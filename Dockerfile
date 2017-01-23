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
        unzip \
        uwsgi-plugin-python=2.0.7-1 \
        zlib1g-dev=1:1.2.8.dfsg-2+b1 \
    && rm -rf /var/lib/apt/lists/*

# Keep big dependencies which are unlikely to change near the top of this file.
RUN conda install --yes cython==0.25.2 numpy=1.11.2
RUN conda install --yes --channel bioconda pysam=0.9.1.4 htslib=1.3.2

# Setup nginx
COPY sites-enabled/* /etc/nginx/sites-enabled/
#RUN /etc/init.d/nginx restart
# TODO: Does nginx restart make any filesystem changes?

RUN groupadd -r higlass && useradd -r -g higlass higlass
WORKDIR /home/higlass
RUN chown higlass:higlass .
USER higlass
RUN git clone --depth 1 https://github.com/hms-dbmi/higlass-server.git --branch v0.1.0


# Setup server
WORKDIR higlass-server
VOLUME data

USER root
RUN pip install clodius==0.3.2
RUN pip install -r requirements.txt
USER higlass

RUN python manage.py migrate
WORKDIR ..


# Setup client
ENV CLIENT_REPO higlass
ENV CLIENT_VERSION 0.3.0
RUN wget https://github.com/hms-dbmi/$CLIENT_REPO/archive/v$CLIENT_VERSION.zip
RUN unzip v$CLIENT_VERSION.zip
RUN mv $CLIENT_REPO-$CLIENT_VERSION higlass-client


# Setup website
ENV SITE_REPO higlass-website
ENV SITE_VERSION 0.0.1
# TODO: There is no release
#RUN wget https://github.com/hms-dbmi/$SITE_REPO/archive/v$SITE_VERSION.zip
#RUN unzip v$SITE_VERSION.zip
#RUN mv $SITE_REPO-$SITE_VERSION higlass-website


EXPOSE 8000
# Given as list so that an extra shell does not need to be started.
CMD ["uwsgi", "--socket", ":8000", "--plugins", "python", "--module", "higlass_server.wsgi"]
