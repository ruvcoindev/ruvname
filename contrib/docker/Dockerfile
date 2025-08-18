FROM debian:stretch-slim

LABEL Description="Ruvname A decentralized DNS and mesh network protocol"
LABEL URL="https://github.com/ruvcoindev/Ruvname/releases"

ARG arch=amd64
ARG srv_port=4244
ARG dns_port=53

RUN apt-get update -y && \
    apt-get install -y curl && \
    curl -SsL "https://github.com/ruvcoindev/Ruvname/releases/download/$(curl --silent "https://api.github.com/repos/ruvcoindev/Ruvname/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/ruvname-${arch}-$(curl --silent "https://api.github.com/repos/ruvcoindev/Ruvname/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')-nogui.deb" -o /tmp/ruvname.deb  && \
    dpkg -i /tmp/ruvname.deb && \
    apt-get purge -y curl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

EXPOSE ${srv_port}
EXPOSE ${dns_port}
EXPOSE ${dns_port}/udp

WORKDIR /var/lib/ruvname

CMD ["/usr/bin/ruvname", "-n", "-c", "/etc/ruvname.conf"]
