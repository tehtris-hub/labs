#!/bin/bash
#

while true
do
  curl http://10.0.0.10:8080 >/dev/null 2>&1
  sleep 30
done &
