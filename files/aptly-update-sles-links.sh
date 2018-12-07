#!/bin/bash

set -eu

: "${APTLY_HOME:=/var/www/html/aptly}"

cd "${APTLY_HOME}"/public/SUSE/

#Find all major version (ie 11, 12 for sles11-sp1, sles-12-sp2, sles12-sp3)
for MAJOR in $(find . -name sles\* | cut -d'-' -f1 | cut -c 7- | sort | uniq); do

	#Find all minor versions and create symlinks (11.1 -> sles11-sp1)
	for MINOR in $(find . -name "sles$MAJOR"\* | cut -c 12-); do
		SHORTNAME="$MAJOR.$MINOR"
		if [ ! -h "$SHORTNAME" ]; then
			ln -s "sles$MAJOR-sp$MINOR" "$SHORTNAME"
		fi
	done

	#Find the latest version and link major (11 -> 11.3)
	#Except for sles 12, because sp 2 and 3 are incompatible
	if [ "$MAJOR" != "12" ]; then
		LATEST="$MAJOR.$(find . -name "sles$MAJOR"\* | cut -c 12- | sort -n -r | head -n 1)"
		if [ ! -h "$MAJOR" ] || [ "$(ls -l "$MAJOR" | sed -e 's/.* -> //')" != "$LATEST" ]; then
			if [ -h "$MAJOR" ]; then
				rm "$MAJOR"
			fi
			ln -s "$LATEST" "$MAJOR"
		fi
	fi
done
