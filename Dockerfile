## TODO
#  Mount a volume and dump all the logs into that otherwise logs will be lost as soon as container exits
#  Configure docker to pick certificates from mount volume
#  Evaluate option of creating Nginx as seperate image
#  Check if size of docker image can be reduced in production image, only binaries of janus ? no code ?? 

FROM ubuntu:18.04

## Install build essential
RUN  apt-get update
RUN  apt-get install -y make vim wget git nginx

## Install dependencies
RUN	apt-get update -y && \
	apt-get install -y cron && \
	apt-get install -y libmicrohttpd-dev libjansson-dev && \
	apt-get install -y libssl-dev libsrtp-dev libsofia-sip-ua-dev libglib2.0-dev && \
	apt-get install -y libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev libavutil-dev libavcodec-dev libavformat-dev && \
	apt-get install -y libconfig-dev pkg-config gengetopt libtool automake cmake

RUN  apt-get install -y python3 python3-pip ninja-build
RUN  pip3 install meson

ENV HOME /var/janus
WORKDIR $HOME

RUN apt-get purge -y libsrtp0 libsrtp0-dev
RUN cd $HOME && wget -nv https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz && tar xf v2.2.0.tar.gz && cd libsrtp-2.2.0  && ./configure --prefix=/usr --enable-openssl && make shared_library && make install
RUN cd $HOME && git clone https://libwebsockets.org/repo/libwebsockets && cd libwebsockets && git checkout v3.2-stable && mkdir build && cd build && cmake -DLWS_MAX_SMP=1 -DLWS_WITHOUT_EXTENSIONS=0 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. && make && make install

COPY ./libnice $HOME/libnice
RUN cd $HOME/libnice && meson --prefix=/usr build && ninja -C build && ninja -C build install


COPY . $HOME/janus-gw
RUN cd $HOME/janus-gw && ./autogen.sh &&  ./configure --prefix=/usr/local --disable-data-channels --enable-post-processing && make && make install && make configs 

EXPOSE 80 443
EXPOSE 0:65535/udp



