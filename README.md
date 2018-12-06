# icinga_aptly Puppet module

## Webserver

By default the module does not touch Apache or it's config. You can use the Apache module to configure the basics.

Here is an example for Hiera configuration:

```yaml
---
classes: # make sure to include those
  - apache
  - apache::vhosts
  - icinga_aptly

icinga_aptly::manage_apache: true

apache::default_vhost: false
apache::vhosts::vhosts:
  aptly:
    port: 80
    docroot: /var/lib/aptly/public
    options:
      - Indexes
      - FollowSymLinks
    override:
      - All
```
