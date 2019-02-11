class icinga_aptly::install {
  include icinga_aptly

  ensure_packages($icinga_aptly::params::gpg_packages)

  ensure_packages($icinga_aptly::params::helper_packages)

  if $icinga_aptly::manage_repo {
    apt::source { 'aptly':
      location => $icinga_aptly::aptly_repo_base,
      release  => $icinga_aptly::aptly_repo_dist,
      repos    => 'main',
      key      => $icinga_aptly::aptly_gpg_key,
      before   => Package['aptly'],
    }
  }

  package { 'aptly':
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
      content => epp('icinga_aptly/aptly/aptly.conf.epp');
  }

  file { 'aptly cli':
    ensure  => file,
    path    => '/usr/local/bin/aptly',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file('icinga_aptly/aptly/aptly.sh'),
  }
}
