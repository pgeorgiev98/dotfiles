#!/bin/bash

# Lock and wait to make sure the screen is locked
$HOME/.config/i3/scripts/lock&
sleep 1

# Hibernate the PC
systemctl hibernate
