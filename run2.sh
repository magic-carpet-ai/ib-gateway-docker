#!/usr/bin/env bash
# run.sh version for direct, non-docker runs

export IBGW_VERSION=972
export TRADING_MODE=paper

export TWS_SETTINGS=$HOME/Jts

export IBC_PATH=/opt/ibc
export IBC_CONFIG=$HOME/mcai/github/ib-gateway-docker/ibc_config.ini

# check that TWSUSERID and TWSPASSWORD are set
if [[ -z $TWSUSERID || -z $TWSPASSWORD ]]; then
  echo 'please set TWS user-id and password via TWSUSERID and TWSPASSWORD variables'
  exit 1
fi

# exit on error (both options are the same)
set -e
set -o errexit

# enable virtual display either here or directly via 'xvfb-run <command>'
export DISPLAY=:0
rm -f /tmp/.X0-lock
Xvfb :0 &

# enable/disable remote control via x11vnc if needed
# export VNC_PORT=5900
# sleep 1
# x11vnc -rfbport $VNC_PORT -display :0 -usepw -forever &

# forking the outside port 4001 to internal 4002, no 'forever' option as in 'run.sh'
# this is so that the IB GW will think that we are connecting from localhost
socat TCP-LISTEN:4001,fork TCP:localhost:4002 &

# echo all commands
set -x

if [[ $OSTYPE == darwin* ]]; then
    export TWS_PATH=$HOME/Applications
    export JAVA_PATH=`/usr/libexec/java_home`/bin

    # run latest, updated IBC scripts, deployed 3.2.2 version does not work for mac
    #
    # connection to IB GW on mac sporadic, sometimes works sometimes not,
    # seems to depend on overall system load
    #
    # two other issues (neither affeecting the run):
    # (1) --java-path seems to be ignored
    # (2) getting an error message:
    #     2020-05-07 10:46:52:045 IBC: Properties file /Users/rusakov/IBC/config.ini not found
    # (3) on mac-os GW windows are always visible (Xvfb seems not working)
    $HOME/mcai/github/IBC/resources/scripts/ibcstart.sh "$IBGW_VERSION" --gateway "--mode=$TRADING_MODE" \
        "--tws-path=$TWS_PATH" "--tws-settings-path=$TWS_SETTINGS" \
        "--ibc-path=$IBC_PATH" "--ibc-ini=$IBC_CONFIG" \
        "--user=$TWSUSERID" "--pw=$TWSPASSWORD"
        # "--java-path=$JAVA_PATH"
else
    # non-mac, simple remote headless run

    /opt/ibc/scripts/ibcstart.sh "$IBGW_VERSION" --gateway "--mode=$TRADING_MODE" \
        "--ibc-path=$IBC_PATH" "--ibc-ini=$IBC_CONFIG" \
        "--user=$TWSUSERID" "--pw=$TWSPASSWORD"
fi
