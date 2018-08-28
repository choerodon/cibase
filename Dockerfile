FROM maven:3.5.2-jdk-8-alpine
LABEL Dockerfile = "https://github.com/choerodon/cibase.git"
ENV HELM_VERSION="v2.8.2" \
    YQ_VERSION="2.1.1"
RUN apk --no-cache add \
    docker \
    mysql-client \
    xmlstarlet \
    openssl \
    ca-certificates \
    openssh \
    jq
RUN wget -O /usr/bin/yq \
    "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" && \
    chmod +x /usr/bin/yq  && \
    wget "https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    tar xzf "helm-${HELM_VERSION}-linux-amd64.tar.gz" -C tmp && \
    rm -r "helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    mv /tmp/linux-amd64/helm /usr/bin/helm && \
    helm init -c && \
    helm plugin install https://github.com/chartmuseum/helm-push
