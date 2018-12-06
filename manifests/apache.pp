class icinga_aptly::apache {
  include apache

  apache::custom_config { 'aptly':
    content => epp('icinga_aptly'),
  }
}
