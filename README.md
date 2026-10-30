# Corosync QNetd for Proxmox, as a Home Assistant add-on

Runs `corosync-qnetd`, the QDevice arbiter of a Proxmox VE cluster, on a Home
Assistant OS host. A cluster with an even number of nodes then gets one more
vote, so it keeps quorum when half of its nodes are down.

- Listens on TCP 5403 on the host's own address (`host_network`).
- Keeps its certificate database in the add-on's `/data`, so the qdevice keeps
  its identity across updates.
- Runs an SSH server only while `ssh_authorized_key` is set, for Proxmox's
  `pvecm qdevice setup`, which signs the cluster certificate over SSH as root.
  It accepts that one key and no password. Clear the option and restart the
  add-on after the setup.

## Setup

1. Add this repository to the add-on store, install **Corosync QNetd**, and
   start it with `ssh_authorized_key` set to a public key held by one cluster
   node (`ssh_port` defaults to 2222).
2. On every cluster node: `apt install corosync-qdevice`.
3. On the node holding the key, point SSH at the add-on's port for the HA host
   (in `/root/.ssh/config`: `Host <ha address>` / `Port 2222`), then run
   `pvecm qdevice setup <ha address>`.
4. `pvecm status` shows one more expected vote and a `Qdevice` line.
5. Clear `ssh_authorized_key` and restart the add-on.
