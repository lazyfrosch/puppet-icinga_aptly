# icinga_aptly Puppet module

## GPG Key

Currently this module does not generate or manipulate any GPG key.

You can create a key like this:

```
$ sudo su - aptly

$ gpg --batch --gen-key <<GPG
%no-ask-passphrase
%no-protection
%echo Generating a basic GPG key
Key-Type: RSA
Key-Usage: sign
Expire-Date: 0
Name-Real: Icinga Aptly Test
Name-Email: info+aptlytest@icinga.com
%commit
%echo done
GPG
```

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
