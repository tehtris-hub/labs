#!/bin/bash
##
# @title break
# Put the vm in the desired state for the exercise
#

## Stupid password for turbo compromize via BruteForce
sudo useradd -m -p $(openssl passwd -1 "password") cedric
