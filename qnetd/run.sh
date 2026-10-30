#!/bin/bash
# Start corosync-qnetd, and an SSH server only while a key is configured.
set -euo pipefail

# The certificate database is the qdevice's identity: keep it in /data, which
# survives add-on updates and restarts. The image's database seeds it once.
if [[ ! -d /data/qnetd ]]; then
  cp -a /etc/corosync/qnetd /data/qnetd
fi
rm -rf /etc/corosync/qnetd
ln -s /data/qnetd /etc/corosync/qnetd
chown -R coroqnetd:coroqnetd /data/qnetd

# Proxmox's `pvecm qdevice setup` signs the cluster's certificate over SSH as
# root. SSH runs only while `ssh_authorized_key` is set, accepts that key alone,
# and never a password; clear the option after the setup to turn it off.
key=$(jq -r '.ssh_authorized_key // empty' /data/options.json)
port=$(jq -r '.ssh_port // 2222' /data/options.json)
if [[ -n "$key" ]]; then
  install -d -m 0700 /root/.ssh
  printf '%s\n' "$key" > /root/.ssh/authorized_keys
  chmod 0600 /root/.ssh/authorized_keys
  cat > /etc/ssh/sshd_config.d/qnetd.conf <<CONF
Port ${port}
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
CONF
  mkdir -p /run/sshd
  /usr/sbin/sshd
  echo "SSH enabled on port ${port} for the configured key"
else
  rm -f /root/.ssh/authorized_keys
  echo "SSH disabled"
fi

exec corosync-qnetd -f
