#!/usr/bin/env bash
###!/bin/bash

# DR 05/05/2020: file modified for local runs
#                environment variables taken from Dockerfile

#export DISPLAY=:0
export TRADING_MODE=paper
export TWS_PORT=4002
export VNC_PORT=5900

export IBGW_VERSION=972
#export IBC_CONFIG=$HOME/github/ib-gateway-docker/ibc_config.ini
export IBC_CONFIG=$HOME/mcai/github/ib-gateway-docker/ibc_config.ini

set -e
set -o errexit

rm -f /tmp/.X0-lock

Xvfb :0 &
sleep 1

x11vnc -rfbport $VNC_PORT -display :0 -usepw -forever &
socat TCP-LISTEN:$TWS_PORT,fork TCP:localhost:4001,forever &

# Start this last and directly, so that if the gateway terminates for any reason, the container will stop as well.
# Retry behavior can be implemented by re-running the container.
/opt/ibc/scripts/ibcstart.sh "$IBGW_VERSION" --gateway "--mode=$TRADING_MODE" "--user=$TWSUSERID" "--pw=$TWSPASSWORD" "--ibc-ini=$IBC_CONFIG"
