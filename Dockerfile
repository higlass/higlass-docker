FROM continuumio/miniconda:4.1.11

# "pip install clodius" complained about missing gcc,
# and "apt-get install gcc" failed and suggested apt-get update.
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get --yes install gcc zlib1g-dev uwsgi-plugin-python nginx

# Keep big dependencies which are unlikely to change near the top of this file.
RUN conda install --yes cython==0.25.2 numpy=1.11.2
RUN conda install --yes --channel bioconda pysam=0.9.1.4 htslib=1.3.2

# TODO: Need new releases for both
RUN git clone --depth 1 https://github.com/hms-dbmi/higlass-server.git --branch v0.1.0
# TODO: Rename, and then get rid of explicit directory at the end
RUN git clone --depth 1 https://github.com/hms-dbmi/higlass.git --branch v0.3.0 higlass-client

# Setup server
WORKDIR higlass-server
RUN pip install clodius==0.3.2
RUN pip install -r requirements.txt
RUN python manage.py migrate
WORKDIR ..

# Setup client
WORKDIR higlass-client
RUN npm install
WORKDIR ..

# Setup nginx
COPY sites-enabled/* /etc/nginx/sites-enabled/
RUN /etc/init.d/nginx restart

EXPOSE 8000
# TODO: Source also has "uwsgi --http :7000 --module api.wsgi &"
# Given as list so that an extra shell does not need to be started.
CMD ["uwsgi", "--socket", ":8000", "--plugins", "python", "--module", "higlass_server.wsgi"]