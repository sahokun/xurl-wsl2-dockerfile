#!/bin/bash
set -e

# Get the container's eth0 IP (this is where Docker forwards traffic to)
ETH0_IP=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)

if [ -n "$ETH0_IP" ]; then
    # Relay: eth0:8080 (receives Docker DNAT) -> 127.0.0.1:8080 (where xurl listens)
    socat TCP-LISTEN:8080,bind="${ETH0_IP}",fork,reuseaddr TCP:127.0.0.1:8080 &
    echo "[entrypoint] socat relay: ${ETH0_IP}:8080 -> 127.0.0.1:8080"
else
    echo "[entrypoint] WARNING: could not detect eth0 IP, relay not started"
fi

exec "$@"
