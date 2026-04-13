FROM 416670754337.dkr.ecr.eu-west-2.amazonaws.com/ci-core-runtime:1.1.0

ARG PLATFORM_TOOLS_VERSION=1.0.6

SHELL ["/bin/bash", "-c"]

RUN dnf update -y && \
    dnf install -y \
        dnf-utils-4.3.0 \
        jq-1.7.1 && \
    dnf clean all

RUN rpm --import http://yum-repository.platform.aws.chdev.org/RPM-GPG-KEY-platform-noarch && \
    yum-config-manager --add-repo http://yum-repository.platform.aws.chdev.org/platform-noarch.repo && \
    dnf install -y \
        platform-tools-common-${PLATFORM_TOOLS_VERSION} && \
    yum clean all

COPY scripts scripts
