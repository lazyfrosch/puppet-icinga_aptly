class icinga_aptly::jobs(
  String $cleanup_ensure            = 'present',
  String $cleanup_snapshots_hour    = '*',
  String $cleanup_snapshots_minute  = '0',
  String $legacy_update_rpms_ensure = 'present',
  String $legacy_update_rpms_hour   = '*',
  String $legacy_update_rpms_minute = '*/5',
  String $legacy_update_msis_ensure = 'present',
  String $legacy_update_msis_hour   = '*',
  String $legacy_update_msis_minute = '*/5',
  String $process_upload_ensure     = 'present',
  String $process_upload_hour       = '*',
  String $process_upload_minute     = '*/5',
  String $mailto                    = '',
) {
  include icinga_aptly

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    'aptly-cleanup-snapshots':
      path    => '/usr/local/bin/aptly-cleanup-snapshots',
      content => file('icinga_aptly/aptly-cleanup-snapshots.sh');
    'aptly-legacy-update-rpms':
      path    => '/usr/local/bin/aptly-legacy-update-rpms',
      content => file('icinga_aptly/aptly-legacy-update-rpms.rb');
    'aptly-legacy-update-msis':
      path    => '/usr/local/bin/aptly-legacy-update-msis',
      content => file('icinga_aptly/aptly-legacy-update-msis.rb');
    'aptly-process-upload':
      path    => '/usr/local/bin/aptly-process-upload',
      content => file('icinga_aptly/aptly-process-upload.py');
    'aptly-rpmsign':
      path    => '/usr/local/bin/aptly-rpmsign',
      content => file('icinga_aptly/aptly-rpmsign.py');
  }

  cron {
    default:
      user        => 'aptly',
      environment => [
        "MAILTO=\"${mailto}\"",
        "APTLY_HOME=\"${icinga_aptly::aptly_home}\"",
      ];
    'aptly-cleanup-snapshots':
      ensure  => $cleanup_ensure,
      command => '/usr/local/bin/aptly-cleanup-snapshots >/dev/null 2>&1',
      hour    => $cleanup_snapshots_hour,
      minute  => $cleanup_snapshots_minute;
    'aptly-process-upload':
      ensure  => $process_upload_ensure,
      command => '/usr/local/bin/aptly-process-upload',
      hour    => $process_upload_hour,
      minute  => $process_upload_minute;
    'aptly-legacy-update-rpms':
      ensure  => $legacy_update_rpms_ensure,
      command => '/usr/local/bin/aptly-legacy-update-rpms',
      hour    => $legacy_update_rpms_hour,
      minute  => $legacy_update_rpms_minute;
    'aptly-legacy-update-msis':
      ensure  => $legacy_update_msis_ensure,
      command => '/usr/local/bin/aptly-legacy-update-msis',
      hour    => $legacy_update_msis_hour,
      minute  => $legacy_update_msis_minute;
  }
}
