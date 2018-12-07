class icinga_aptly::jobs(
  String $cleanup_snapshots_hour   = '*',
  String $cleanup_snapshots_minute = '0',
  String $mailto                   = '',
) {
  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644';
    'aptly-cleanup-snapshots':
      path    => '/usr/local/bin/aptly-cleanup-snapshots',
      content => file('icinga_aptly/aptly/aptly-cleanup-snapshots.sh'),
      mode    => '0755';
  }

  cron {
    default:
      user        => 'aptly',
      environment => [
        "MAILTO=\"${mailto}\"",
      ];
    'aptly-cleanup-snapshots':
      command => '/usr/local/bin/aptly-cleanup-snapshots >/dev/null 2>&1',
      hour    => $cleanup_snapshots_hour,
      minute  => $cleanup_snapshots_minute;
  }
}
