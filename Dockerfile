FROM alpine:3.18.3

RUN apk upgrade --no-cache && \
    apk add --no-cache bash~=5.2 curl~=8.2 jq~=1.6

COPY scripts scripts

ENTRYPOINT ["/bin/bash"]
