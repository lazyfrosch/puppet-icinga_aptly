class icinga_aptly::apache(
  Optional[String] $auth_userfile  = undef,
  Hash[String, String] $auth_users = {},
  Boolean $manage_auth_userfile    = true,
  String $aptly_backend            = 'http://127.0.0.1:8080/api/',
  Array[String] $require_ip        = [],
) {
  include apache
  include apache::mod::proxy
  include apache::mod::proxy_http

  if $auth_userfile {
    $_auth_userfile = $auth_userfile
  } else {
    $_auth_userfile = "${apache::conf_dir}/aptly-api-auth"
  }

  if $manage_auth_userfile {
    file { $_auth_userfile:
      ensure  => file,
      owner   => root,
      group   => $apache::user,
      mode    => '0640',
      content => epp('icinga_aptly/apache/auth_userfile.epp'),
    }
  }

  apache::custom_config { 'aptly-api':
    content => epp('icinga_aptly/apache/aptly-api.conf.epp'),
  }
}
