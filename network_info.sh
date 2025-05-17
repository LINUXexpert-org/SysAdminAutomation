#!/bin/bash
# network_info.sh - Show network interfaces, routes, open ports, firewall rules
# 
# Copyright (C) 2025 LINUXexpert.org
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by the 
# Free Software Foundation, version 3 of the License.
# 
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
# for more details.
# 
# You should have received a copy of the GNU General Public License along 
# with this program. If not, see <https://www.gnu.org/licenses/>.
# 
# Usage: network_info.sh    (no arguments)
# Description: Displays network interface addresses, routing table, open ports, and iptables rules.
 
echo "==== Network Interfaces (IP addresses) ===="
if command -v ip &> /dev/null; then
  ip -brief addr show    # brief output of interfaces and addresses
elif command -v ifconfig &> /dev/null; then
  ifconfig -a
else
  echo "No network interface tool (ip or ifconfig) available."
fi

echo -e "\n==== Routing Table ===="
if command -v ip &> /dev/null; then
  ip route show
elif command -v route &> /dev/null; then
  route -n
else
  echo "No routing tool (ip or route) available."
fi

echo -e "\n==== Listening Ports (TCP/UDP) ===="
if command -v ss &> /dev/null; then
  ss -tulwn   # show TCP/UDP ports in listen state with numeric addresses
elif command -v netstat &> /dev/null; then
  netstat -tuln
else
  echo "No socket listing tool (ss or netstat) available."
fi

echo -e "\n==== Firewall Rules (iptables) ===="
if command -v iptables &> /dev/null; then
  iptables -L -n -v    # list firewall rules with numeric addresses and packet counts
else
  echo "iptables command not found (no firewall rules to show or using nftables)."
fi
