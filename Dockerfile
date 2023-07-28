FROM arm64v8/alpine:3.14.2
ARG AWSCLI_VERSION=2.11.20

RUN apk update && apk add --no-cache \
    chromium \
    nodejs \
    npm \
    python3 \
    jq \
    curl \
    unzip \
    udev \
    ttf-freefont \
    ca-certificates

# Tell Puppeteer to skip installing Chrome. We'll be using the installed package.
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Install Puppeteer and AWS-Azure-Login globally
RUN npm install -g puppeteer@13.5.0 && \
    npm install -g aws-azure-login --unsafe-perm

# Create necessary directories and copy scripts
RUN mkdir -p /app/pim
COPY update_config.sh /app/pim/
COPY create_config.py /app/pim/

#  update pip
RUN apk add --no-cache py3-pip && \
    pip install --upgrade pip 

#depencies for awscli v2
RUN apk add --no-cache \
  git \
  groff \
  less \
  mailcap \
  build-base \
  libffi-dev \
  cmake \
  openssl-dev \
  python3-dev

# Install the AWS CLI from source
WORKDIR /tmp

RUN git clone --single-branch --depth 1 -b "${AWSCLI_VERSION}" https://github.com/aws/aws-cli.git && \
  ./aws-cli/configure --with-install-type=portable-exe --with-download-deps && \
  make && \
  make install && \
  rm -rf /tmp/aws-cli \
  && rm -rf \
    /usr/local/lib/aws-cli/aws_completer \
    /usr/local/lib/aws-cli/awscli/data/ac.index \
    /usr/local/lib/aws-cli/awscli/examples \
    && find /usr/local/lib/aws-cli/awscli/data -name "completions-1*.json" -delete && \
    find /usr/local/lib/aws-cli/awscli/botocore/data -name examples-1.json -delete

# Install bash shell
RUN apk add --no-cache bash

# Install the azure cli
RUN apk add --no-cache --update python3 py3-pip && \
    apk add --virtual=build gcc libffi-dev musl-dev openssl-dev gcc python3-dev && \
    pip install azure-cli && \
    apk del --purge build

# Add user as work around for puppeteer security.
RUN addgroup -S pptruser && adduser -S -G pptruser pptruser \
    && mkdir -p /home/pptruser/Downloads /app /home/pptruser/.aws \
    && touch /home/pptruser/.aws/credentials /home/pptruser/.aws/config \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /app

# Run everything after as non-privileged user.
USER pptruser

WORKDIR /app/pim

# Set the command to run aws configure and the Node.js command using shell
CMD bash -c "node -e \"console.log('alpine linux is installed!')\""
