FROM hashicorp/terraform:1.10.1

RUN apk add --no-cache python3 py3-pip \
    && pip3 install awscli \
    && apk --purge del py3-pip

WORKDIR /app

COPY . .

CMD ["/bin/sh"]