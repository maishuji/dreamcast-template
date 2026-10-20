# Debugging the Dreamcast network connection

This guide describes a simple DHCP setup for connecting a Dreamcast to a Linux host over Ethernet, such as through a Broadband Adapter (BBA) or USB Ethernet adapter. It also covers common `dnsmasq` and `dcload-ip` issues.

## Configure DHCP with `dnsmasq`

### Install `dnsmasq`

On Debian or Ubuntu:

```bash
sudo apt install dnsmasq
```

### Configure an interface-specific DHCP range

Create a configuration file for the Dreamcast connection:

```bash
sudo nano /etc/dnsmasq.d/dreamcast.conf
```

Add the following, replacing the interface name with the NIC connected to the Dreamcast:

```ini
interface=<your-dreamcast-interface>
bind-interfaces

dhcp-range=192.168.0.50,192.168.0.150,12h
dhcp-option=3,192.168.0.1
dhcp-option=6,8.8.8.8,1.1.1.1
```

Find the interface name with:

```bash
ip addr
```

Check that it is the adapter connected to the Dreamcast. For a dedicated direct link, give the host adapter the example gateway address if it does not already have it, bring the interface up, then restart `dnsmasq`:

```bash
sudo ip addr add 192.168.0.1/24 dev <your-dreamcast-interface>
sudo ip link set <your-dreamcast-interface> up
sudo systemctl restart dnsmasq
```

> **Network configuration:** These commands assume a dedicated `192.168.0.0/24` network. Check the adapter's current address first; do not add `192.168.0.1/24` again if it is already configured. `ip addr add` is temporary, so configure a persistent address using your host's network manager if needed. Adapt the range and options to your network, and avoid running a second DHCP server on a shared network.

## Find the Dreamcast IP address

With the Dreamcast booted into `dcload-ip` or another network-enabled application, follow the `dnsmasq` journal:

```bash
sudo journalctl -u dnsmasq -f
```

A successful DHCP exchange looks similar to:

```text
DHCPDISCOVER(enx...) ...
DHCPOFFER(enx...) 192.168.0.85 ...
DHCPREQUEST ...
DHCPACK ...
```

Use the offered address with tools such as `dc-tool-ip`.

## Troubleshooting

### `dnsmasq` fails to start because the interface is unknown

An error such as `unknown interface` usually means that the configured interface does not exist or is not available when `dnsmasq` starts. Check the name and state:

```bash
ip addr show <your-dreamcast-interface>
```

If the interface exists but is down, bring it up and restart the service:

```bash
sudo ip link set <your-dreamcast-interface> up
sudo systemctl restart dnsmasq
```

If it does not exist, verify the interface name in `/etc/dnsmasq.d/dreamcast.conf` and check that the Ethernet adapter is connected.

### `dcload-ip` does not receive an IP address

Inspect the `dnsmasq` journal while the Dreamcast requests an address:

```bash
sudo journalctl -u dnsmasq -f
```

If the log reports that a DHCP packet was received on the interface “which has no address,” assign the host adapter an address on the example subnet, then restart `dnsmasq`:

```bash
sudo ip addr add 192.168.0.1/24 dev <your-dreamcast-interface>
sudo ip link set <your-dreamcast-interface> up
sudo systemctl restart dnsmasq
```

Confirm the address:

```bash
ip addr show <your-dreamcast-interface>
```

Once `dcload-ip` reports its address, pass it to the hardware run target. For example:

```bash
make run-dc DC_BUILD_DIR=build-dreamcast DC_IP=192.168.0.85
```

## Useful commands

```bash
sudo journalctl -u dnsmasq -f
sudo ip link set <your-dreamcast-interface> up
sudo ip addr show <your-dreamcast-interface>
sudo systemctl restart dnsmasq
```
