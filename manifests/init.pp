class icinga_aptly(
  Boolean $manage_apache                         = false,
  String $aptly_version                          = '1.3.0',
  String $aptly_gpg_key                          = '26DA9D8630302E0B86A7A2CBED75B5A4483DA07C',
  String $aptly_repo_base                        = 'http://repo.aptly.info/',
  String $aptly_repo_dist                        = 'squeeze',
  String $aptly_home                             = '/var/lib/aptly',
  String $aptly_listen_addr                      = '127.0.0.1:8080',
  String $content_repo_source                    = 'https://github.com/Icinga/packages.icinga.com.git',
  Enum['present', 'latest'] $content_repo_ensure = 'latest',
  String $content_repo_revision                  = 'master',
) inherits icinga_aptly::params {
  contain icinga_aptly::aptly

  contain icinga_aptly::content
  contain icinga_aptly::rpms

  if $manage_apache {
    contain icinga_aptly::apache
  }
}
