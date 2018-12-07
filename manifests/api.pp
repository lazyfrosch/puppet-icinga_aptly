class icinga_aptly::api {
  include icinga_aptly

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
}
