class icinga_aptly::aptly {
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

  file { 'aptly home':
    ensure => directory,
    path   => $icinga_aptly::aptly_home,
    owner  => 'aptly',
    group  => 'aptly',
    mode   => '0755',
  }

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644';
    'aptly-api.service':
      path    => '/etc/systemd/system/aptly-api.service',
      content => epp('icinga_aptly/aptly/aptly.service.epp', {
        listen_addr => $icinga_aptly::aptly_listen_addr,
      });
    'aptly-cli':
      path    => '/usr/local/bin/aptly',
      content => file('icinga_aptly/aptly/aptly.sh'),
      mode    => '0755';
    'aptly-cleanup-snapshots':
      path    => '/usr/local/bin/aptly-cleanup-snapshots',
      content => file('icinga_aptly/aptly/aptly-cleanup-snapshots.sh'),
      mode    => '0755';
  }

  exec { 'aptly systemctl daemon-reload':
    command     => 'systemctl daemon-reload',
    refreshonly => true,
    user        => 'root',
    path        => $facts['path'],
    subscribe   => File['/etc/systemd/system/aptly-api.service'],
  }

  ~> service { 'aptly-api':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/systemd/system/aptly-api.service'],
  }

  # TODO: cron jobs
}
