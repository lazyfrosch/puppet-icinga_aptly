#!/usr/bin/env ruby

require 'fileutils'
require 'syslog/logger'

ENV['APLY_HOME'] = '/var/www/html/aptly' unless ENV.has('APTLY_HOME')

@log = Syslog::Logger.new 'update-msi'
begin
  @repos_prefix = ENV['APLY_HOME'] + '/public/windows'
  Dir.mkdir(@repos_prefix) unless File.directory?(@repos_prefix)

  # get all files uploaded to aptly
  files = Dir[ENV['APLY_HOME'] + '/upload/*/*.msi'] +
          Dir[ENV['APLY_HOME'] + '/upload/*/*.nupkg'] +
          Dir[ENV['APLY_HOME'] + '/upload/windows/*.zip']

  @log.info "Found #{files.length} new Files"

  files.each do |source|
    @log.info "Processing #{source}"
    unless File.size(source) > 0
      @log.info "Remove: #{source}. Filesize is not > 0"
      File.delete(source)
      next
    end
    filename = File.basename(source)
    destination = repos_prefix
    FileUtils.mv(source, "#{destination}/#{filename}")
    @log.info "Moved #{source} to #{destination}/#{filename}"
  end
rescue StandardError => e
  @log.error e.message
end
