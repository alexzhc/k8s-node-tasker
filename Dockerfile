FROM alpine

RUN set -x && \ 
    apk add curl && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    install ./kubectl /usr/bin/

ADD *.yaml /

ADD entry.sh /usr/bin

ENTRYPOINT ["entry.sh"]

