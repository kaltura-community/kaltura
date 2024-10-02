ARG VERSION="Tucana-20.9.0"
ARG BASE_IMAGE=php:8.2-apache-bookworm
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC

ARG BASE_DIR=/opt/kaltura
ARG APP_DIR=${BASE_DIR}/app
ARG WEB_DIR=${BASE_DIR}/web
ARG APPS_DIR=${BASE_DIR}/apps
ARG TMP_DIR=${BASE_DIR}/tmp
ARG LOG_DIR=${BASE_DIR}/log

FROM ${BASE_IMAGE} AS kaltura-base

ARG VERSION
ARG BASE_DIR
ARG APP_DIR
ARG WEB_DIR
ARG APPS_DIR
ARG TMP_DIR
ARG LOG_DIR

#Install Dependencies
RUN mkdir -p ${BASE_DIR} && \
    mkdir -p ${APP_DIR}/cache && \
    mkdir -p ${WEB_DIR} && \
    mkdir -p ${APPS_DIR} && \
    mkdir -p ${TMP_DIR} && \
    mkdir -p ${LOG_DIR}

ADD https://github.com/kaltura/server.git#${VERSION} ${APP_DIR}

RUN ln -s ${APP_DIR}/api_v3/web ${APP_DIR}/alpha/web/api_v3

FROM kaltura-base AS generate-clients

ARG VERSION
ARG BASE_DIR
ARG APP_DIR

SHELL ["/bin/bash", "-c"]

WORKDIR ${BASE_DIR}

# Clone the repository
ADD https://github.com/kaltura/clients-generator.git#${VERSION} ${BASE_DIR}/clients-generator

# Generate the clients
RUN for file in $(find ${APP_DIR}/configurations -type f); do mv $file ${file/.template}; done && \
    php ${APP_DIR}/api_v3/generator/generate_xml.php /tmp && \
    php ${APP_DIR}/generator/generate.php -x /tmp/KalturaClient.xml

RUN tar -czf ${TMP_DIR}/clients-libs-${VERSION}.tar.gz  ${WEB_DIR}/content/clientlibs

FROM scratch

ARG TMP_DIR
ARG VERSION
COPY --from=generate-clients ${TMP_DIR}/clients-libs-${VERSION}.tar.gz /clients-libs-${VERSION}.tar.gz
