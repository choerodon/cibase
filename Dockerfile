FROM gcr.io/kaniko-project/executor:v0.9.0
FROM maven:3.5.2-jdk-8-slim
COPY --from=0 /kaniko/executor /usr/local/bin/kaniko
ENV TZ="Asia/Shanghai" \
    HELM_VERSION="v2.8.2" \
    HELM_PUSH_VERSION="v0.7.1" \
    YQ_VERSION="2.1.2" \
    DOCKER_VERSION="17.06.2"
# # Add mirror source
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
    echo 'deb http://mirrors.aliyun.com/debian stretch main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian stretch-proposed-updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian stretch-updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian-security/ stretch/updates main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb-src http://mirrors.aliyun.com/debian stretch main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb-src http://mirrors.aliyun.com/debian stretch-proposed-updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb-src http://mirrors.aliyun.com/debian stretch-updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb-src http://mirrors.aliyun.com/debian-security/ stretch/updates main non-free contrib' >> /etc/apt/sources.list
# Install base packages
RUN apt-get update && apt-get install -y \
        jq \
        vim \
        git \
        tar \
        gzip \
        zip \
        unzip \
        bzip2 \
        curl \
        wget \
        locales \
        netcat \
        net-tools \
        python2.7 \
        python-pip \
        xmlstarlet \
        mysql-client \
        openssh-client \
        gettext \
        ca-certificates && \
	rm -rf /var/lib/apt/lists/* 
RUN ln -s /usr/bin/xmlstarlet /usr/bin/xml && \
    wget -O /usr/bin/yq \
        "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" && \
    chmod +x /usr/bin/yq  && \
    wget -O "/tmp/docker-${DOCKER_VERSION}-ce.tgz" \
        "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}-ce.tgz" && \
    tar zxf "/tmp/docker-${DOCKER_VERSION}-ce.tgz" -C /tmp && \
    mv -f /tmp/docker/docker* /usr/bin && \
    wget -O "/tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
        "https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    tar xzf "/tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz" -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/bin/helm && \
    rm -r /tmp/* && \
    helm init -c && \
    helm plugin install --version $HELM_PUSH_VERSION https://github.com/chartmuseum/helm-push
