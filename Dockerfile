FROM hashicorp/terraform:1.10.1

RUN apk add --no-cache python3 py3-pip aws-cli

WORKDIR /app

COPY . .

CMD ["/bin/sh"]