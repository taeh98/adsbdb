FROM postgres:15-alpine3.18

ARG DOCKER_GUID=1000 \
	DOCKER_UID=1000 \
	DOCKER_TIME_CONT=Europe\
	DOCKER_TIME_CITY=Berlin \
	DOCKER_APP_USER=app_user \
	DOCKER_APP_GROUP=app_group

ENV TZ=${DOCKER_TIME_CONT}/${DOCKER_TIME_CITY}

RUN apk add --update --no-cache tzdata \
	&& cp /usr/share/zoneinfo/${TZ} /etc/localtime \
	&& echo ${TZ} > /etc/timezone \
	&& addgroup -g ${DOCKER_GUID} -S ${DOCKER_APP_GROUP} \
	&& adduser -u ${DOCKER_UID} -S -G ${DOCKER_APP_GROUP} ${DOCKER_APP_USER} \
	&& mkdir /pg_data /healthcheck /init \
	&& chown -R ${DOCKER_APP_USER}:postgres /pg_data \
	&& chown -R ${DOCKER_APP_USER}:${DOCKER_APP_GROUP} /healthcheck /init


# From dump OR scratch
COPY --chown=${DOCKER_APP_USER}:${DOCKER_APP_GROUP} docker/init/dev.postgres_init.sh /docker-entrypoint-initdb.d/
# This is a bit of a hack, for pg_dump.tar
COPY --chown=${DOCKER_APP_USER}:${DOCKER_APP_GROUP} docker/init/init_db.sql docker/data/pg_dump.tar* /init/

COPY --chown=${DOCKER_APP_USER}:${DOCKER_APP_GROUP} docker/confs/.psqlrc /home/app_user/

COPY --chown=${DOCKER_APP_USER}:${DOCKER_APP_GROUP} docker/healthcheck/health_postgres.sh /healthcheck/

RUN chmod +x /healthcheck/health_postgres.sh /docker-entrypoint-initdb.d/dev.postgres_init.sh

USER ${DOCKER_APP_USER}