#!/bin/bash

set -eu

module_path=/etc/puppetlabs/code/modules
module_name=icinga_aptly

module_install() {
  if ! puppet module list | grep -q "$1"; then
    puppet module install "$@"
  fi
}

module_install puppetlabs-apache
module_install puppetlabs-apt
module_install puppetlabs-stdlib

if [ ! -e "${module_path}/${module_name}" ]; then
  echo "Creating symlink at ${module_path}/${module_name}"
  ln -svf /vagrant "${module_path}/${module_name}"
fi
