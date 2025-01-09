#!/bin/bash

set -e

touch "/etc/security/limits.d/99-devzero.conf"
echo "* soft     nproc          65535" >>"/etc/security/limits.d/99-devzero.conf"
echo "* hard     nproc          65535" >>"/etc/security/limits.d/99-devzero.conf"
echo "* soft     nofile         65535" >>"/etc/security/limits.d/99-devzero.conf"
echo "* hard     nofile         65535" >>"/etc/security/limits.d/99-devzero.conf"
echo "root soft     nproc          65535" >>"/etc/security/limits.d/99-devzero.conf"
echo "root hard     nproc          65535" >>"/etc/security/limits.d/99-devzero.conf"
echo "root soft     nofile         65535" >>"/etc/security/limits.d/99-devzero.conf"
echo "root hard     nofile         65535" >>"/etc/security/limits.d/99-devzero.conf"

touch "/etc/sysctl.d/98-devzero.conf"
echo "fs.inotify.max_user_instances = 8192" >>/etc/sysctl.d/98-devzero.conf
echo "fs.inotify.max_user_watches = 524288" >>/etc/sysctl.d/98-devzero.conf
