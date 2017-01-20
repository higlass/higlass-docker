FROM continuumio/miniconda:4.1.11

# "pip install clodius" complained about missing gcc,
# and "apt-get install gcc" failed and suggested apt-get update.
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get --yes install gcc

# Keep big dependencies which are unlikely to change near the top of this file.
RUN conda install --yes cython==0.25.2 numpy=1.11.2
RUN conda install --yes --channel bioconda pysam=0.9.1.4 htslib=1.3.2

# TODO: Need new releases for both
RUN git clone --depth 1 https://github.com/hms-dbmi/higlass-server.git --branch v0.1.0
RUN git clone --depth 1 https://github.com/hms-dbmi/higlass.git --branch v0.3.0

# Setup server
WORKDIR higlass-server
RUN pip install clodius==0.3.2
RUN pip install -r requirements.txt
RUN python manage.py migrate
# TODO: WORKDIR ..

# Setup client
# TODO: Build the UI files

# TODO: Install and configure nginx

# TODO: Run nginx instead of django
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]