ARG VERSION="Tucana-20.9.0"
ARG BASE_IMAGE=debian:bullseye-slim
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC

ARG BASE_DIR=/opt/kaltura
ARG APP_DIR=${BASE_DIR}/app
ARG WEB_DIR=${BASE_DIR}/web
ARG APPS_DIR=${BASE_DIR}/apps
ARG TMP_DIR=${BASE_DIR}/tmp
ARG LOG_DIR=${BASE_DIR}/log

FROM ${BASE_IMAGE} as kaltura-base

ARG BASE_DIR
ARG APP_DIR
ARG WEB_DIR
ARG APPS_DIR
ARG TMP_DIR
ARG LOG_DIR

#Install Dependencies
RUN apt-get update --yes && \
    apt-get install --no-install-recommends --yes \
    apache2 \
    php7.4 \
    php7.4-fpm \
    php7.4-opcache \
    php7.4-mbstring \
    php7.4-json \
    php7.4-xml \
    php7.4-curl \
    php7.4-redis \
    php7.4-memcached \
    php7.4-apcu && \
    mkdir -p ${BASE_DIR} && \
    mkdir -p ${APP_DIR}/cache && \
    mkdir -p ${WEB_DIR} && \
    mkdir -p ${APPS_DIR} && \
    mkdir -p ${TMP_DIR} && \
    mkdir -p ${LOG_DIR}

COPY ./server ${APP_DIR}

RUN ln -s ${APP_DIR}/api_v3/web ${APP_DIR}/alpha/web/api_v3

FROM kaltura-base as generate-clients

ARG VERSION
ARG BASE_DIR
ARG APP_DIR

SHELL ["/bin/bash", "-c"]

WORKDIR ${BASE_DIR}

RUN apt-get install --no-install-recommends --yes \
    git \
    ca-certificates

# Clone the repository
RUN git clone --depth=1 -b $(cat ${APP_DIR}/VERSION.txt) https://github.com/kaltura/clients-generator.git

# Generate the clients
RUN for file in $(find ${APP_DIR}/configurations -type f); do mv $file ${file/.template}; done && \
    php ${APP_DIR}/api_v3/generator/generate_xml.php /tmp && \
    php ${APP_DIR}/generator/generate.php -x /tmp/KalturaClient.xml

RUN tar -czf ${TMP_DIR}/clients-libs-$(cat ${APP_DIR}/VERSION.txt).tar.gz  ${WEB_DIR}/content/clientlibs
FROM scratch

ARG TMP_DIR
ARG VERSION
COPY --from=generate-clients ${TMP_DIR}/clients-libs-${VERSION}.tar.gz /clients-libs-${VERSION}.tar.gz