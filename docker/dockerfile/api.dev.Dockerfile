#############
## Builder ##
#############

FROM rust:slim as BUILDER

WORKDIR /usr/src

# Create blank project
RUN cargo new adsbdb

# We want dependencies cached, so copy those first
COPY Cargo.* /usr/src/adsbdb/

# Set the working directory
WORKDIR /usr/src/adsbdb

# This is a dummy build to get the dependencies cached - probably not needed - as run via a github action
RUN cargo build --release

# Now copy in the rest of the sources
COPY src /usr/src/adsbdb/src/

## Touch main.rs to prevent cached release build
RUN touch /usr/src/adsbdb/src/main.rs

# This is the actual application build
RUN cargo build --release

#############
## Runtime ##
#############

FROM ubuntu:22.04 as RUNTIME

ARG DOCKER_GUID=1000 \
	DOCKER_UID=1000 \
	DOCKER_TIME_CONT=Europe\
	DOCKER_TIME_CITY=Berlin \
	DOCKER_APP_USER=app_user \
	DOCKER_APP_GROUP=app_group

ENV TZ=${DOCKER_TIME_CONT}/${DOCKER_TIME_CITY}

RUN apt-get update \
	&& apt-get install -y ca-certificates wget \
	&& update-ca-certificates \
	&& groupadd --gid ${DOCKER_GUID} ${DOCKER_APP_GROUP} \
	&& useradd --no-create-home --no-log-init --uid ${DOCKER_UID} --gid ${DOCKER_GUID} ${DOCKER_APP_USER} \
	&& mkdir /healthcheck /logs \
	&& chown ${DOCKER_APP_USER}:${DOCKER_APP_GROUP} /logs

WORKDIR /app

COPY --chown=${DOCKER_APP_USER}:${DOCKER_APP_GROUP} docker/healthcheck/health_api.sh /healthcheck/

RUN chmod +x /healthcheck/health_api.sh

COPY --from=BUILDER /usr/src/adsbdb/target/release/adsbdb /app/

# COPY --from=BUILDER ./target/release/adsbdb /app/

# Use an unprivileged user
USER ${DOCKER_APP_USER}

CMD ["/app/adsbdb"]