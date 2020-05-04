# simple IB GW Dockerfile where IB Gateway is running via IBC, see https://github.com/IbcAlpha/IBC
#
# DR 04/05/2020: it is different from the base 'Dockerfile' in the following
# - fixed ubuntu version 20.04
# - latest stable ibgateway, 972.1 currently,
#   check it after build via 'docker run -it ib-gateway-docker ls -al Jts/ibgateway'
# - latest IBC Linux, 3.8.2 currently
#
# see more info:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#
# to build a docker file:
# $ docker build . -f Dockerfile -t ib-gateway-docker
#
# then tag it with the current date YYYY.MM.DD_version, e.g. 2020.05.04_0
# $ date_tag=`date +'%Y.%m.%d'`_0; echo $date_tag
# $ docker tag ib-gateway-docker gcr.io/mcai-algo/ib-gateway-docker:$date_tag
#
# and push this tagged version
# $ docker push gcr.io/mcai-algo/ib-gateway-docker:$date_tag
#
# you can then see the uploaded dockers and their versions in
# https://console.cloud.google.com/gcr/images/mcai-algo?project=mcai-algo

# intermediate 'builder' layer, used for slimmer image
FROM ubuntu:20.04 AS builder
LABEL maintainer="dmitry@magic-carpet.ch"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y unzip wget

WORKDIR /root

RUN wget -q --progress=bar:force:noscroll --show-progress https://download2.interactivebrokers.com/installers/ibgateway/stable-standalone/ibgateway-stable-standalone-linux-x64.sh -O install-ibgateway.sh && \
    chmod a+x install-ibgateway.sh

RUN wget -q --progress=bar:force:noscroll --show-progress https://github.com/IbcAlpha/IBC/releases/download/3.8.2/IBCLinux-3.8.2.zip -O ibc.zip && \
    unzip ibc.zip -d /opt/ibc && \
    chmod a+x /opt/ibc/*.sh /opt/ibc/*/*.sh

COPY run.sh run.sh
#RUN dos2unix run.sh


# actual docker ===============================================================
FROM ubuntu:20.04
LABEL maintainer="dmitry@magic-carpet.ch"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y socat x11vnc xvfb

WORKDIR /root

COPY --from=builder /root/install-ibgateway.sh install-ibgateway.sh
RUN yes n | ./install-ibgateway.sh

RUN mkdir .vnc
RUN x11vnc -storepasswd 1358 .vnc/passwd

COPY --from=builder /opt/ibc /opt/ibc
COPY --from=builder /root/run.sh run.sh

COPY ibc_config.ini ibc/config.ini

ENV DISPLAY :0
ENV TRADING_MODE paper
ENV TWS_PORT 4002
ENV VNC_PORT 5900

EXPOSE $TWS_PORT
EXPOSE $VNC_PORT

ENTRYPOINT ["./run.sh"]
