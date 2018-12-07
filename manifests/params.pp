class icinga_aptly::params {
  if $facts['os']['family'] != 'Debian' {
    fail('Only osfamily Debian is supported here!')
  }

  $helper_packages = [
    'rpm',
    'createrepo',
    'ruby',
    'curl',
    'ca-certificates',
  ]

  $_dist = $facts['os']['name']
  $_release = $facts['os']['release']['major']

  if (
    ($_dist == 'Debian' and versioncmp($_release, '9') < 0)
    or ($_dist == 'Ubuntu' and versioncmp($_release, '18.04') < 0)
  ) {
    $gpg_packages = ['gnupg', 'gpgv']
  } else {
    $gpg_packages = ['gnupg1', 'gpgv1']
  }
}
