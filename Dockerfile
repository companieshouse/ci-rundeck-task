FROM 416670754337.dkr.ecr.eu-west-2.amazonaws.com/ci-core-runtime:1.1.0

SHELL ["/bin/bash", "-c"]

RUN dnf update -y && \
    dnf install -y \
        jq-1.7.1

COPY scripts scripts
