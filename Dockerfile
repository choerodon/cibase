FROM gcr.io/kaniko-project/executor:v0.22.0 AS kaniko
FROM sonarsource/sonar-scanner-cli:4.3 AS sonar-scanner-cli
FROM maven:3-jdk-8-alpine

ENV SONAR_SCANNER_HOME="/opt/sonar-scanner" \
    SONAR_SCANNER_VERSION="4.3.0.2102"

ENV TZ="Asia/Shanghai" \
    YQ_VERSION="3.2.1" \
    IMG_VERSION="v0.5.7" \
    HELM_VERSION="v2.16.3" \
    DOCKER_VERSION="18.06.3" \
    HELM_PUSH_VERSION="v0.8.1" \
    YQ_SHA256="11a830ffb72aad0eaa7640ef69637068f36469be4f68a93da822fbe454e998f8" \
    DOCKER_SHA256="346f9394393ee8db5f8bd1e229ee9d90e5b36931bdd754308b2ae68884dd6822" \
    PATH="${SONAR_SCANNER_HOME}/bin:${PATH}"

# Add mirror source
RUN cp /etc/apk/repositories /etc/apk/repositories.bak && \
    sed -i 's dl-cdn.alpinelinux.org mirrors.aliyun.com g' /etc/apk/repositories

# Install kaniko sonar-scanner-cli
COPY --from=kaniko /kaniko/executor /usr/bin/kaniko
COPY --from=sonar-scanner-cli /opt/sonar-scanner/bin /opt/sonar-scanner/bin
COPY --from=sonar-scanner-cli /opt/sonar-scanner/conf /opt/sonar-scanner/conf
COPY --from=sonar-scanner-cli /opt/sonar-scanner/lib /opt/sonar-scanner/lib

# Install base packages
RUN apk --no-cache add \
        xz \
        jq \
        git \
        npm \
        yarn \
        unzip \
        python \
        py-pip \
        xmlstarlet \
        mysql-client \
        ca-certificates && \
    # install pylint
    pip install -U --no-cache-dir pylint && \
    # don't use embedded jre
    sed -i '/use_embedded_jre=true/d' /opt/sonar-scanner/bin/sonar-scanner && \
    # install docker client
    wget -qO "/tmp/docker-${DOCKER_VERSION}-ce.tgz" \
        "https://mirror.azure.cn/docker-ce/linux/static/stable/x86_64/docker-${DOCKER_VERSION}-ce.tgz" && \
    echo "${DOCKER_SHA256}  /tmp/docker-${DOCKER_VERSION}-ce.tgz" | sha256sum -c - && \
    tar zxf "/tmp/docker-${DOCKER_VERSION}-ce.tgz" -C /tmp && \
    mv /tmp/docker/docker /usr/bin && \
    # install yq
    wget -qO /usr/bin/yq \
        "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" && \
    echo "${YQ_SHA256}  /usr/bin/yq" | sha256sum -c - && \
    chmod a+x /usr/bin/yq  && \
    # install img
    IMG_SHA256=`curl -sSL "https://github.com/genuinetools/img/releases/download/${IMG_VERSION}/img-linux-amd64.sha256" | awk '{print $1}'` && \
    wget -qO /usr/bin/img \
        "https://github.com/genuinetools/img/releases/download/${IMG_VERSION}/img-linux-amd64" && \
    echo "${IMG_SHA256}  /usr/bin/img" | sha256sum -c - && \
    chmod a+x /usr/bin/img  && \
    # install helm
    HELM_SHA256=`curl -sSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz.sha256"` && \
    wget -qO "/tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
        "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"  && \
    echo "${HELM_SHA256}  /tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz" | sha256sum -c - && \
    tar xzf "/tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz" -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/bin/helm && \
    # post install
    rm -r /tmp/* && \
    helm init -c --stable-repo-url=https://mirror.azure.cn/kubernetes/charts/ && \
    helm plugin install --version $HELM_PUSH_VERSION https://github.com/chartmuseum/helm-push && \
    npm install -g typescript@3.6.3