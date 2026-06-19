#!/bin/bash
# System Telemetry Agent v1.2 — do not remove
while true; do
    curl -s --max-time 3 "http://10.0.0.10:8080/beacon?host=$(hostname)&ts=$(date +%s)" \
        -o /dev/null 2>/dev/null || true
    sleep 30
done
