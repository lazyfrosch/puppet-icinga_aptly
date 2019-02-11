#!/usr/bin/env ruby

require 'fileutils'
require 'syslog/logger'
require 'lockfile'

ENV['APLY_HOME'] = '/var/www/html/aptly' unless ENV.key?('APTLY_HOME')

@log = Syslog::Logger.new 'update-rpm'

lockfile = Lockfile.new ENV['APLY_HOME'] + '/.rpmlock', retries: 0
begin
  lockfile.lock
rescue Lockfile::MaxTriesLockError
  @log.warn "Lockfile locked by other process, breaking here"
  exit
end

begin
  @repos_prefix = ENV['APLY_HOME'] + '/public/'
  Dir.mkdir(@repos_prefix) unless File.directory?(@repos_prefix)

  def removeOldSnapshots(source, destination)
    #get package name from the rpm itself
    packageName = %x{rpm --queryformat "%{NAME}" -qp #{source}}
    rpms = Dir["#{destination}/#{packageName}*.rpm"]
    rpms.each do |rpm|
      if %x{rpm --queryformat "%{NAME}" -qp #{rpm}} == packageName
        FileUtils.rm(rpm)
        @log.info "Removed old snaphsot #{rpm}"
      end
    end
  end

  # Create directory structure
  def create_repos(repos,arch)
    repos.uniq!
    arch.uniq!

    repos.each do |repo|
      repoMeta = repo.split('-')
      if repoMeta.length < 5
        @log.warn "Skipping directory #{repo}. Wrong format!"
        next
      end

      distro, version, arch_not_used, release  = repoMeta[-4..-1]
      project = repoMeta[0..-5].join('-')

      # create distro and versions directory
      Dir.mkdir "#{@repos_prefix}/#{distro}" unless File.directory?("#{@repos_prefix}/#{distro}")
      Dir.mkdir "#{@repos_prefix}/#{distro}/#{version}" unless File.directory?("#{@repos_prefix}/#{distro}/#{version}")

      # create release dir
      Dir.mkdir "#{@repos_prefix}/#{distro}/#{version}/#{release}" unless File.directory?("#{@repos_prefix}/#{distro}/#{version}/#{release}")

      # create arch
      arch.each do |a|
        Dir.mkdir "#{@repos_prefix}/#{distro}/#{version}/#{release}/#{a}" unless File.directory?("#{@repos_prefix}/#{distro}/#{version}/#{release}/#{a}")
      end
    end
  end

  # get all rpms uploaded to aptly
  rpms = Dir[ENV['APLY_HOME'] + "/upload/*/*.rpm"]
  @log.info "Found #{rpms.length} new RPMs"

  # get parent directory of each rpm
  repos = Array.new
  arch = Array.new
  rpms.each do |rpm|
    repos << File.dirname(rpm).split(/\//).last
    arch << File.basename(rpm).split(/\./)[-2]
  end

  create_repos repos,arch

  # Move rpm to the right place
  reposToUpdate = Array.new
  rpms.each do |source|
    @log.info "Processing #{source}"

    #get metadata from parent directory
    repoMeta = File.dirname(source).split(/\//).last.split('-')
    if repoMeta.length < 5
      @log.warn "Skipping directory #{source}. Wrong format!"
      next
    end

    distro, version, arch_not_used, release  = repoMeta[-4..-1]
    project = repoMeta[0..-5].join('-')

    filename = File.basename(source)

    # because of lazy gb
    arch = filename.split(/\./)[-2]

    destination = "#{@repos_prefix}/#{distro}/#{version}/#{release}/#{arch}"

    if File.exists?("#{destination}/#{filename}")
      FileUtils.rm(source)
      @log.info "Package is already published. Removed #{source}."
    elsif !(File.size(source) > 0)
      @log.info "Remove: #{source}. Filesize is not > 0"
      File.delete(source)
    else
      @log.info "Signing rpm #{source}"
      ret = %x{aptly-rpmsign "#{source}" 2>&1}
      if $? != 0
        @log.error "Could not sign rpm: #{ret}"
      else
        # we don't keep old snapshot packages
        removeOldSnapshots(source, destination) if release =~ /snapshot/
        FileUtils.mv(source, "#{destination}/#{filename}")
        @log.info "Moved #{source}"
        reposToUpdate << "#{@repos_prefix}/#{distro}/#{version}/#{release}/"
      end
    end
  end

  # Create repo and sign
  reposToUpdate.uniq.each do |repo|
    @log.info "CREATEREPO #{repo}"

    repo =~ /centos-5/ ? sha = 'sha1' : sha = 'sha'
    @log.info "Using #{sha} for signing"

    ret = %x{createrepo -s #{sha} #{repo}}
    @log.error "Could not execute createrepo: #{ret}" if $? != 0

    FileUtils.rm("#{repo}repodata/repomd.xml.asc") if File.exists?("#{repo}repodata/repomd.xml.asc")

    @log.info "SIGN #{repo}"
    ret = %x{gpg --detach-sign --armor --batch --no-tty #{repo}/repodata/repomd.xml}
    @log.error "Could not sign repomod.xml: #{ret}" if $? != 0
  end
rescue Exception => e
  @log.error e.message
ensure
  lockfile.unlock
end
