#!/bin/bash
set -e
ssh-keygen -A
exec /usr/sbin/sshd -D
