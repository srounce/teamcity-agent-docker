FROM java:latest

ENV CONTAINER_BUILD_DATE `date`
ENV DEBIAN_FRONTEND noninteractive

# Setup teamcity-agent and his data dir
RUN adduser --disabled-password --gecos "" teamcity-agent\
    && mkdir -p /data\
    && chown -R teamcity-agent:root /data \
		&& curl -sSL https://get.docker.com/ | sh \
    && apt-get update -qq\
			&& apt-get install -qqy \
				$BUILD_PACKAGES \
				python \
				build-essential\
				unzip\
				git\
			&& apt-get remove $BUILD_PACKAGES \
			&& apt-get clean autoclean\
			&& apt-get autoremove -y\
			&& rm -rf /var/lib/{apt,dpkg,cache,log}/ \
			&& service docker start && systemctl enable docker.service

ENV CLOUDSDK_PYTHON_SITEPACKAGES 1
RUN wget https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.zip && unzip google-cloud-sdk.zip && rm google-cloud-sdk.zip && \
    google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/home/teamcity-agent/.bashrc --additional-components app-engine-python app kubectl alpha beta && \
    chmod -R +rx /google-cloud-sdk/bin

# Install phantomjs
#ENV PHANTOMJS phantomjs-2.1.1-linux-x86_64

#RUN curl -Ls https://bitbucket.org/ariya/phantomjs/downloads/${PHANTOMJS}.tar.bz2\
    #| tar --strip=2 -jx ${PHANTOMJS}/bin/phantomjs -C /usr/bin

# prepare docker-in-docker (with some sane defaults here,
# which should be overridden via `docker run -e ADDITIONAL_...`)
# example to map group details from the host to the container env:
# -e ADDITIONAL_GID=$(stat -c %g /var/run/docker.sock)
# -e ADDITIONAL_GROUP=$(stat -c %G /var/run/docker.sock)
ENV ADDITIONAL_GID 4711
ENV ADDITIONAL_GROUP docker

EXPOSE 9090

ADD docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT /docker-entrypoint.sh
