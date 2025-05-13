FROM ubuntu:22.04
LABEL maintainer="Cinc Project <docker@cinc.sh>"

ARG CHANNEL=stable
ARG VERSION=25.2.1075
ENV DEBIAN_FRONTEND=noninteractive \
    GEM_HOME=/root/.chefdk/gem/ruby/3.0.0 \
    PATH=/opt/cinc-workstation/bin:/opt/cinc-workstation/embedded/bin:/root/.chefdk/gem/ruby/3.0.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CURL_CA_BUNDLE=/usr/local/share/ca-certificates/ca-bundle.pem

RUN mkdir -p /usr/local/share/ca-certificates/
COPY local-cert-chain-file.txt /usr/local/share/ca-certificates/ca-bundle.pem

# Run the entire container with the default locale to be en_US.UTF-8
RUN apt-get update && \
    apt-get install -y locales=2.35-* && \ 
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN apt-get update && \
    apt-get install -y ca-certificates gpg curl && \
    update-ca-certificates && \
    apt-get install -y gcc=4:11.2.* git=1:2.34.* graphviz=2.42.* make=4.3-* rsync=3.2.* ssh=1:8.9p1-* vim-tiny=2:8.2.* wget=1.21.* && \ 
    ln -s /usr/bin/vi /usr/bin/vim && \
    wget --content-disposition "http://ftp-osl.osuosl.org/pub/cinc/files/stable/cinc-auditor/6.8.24/debian/12/cinc-auditor_6.8.24-1_amd64.deb" -O /tmp/cinc-auditor.deb && \
    dpkg -i /tmp/cinc-auditor.deb

RUN curl -fsSLk https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
        gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
        tee /etc/apt/sources.list.d/kubernetes.list && \
    chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
    apt-get -o Acquire::https::Verify-Peer=false update && apt-get -o Acquire::https::Verify-Peer=false install -y kubectl

RUN git clone -c http.sslVerify=false https://github.com/inspec/train-k8s-container.git && \
    cinc-auditor plugin install ./train-k8s-container

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/*log /var/log/apt/* /var/lib/dpkg/*-old /var/cache/debconf/*-old

CMD ["/bin/bash"]
