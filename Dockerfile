# FROM gcr.io/kaniko-project/executor:v0.9.0
FROM registry.cn-hangzhou.aliyuncs.com/setzero/executor:v0.9.0
# FROM maven:3-jdk-8-alpine
FROM dockerhub.azk8s.cn/library/maven:3-jdk-8-alpine
ENV TZ="Asia/Shanghai" \
    YQ_VERSION="2.4.0" \
    IMG_VERSION="v0.5.7" \
    HELM_VERSION="v2.13.1" \
    DOCKER_VERSION="18.06.3" \
    HELM_PUSH_VERSION="v0.7.1" \
    YQ_SHA256="99a01ae32f0704773c72103adb7050ef5c5cad14b517a8612543821ef32d6cc9" \
    DOCKER_SHA256="346f9394393ee8db5f8bd1e229ee9d90e5b36931bdd754308b2ae68884dd6822"

# Add mirror source
RUN cp /etc/apk/repositories /etc/apk/repositories.bak && \
    sed -i 's dl-cdn.alpinelinux.org mirrors.aliyun.com g' /etc/apk/repositories

# Install kaniko
COPY --from=0 /kaniko/executor /usr/bin/kaniko
# Install base packages
RUN apk --no-cache add \
        jq \
        git \
        npm \
        xmlstarlet \
        mysql-client \
        ca-certificates && \
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
    HELM_SHA256=`curl -sSL "https://mirror.azure.cn/kubernetes/helm/helm-${HELM_VERSION}-linux-amd64.tar.gz.sha256"` && \
    wget -qO "/tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
        "https://mirror.azure.cn/kubernetes/helm/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    echo "${HELM_SHA256}  /tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz" | sha256sum -c - && \
    tar xzf "/tmp/helm-${HELM_VERSION}-linux-amd64.tar.gz" -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/bin/helm && \
    # post install
    rm -r /tmp/* && \
    helm init -c --stable-repo-url=https://mirror.azure.cn/kubernetes/charts/ && \
    helm plugin install --version $HELM_PUSH_VERSION https://github.com/chartmuseum/helm-push