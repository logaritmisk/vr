#!/bin/bash

function find_reverse {
  pwd=$1/
  while [ "$pwd" != "//" ]; do
    if [ -f ${pwd}${2} ]; then
      echo $pwd

      return 0
    fi

    pwd=${pwd%/*/}/;
  done
}

pwd=$(pwd)

folder=$(find_reverse $pwd '.vagrant')

if [ $folder ]; then
  test `find "${folder}.ssh_config" -cmin +10` > /dev/null && rm "${folder}.ssh_config"

  if [ ! -f "${folder}.ssh_config" ]; then
    pushd $folder > /dev/null && vagrant ssh-config > .ssh_config && popd > /dev/null
  fi

  test `find "${folder}.r" -cmin +10` > /dev/null && rm "${folder}.r"

  if [ ! -f "${folder}.r" ]; then
    while read f; do
      a=$(echo $f | cut -d ' ' -f 1 | cut -d ':' -f 2)

      grep $a /etc/exports > /dev/null

      if [ $? -eq 0 ]; then
        b=$(echo $f | cut -d ' ' -f 3)

        echo "${b} ${a}" > "${folder}.r"
      fi
    done < <(ssh -qtF "${folder}.ssh_config" default "mount" | tr -d '\r')
  fi

  if [ -n "$1" ]; then
    s=( $(cat "${folder}.r") )
    p=${s[0]}${pwd#${s[1]}*}

    cmd="cd ${p} && $@"
  fi

  ssh -qtF "${folder}.ssh_config" default ${cmd:-""}
fi
