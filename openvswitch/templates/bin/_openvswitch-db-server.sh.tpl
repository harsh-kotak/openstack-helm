#!/bin/bash

{{/*
Copyright 2017 The Openstack-Helm Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

set -ex
COMMAND="${@:-start}"

OVS_DB=/run/openvswitch/conf.db
OVS_SOCKET=/run/openvswitch/db.sock
OVS_SCHEMA=/usr/share/openvswitch/vswitch.ovsschema

function start () {
  mkdir -p "$(dirname ${OVS_DB})"
  if [[ ! -e "${OVS_DB}" ]]; then
    ovsdb-tool create "${OVS_DB}"
  fi

  if [[ "$(ovsdb-tool needs-conversion ${OVS_DB} ${OVS_SCHEMA})" == 'yes' ]]; then
      ovsdb-tool convert ${OVS_DB} ${OVS_SCHEMA}
  fi

  umask 000
  exec /usr/sbin/ovsdb-server ${OVS_DB} \
          -vconsole:emer \
          -vconsole:err \
          -vconsole:info \
          --remote=punix:${OVS_SOCKET} \
          --remote=db:Open_vSwitch,Open_vSwitch,manager_options
  
}

function stop () {
  ovs-appctl -T1 -t /run/openvswitch/ovsdb-server.1.ctl exit
}

$COMMAND
