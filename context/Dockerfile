FROM continuumio/miniconda:4.1.11

# NOTE: Versions have been pinned everywhere. These are the latest versions at the moment, because
# I want to ensure predictable behavior, but I don't know of any problems with higher versions:
# It would be good to update these over time.

# "pip install clodius" complained about missing gcc,
# and "apt-get install gcc" failed and suggested apt-get update.
# (Was having some trouble with installs, so split it up for granular caching.)
RUN apt-get update && apt-get install -y \
        gcc=4:4.9.2-2 \
        nginx=1.6.2-5+deb8u4 \
        supervisor=3.0r1-1 \
        unzip=6.0-16+deb8u2 \
        uwsgi-plugin-python=2.0.7-1 \
        zlib1g-dev=1:1.2.8.dfsg-2+b1 \
    && rm -rf /var/lib/apt/lists/*

# Keep big dependencies which are unlikely to change near the top of this file.
RUN conda install --yes cython==0.25.2 numpy=1.11.2
RUN conda install --yes --channel bioconda pysam=0.9.1.4 htslib=1.3.2
RUN pip install uwsgi==2.0.14


# TODO: We want to use goofys (if we can randomly access files), which in turn requires go...
# Not working yet, but if the prereqs themselves cause problems, good to figure that out soon.
# Install Go
ENV GO_TAR go1.7.5.linux-amd64.tar.gz
RUN wget https://storage.googleapis.com/golang/$GO_TAR && tar -C /usr/local -xzf $GO_TAR && rm $GO_TAR
ENV PATH $PATH:/usr/local/go/bin
RUN go version


# Setup home directory
RUN groupadd -r higlass && useradd -r -g higlass higlass
WORKDIR /home/higlass
RUN chown higlass:higlass .
USER higlass


# Build goofys
# TODO: There are supposed to be prebuilt images, but wasn't clear how they would be installed?
ENV GOPATH /home/higlass/go-workspace
RUN go get github.com/kahing/goofys
#RUN git checkout a tagged release
# Just doing the checkout didn't work for me; could be a dumb mistake.
#RUN git clone --depth 1 https://github.com/kahing/goofys.git $GOPATH/src/github.com/kahing/goofys
RUN go install github.com/kahing/goofys
# TODO: start it with AWS credentials and the bucket ID
RUN $GOPATH/bin/goofys --version


# Setup server
WORKDIR /home/higlass/projects
USER root
RUN chown higlass:higlass .
USER higlass
RUN git clone --depth 1 https://github.com/hms-dbmi/higlass-server.git --branch v0.2.1
WORKDIR higlass-server
VOLUME data

USER root
RUN pip install clodius==0.3.2
RUN pip install -r requirements.txt
USER higlass

RUN python manage.py migrate
WORKDIR ..


# Setup website (includes client js)
ENV SITE_REPO higlass-website
ENV SITE_VERSION 0.2.0
RUN wget https://github.com/hms-dbmi/$SITE_REPO/releases/download/v$SITE_VERSION/dist.zip
RUN unzip dist.zip -d higlass-website


# Setup supervisord and nginx
USER root
COPY supervisord.conf .
COPY nginx.conf /etc/nginx/
COPY sites-enabled/* /etc/nginx/sites-enabled/
COPY uwsgi.ini .
COPY uwsgi_params /home/higlass/projects/higlass-server/
# TODO: Is it confusing to have this file in a directory which is otherwise a git checkout?

RUN rm /etc/nginx/sites-*/default && grep 'listen' /etc/nginx/sites-*/*
# Without this, two config files are trying to grab port 80:
# nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)

# TODO: Needs to write to logs, but running as root is risky
# Given as list so that an extra shell does not need to be started.
CMD ["supervisord", "-n"]
