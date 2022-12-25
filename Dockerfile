FROM golang:1.14-buster AS easy-novnc-build
WORKDIR /src
RUN go mod init build && \
    go get github.com/geek1011/easy-novnc@v1.1.0 && \
    go build -o /bin/easy-novnc github.com/geek1011/easy-novnc

FROM debian:buster
LABEL Description="Build environment"

ENV HOME /root

SHELL ["/bin/bash", "-c"]

RUN apt-get update -y && apt-get -y --no-install-recommends install \
    build-essential \
    clang \
    cmake \
    wget

RUN apt-get update -y && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends tigervnc-standalone-server supervisor gosu && \
    rm -rf /var/lib/apt/lists && \
    mkdir -p /usr/share/desktop-directories

RUN apt-get update -y &&  apt-get install -y --no-install-recommends qemu-system-x86-64 && mkdir cest

RUN apt-get install -y --no-install-recommends ovmf

RUN apt-get install -y --no-install-recommends lld

RUN apt-get install -y --no-install-recommends parted

RUN apt-get install -y --no-install-recommends mtools

RUN apt-get install -y --no-install-recommends udev

RUN apt-get install -y --no-install-recommends nasm

RUN apt-get install -y --no-install-recommends gdb
 
RUN apt-get install -y --no-install-recommends binutils

RUN apt-get install -y --no-install-recommends zip

COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY supervisord.conf /etc/
EXPOSE 8080

RUN groupadd --gid 1000 app && \
    useradd --home-dir /cest --shell /bin/bash --uid 1000 --gid 1000 app

COPY . /cest

WORKDIR /cest

RUN make

RUN cp /usr/share/OVMF/OVMF_CODE.fd /cest/OVMF_CODE.fd
RUN cp /usr/share/OVMF/OVMF_VARS.fd /cest/OVMF_VARS.fd
RUN chmod 006 OVMF_CODE.fd


CMD ["sh", "-c", "chown app:app /cest /dev/stdout && exec gosu app supervisord"]
# ENTRYPOINT ["tail", "-f", "/dev/null"] # For debugging purposes.
