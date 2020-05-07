#!/usr/bin/env bash
###!/bin/bash

# DR 05/05/2020: file modified for local runs
#                environment variables taken from Dockerfile

#export DISPLAY=:0
export TWS_PORT=4002
export VNC_PORT=5900

export IBGW_VERSION=972
export TRADING_MODE=paper

export TWS_SETTINGS=$HOME/Jts

export IBC_PATH=/opt/ibc
#export IBC_CONFIG=$HOME/github/ib-gateway-docker/ibc_config.ini
export IBC_CONFIG=$HOME/mcai/github/ib-gateway-docker/ibc_config.ini

# mac-specific
if [[ $OSTYPE == darwin* ]]; then
    export TWS_PATH=$HOME/Applications
    export JAVA_PATH=`/usr/libexec/java_home`/bin
fi

set -e
set -o errexit

rm -f /tmp/.X0-lock

Xvfb :0 &
sleep 1

x11vnc -rfbport $VNC_PORT -display :0 -usepw -forever &
socat TCP-LISTEN:$TWS_PORT,fork TCP:localhost:4001,forever &

# echo all commands
set -x

if [[ $OSTYPE == darwin* ]]; then
    # run latest, updated IBC scripts, deployed 3.2.2 version does not work for mac
    #
    # connection to IB GW on mac sporadic, sometimes works sometimes not,
    # seems to depend on overall system load
    #
    # two other issues (neither affeecting the run):
    # (1) --java-path seems to be ignored
    # (2) getting an error message:
    #     2020-05-07 10:46:52:045 IBC: Properties file /Users/rusakov/IBC/config.ini not found
    $HOME/mcai/github/IBC/resources/scripts/ibcstart.sh "$IBGW_VERSION" --gateway "--mode=$TRADING_MODE" \
        "--tws-path=$TWS_PATH" "--tws-settings-path=$TWS_SETTINGS" \
        "--ibc-path=$IBC_PATH" "--ibc-ini=$IBC_CONFIG" \
        "--user=$TWSUSERID" "--pw=$TWSPASSWORD"
        # "--java-path=$JAVA_PATH"
else
    /opt/ibc/scripts/ibcstart.sh "$IBGW_VERSION" --gateway "--mode=$TRADING_MODE" \
        "--tws-settings-path=$TWS_SETTINGS" \
        "--ibc-path=$IBC_PATH" "--ibc-ini=$IBC_CONFIG" \
        "--user=$TWSUSERID" "--pw=$TWSPASSWORD"
fi
