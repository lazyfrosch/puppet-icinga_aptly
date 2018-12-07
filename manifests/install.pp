class icinga_aptly::install {
  include icinga_aptly

  ensure_packages($icinga_aptly::params::gpg_packages)

  apt::source { 'aptly':
    location => $icinga_aptly::aptly_repo_base,
    release  => $icinga_aptly::aptly_repo_dist,
    repos    => 'main',
    key      => {
      id     => $icinga_aptly::aptly_gpg_key,
      server => 'keyserver.ubuntu.com',
    },
  }

  -> package { 'aptly':
    ensure          => $icinga_aptly::aptly_version,
    install_options => '--no-install-recommends',
  }

  user { 'aptly':
    ensure   => present,
    home     => $icinga_aptly::aptly_home,
    system   => true,
    shell    => '/bin/bash',
    password => '!',
  }

  file {
    default:
      ensure => file,
      owner  => 'aptly',
      group  => 'aptly',
      mode   => '0644',
      notify => Service['aptly-api'];
    'aptly home':
      ensure => directory,
      path   => $icinga_aptly::aptly_home;
    'aptly db':
      ensure => directory,
      path   => "${icinga_aptly::aptly_home}/db",
      mode   => '0640';
    'aptly public':
      ensure => directory,
      path   => "${icinga_aptly::aptly_home}/public";
    'aptly.conf':
      ensure  => file,
      path    => "${icinga_aptly::aptly_home}/.aptly.conf",
      owner   => 'aptly',
      group   => 'aptly',
      mode    => '0640',
      content => epp('icinga_aptly/aptly/aptly.conf.epp', {
        'rootDir' => $icinga_aptly::aptly_home,
      });
  }

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644';
    'aptly-cli':
      path    => '/usr/local/bin/aptly',
      content => file('icinga_aptly/aptly/aptly.sh'),
      mode    => '0755';
    'aptly-cleanup-snapshots':
      path    => '/usr/local/bin/aptly-cleanup-snapshots',
      content => file('icinga_aptly/aptly/aptly-cleanup-snapshots.sh'),
      mode    => '0755';
  }
}
