FROM gcr.io/kaniko-project/executor:v1.3.0 AS kaniko
FROM maven:3-jdk-8-alpine

ENV SONAR_SCANNER_HOME="/opt/sonar-scanner" \
    SONAR_SCANNER_VERSION="4.3.0.2102"

ENV TZ="Asia/Shanghai" \
    YQ_VERSION="3.4.1" \
    HELM_VERSION="v3.4.0" \
    DOCKER_VERSION="19.03.13" \
    HELM_PUSH_VERSION="v0.9.0" \
    PATH="${SONAR_SCANNER_HOME}/bin:/kaniko:${PATH}"

# Install kaniko sonar-scanner-cli
COPY --from=kaniko /kaniko /kaniko
COPY sonar-scanner/bin /opt/sonar-scanner/bin
COPY sonar-scanner/conf /opt/sonar-scanner/conf
COPY sonar-scanner/lib /opt/sonar-scanner/lib

# Install base packages
RUN set -eux; \
    docker-credential-gcr config --token-source=env; \
    ln -s /kaniko/executor /kaniko/kaniko; \
    apk --no-cache add \
        xz \
        jq \
        git \
        npm \
        yarn \
        dpkg \
        unzip \
        python \
        py-pip \
        dpkg-dev \
        xmlstarlet \
        mysql-client \
        ca-certificates && \
    apkArch="$(apk --print-arch)"; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    # install pylint
    pip install -U --no-cache-dir pylint && \
    # don't use embedded jre
    sed -i '/use_embedded_jre=true/d' /opt/sonar-scanner/bin/sonar-scanner && \
    # install docker client
    echo "https://download.docker.com/linux/static/stable/${apkArch}/docker-${DOCKER_VERSION}.tgz" && \
    wget -qO "/tmp/docker-${DOCKER_VERSION}-ce.tgz" \
        "https://download.docker.com/linux/static/stable/${apkArch}/docker-${DOCKER_VERSION}.tgz" && \
    tar zxf "/tmp/docker-${DOCKER_VERSION}-ce.tgz" -C /tmp && \
    mv /tmp/docker/docker /usr/bin && \
    # install yq
    echo "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${dpkgArch}" && \
    wget -qO /usr/bin/yq \
        "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${dpkgArch}" && \
    chmod a+x /usr/bin/yq  && \
    # install helm
    echo "https://get.helm.sh/helm-${HELM_VERSION}-linux-${dpkgArch}.tar.gz" && \
    wget -qO "/tmp/helm-${HELM_VERSION}-linux-${dpkgArch}.tar.gz" \
        "https://get.helm.sh/helm-${HELM_VERSION}-linux-${dpkgArch}.tar.gz"  && \
    tar xzf "/tmp/helm-${HELM_VERSION}-linux-${dpkgArch}.tar.gz" -C /tmp && \
    mv /tmp/linux-${dpkgArch}/helm /usr/bin/helm && \
    # post install
    rm -r /tmp/* && \
    helm plugin install --version $HELM_PUSH_VERSION https://github.com/chartmuseum/helm-push && \
    npm install -g typescript@3.6.3

# Add mirror source
RUN cp /etc/apk/repositories /etc/apk/repositories.bak && \
    sed -i 's dl-cdn.alpinelinux.org mirrors.aliyun.com g' /etc/apk/repositories