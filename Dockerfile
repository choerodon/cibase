FROM golang:1.9.4-alpine3.7 as builder
WORKDIR /go/src/GetVersion
COPY . .
RUN go build .

FROM maven:3.5.2-jdk-8-alpine
LABEL Dockerfile = "https://github.com/choerodon/cibase.git"
ENV MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=256m" \
    LIQUIBASE_TOOL_VERSION="1.0.4" \
    HELM_VERSION="v2.8.2" \
    YQ_VERSION="1.14.1"
COPY --from=builder /go/src/GetVersion/GetVersion /usr/bin/GetVersion
RUN apk --no-cache add docker mysql-client xmlstarlet openssl ca-certificates openssh
RUN \
    wget -O /usr/bin/yq \
    "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" && \
    chmod +x /usr/bin/yq  && \
    wget "https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    tar xzf "helm-${HELM_VERSION}-linux-amd64.tar.gz" -C tmp && \
    rm -r "helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    mv /tmp/linux-amd64/helm /usr/bin/helm && \
    helm init -c && \
    helm plugin install https://github.com/chartmuseum/helm-push