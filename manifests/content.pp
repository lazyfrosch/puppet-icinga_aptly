class icinga_aptly::content {
  ensure_packages(['git'])

  $public_path = "${icinga_aptly::aptly_home}/public"

  vcsrepo { 'aptly web content':
    ensure   => $icinga_aptly::content_repo_ensure,
    provider => 'git',
    path     => $public_path,
    source   => $icinga_aptly::content_repo_source,
    revision => $icinga_aptly::content_repo_revision,
    user     => 'aptly',
    require  => File[$public_path],
  }
}
