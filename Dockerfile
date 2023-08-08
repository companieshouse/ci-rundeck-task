FROM alpine:3.18.3

RUN apk upgrade --no-cache && \
    apk add --no-cache bash curl jq

ENTRYPOINT ["/bin/bash"]