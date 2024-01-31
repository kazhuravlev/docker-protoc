FROM golang:1.21

ENV GOBIN="/usr/local/bin"

RUN apt-get update && \
    apt-get install -y \
      npm \
      python3-pip \
      unzip && \
    apt-get clean

# common packages
# https://github.com/go-task/task/releases
ENV TASK_VERSION 3.33.0
# https://github.com/yoheimuta/protolint/releases
ENV PROTOLINT_VERSION 0.47.5
# https://github.com/protocolbuffers/protobuf/releases
ENV PROTOC_VERSION 25.2


RUN echo "Download common packages"
RUN curl -sfL "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_amd64.tar.gz" -o /tmp/task.tar.gz 
RUN curl -sfL "https://github.com/yoheimuta/protolint/releases/download/v${PROTOLINT_VERSION}/protolint_${PROTOLINT_VERSION}_linux_amd64.tar.gz" -o /tmp/protolint.tar.gz
RUN curl -sfL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip" -o /tmp/protoc.zip

# ts packages
# https://www.npmjs.com/package/ts-proto
ENV TS_PROTO_VERSION 1.83.0

RUN echo "Install ts packages" && \
    npm install --prefix=/opt --save ts-proto@${TS_PROTO_VERSION}


# go packages
# https://github.com/grpc-ecosystem/grpc-gateway/releases/
ENV GRPC_GATEWAY_VERSION 2.19.0
# https://github.com/protocolbuffers/protobuf-go/releases
ENV PROTOC_GEN_GO_VERSION 1.32.0
# https://github.com/grpc/grpc-go/tags
ENV PROTOC_GEN_GO_GPPC_VERSION 1.61.0
# https://github.com/envoyproxy/protoc-gen-validate/tags
ENV PROTOC_GEN_VALIDATE_VERSION 1.0.4

RUN echo "Install go packages"
RUN curl -sfL "https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v${GRPC_GATEWAY_VERSION}/protoc-gen-grpc-gateway-v${GRPC_GATEWAY_VERSION}-linux-x86_64" -o /usr/local/bin/protoc-gen-grpc-gateway
RUN curl -sfL "https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v${GRPC_GATEWAY_VERSION}/protoc-gen-openapiv2-v${GRPC_GATEWAY_VERSION}-linux-x86_64" -o /usr/local/bin/protoc-gen-openapi
RUN curl -sfL "https://github.com/protocolbuffers/protobuf-go/releases/download/v${PROTOC_GEN_GO_VERSION}/protoc-gen-go.v${PROTOC_GEN_GO_VERSION}.linux.amd64.tar.gz" -o /tmp/protoc_gen_go.tar.gz
RUN git clone https://github.com/grpc/grpc-go && cd grpc-go/cmd/protoc-gen-go-grpc && git checkout tags/v${PROTOC_GEN_GO_GPPC_VERSION} && go install && cd - && rm -rf grpc-go


# py packages
ENV PY_PROTOBUF_VERSION 4.25.2
ENV PY_TYPES_PROTOBUF_VERSION 4.24.0.4
ENV PY_GOOGLEAPIS_COMMON_PROTO_VERSION 1.62.0
ENV PY_MYPY_PROTOBUF_VERSION 3.5.0
ENV PY_GRPCIO_VERSION 1.60.0
ENV PY_GRPCIO_TOOLS_VERSION 1.60.0

RUN echo "Install py packages"
RUN pip3 install --break-system-packages --upgrade pip
RUN python3 -m pip install --break-system-packages --upgrade setuptools

RUN pip3 install --break-system-packages mypy-protobuf==${PY_MYPY_PROTOBUF_VERSION}
RUN pip3 install --break-system-packages protobuf==${PY_PROTOBUF_VERSION}
RUN pip3 install --break-system-packages types-protobuf==${PY_TYPES_PROTOBUF_VERSION}
RUN pip3 install --break-system-packages googleapis-common-protos==${PY_GOOGLEAPIS_COMMON_PROTO_VERSION}

RUN pip3 install --break-system-packages --no-cache-dir --force-reinstall -Iv grpcio==${PY_GRPCIO_VERSION}
RUN pip3 install --break-system-packages --no-cache-dir --force-reinstall -Iv grpcio-tools==${PY_GRPCIO_TOOLS_VERSION}

RUN echo "Unpack downloaded archives"
RUN	cd /tmp && \
	tar -xzf /tmp/protoc_gen_go.tar.gz && mv protoc-gen-go /usr/local/bin/protoc-gen-go && \
	tar -xzf task.tar.gz && \
	tar -xzf protolint.tar.gz && \
	unzip protoc.zip -d protoc && \
	ls -lah /tmp && \
	mv task /usr/local/bin/ && \
	mv protolint /usr/local/bin/ && \
	mv protoc/bin/protoc /usr/local/bin/ && \
	mv protoc/include/* /usr/local/include/ && \
	chmod +x /usr/local/bin/* && \
	rm -rf /tmp/*

RUN echo "Build protoc-gen-validate"
# Should be runned after protoc will be visible in ${PATH}
RUN curl -sfL "https://github.com/envoyproxy/protoc-gen-validate/archive/refs/tags/v${PROTOC_GEN_VALIDATE_VERSION}.tar.gz" -o /tmp/protoc-gen-validate.tar.gz
RUN cd /tmp && \
    tar -xzf /tmp/protoc-gen-validate.tar.gz && \
    cd /tmp/protoc-gen-validate-${PROTOC_GEN_VALIDATE_VERSION} && \
    make build && \
    cd && \
    rm -rf /tmp/*
