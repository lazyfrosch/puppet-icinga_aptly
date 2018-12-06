class icinga_aptly(
  $manage_apache     = false,
  $aptly_version     = '1.3.0',
  $aptly_gpg_key     = '26DA9D8630302E0B86A7A2CBED75B5A4483DA07C',
  $aptly_repo_base   = 'http://repo.aptly.info/',
  $aptly_repo_dist   = 'squeeze',
  $aptly_home        = '/var/lib/aptly',
  $aptly_listen_addr = '127.0.0.1:8080',
) inherits icinga_aptly::params {
  contain icinga_aptly::aptly

  contain icinga_aptly::content
  contain icinga_aptly::rpms

  if $manage_apache {
    contain icinga_aptly::apache
  }
}
