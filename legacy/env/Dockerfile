############################################################
# Dockerfile based on Ubuntu Image for bioinformatics
############################################################

# Set the base image to use to Ubuntu
FROM ubuntu:14.04

# Set the file maintainer (your name - the file's author)
MAINTAINER "Andre Rendeiro" arendeiro@cemm.oeaw.ac.at

### Configs
# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
# User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

### Install
# basics
RUN apt-get update \
    && apt-get install -y wget cmake git github-backup pandoc

### generic bioinfo
RUN apt-get install -y bedtools samtools picard-tools \
    fastqc ghostscript
 
### python
# dependencies
RUN apt-get install -y python-dev python-pip libmysqlclient-dev \
    libpq-dev libatlas-base-dev libfreetype6-dev

# data + bioinfo libraries
RUN apt-get install -y ipython python-numpy cython python-scipy \
    python-pandas python-matplotlib \
    python-biopython python-scikits-learn python-statsmodels

# more python bioinfo libraries
RUN pip install pybedtools pysam htseq 

# plotting + visualisation
RUN pip install seaborn bokeh lightning-python

### R
ENV R_BASE_VERSION 3.2

## Now install R and littler, and create a link for littler in /usr/local/bin
## Also set a default CRAN repo, and make sure littler knows about it too
RUN apt-get update \
    && apt-get install -y \
        r-base \
        r-base-dev \
        r-recommended \
    && echo 'options(repos = list(CRAN = "http://cran.rstudio.com/"))' >> /etc/R/Rprofile.site \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

## R packages - common stuff
RUN Rscript -e 'install.packages(c("devtools", "dplyr", "ggplot2", "reshape2"))' \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

## bioconductor packages
RUN Rscript -e 'source("http://bioconductor.org/biocLite.R"); \
                biocLite(c("DiffBind", "DESeq", "GenomicRanges", "ballgown"))' \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# R-dependent stuff
RUN apt-get update \
    && apt-get install -y \
        libblas-dev \
        liblapack-dev \
    && apt-get install -y python-rpy2
# RUN pip install cgat


#### Bioinformatics tools
### General-purpose
# sambamba
RUN wget https://github.com/lomereiter/sambamba/releases/download/v0.6.3/sambamba_v0.6.3_linux.tar.bz2 \
    && tar -xjvf sambamba_v0.6.3_linux.tar.bz2 \
    && rm sambamba_v0.6.3_linux.tar.bz2 \
    && chmod +x sambamba_v0.6.3 \
    && sudo mv sambamba_v0.6.3 /usr/local/bin/sambamba

# bamtools
RUN git clone git://github.com/pezmaster31/bamtools.git && cd bamtools \
    && mkdir build && cd build \
    && cmake .. \
    && make \
    && cd .. \
    && cp bin/bamtools* /usr/local/bin/ \
    && cd .. \
    && rm -r bamtools/

# ucsc tools
RUN rsync -aP rsync://hgdownload.cse.ucsc.edu/genome/admin/exe/linux.x86_64/ ucscTools \
    && cp ucscTools/blat/blat /usr/local/bin/ \
    && rm -rf ucscTools/blat \
    && cp ucscTools/* /usr/local/bin/
    
### Trimmers
# trimmomatic
# run as java -jar `which trimmomatic-0.33.jar`
RUN wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.33.zip \
    && unzip Trimmomatic-0.33.zip \
    && chmod +x Trimmomatic-0.33/trimmomatic-0.33.jar \
    && sudo mv Trimmomatic-0.33/trimmomatic-0.33.jar /usr/bin/
 
# skewer
RUN git clone https://github.com/relipmoc/skewer.git \
    && cd skewer \
    && make \
    && make install \
    && cd .. \
    && sudo rm -r skewer

### Aligners 
# BWA
RUN git clone https://github.com/lh3/bwa.git \
    && cd bwa; make \
    && cp bwa /usr/bin/ \
    && cd .. && rm -r -f bwa

# Bowtie
RUN wget https://github.com/BenLangmead/bowtie2/archive/v2.2.5.tar.gz \
    && tar xfz v2.2.5.tar.gz \
    && cd bowtie2-2.2.5/; make \
    && cp bowtie2* /usr/bin/ \
    && cd .. && rm -r -f bowtie2-2.2.5/ v2.2.5.tar.gz

# STAR
RUN git clone https://github.com/alexdobin/STAR.git \
    && cd STAR/source; make STAR \
    && cp STAR /usr/bin/ \
    && cd ../.. && rm -r -f STAR

# # hisat
# RUN wget http://ccb.jhu.edu/software/hisat/downloads/hisat-0.1.5-beta-Linux_x86_64.zip \
#     && unzip hisat-0.1.5-beta-Linux_x86_64.zip \
#     && cd hisat-0.1.5-beta/; make \
#     && cp hisat* /usr/local/bin \
#     && cd .. && rm -r hisat-0.1.5-beta-Linux_x86_64.zip hisat-0.1.5-beta

# TopHat
#RUN git clone https://github.com/infphilo/tophat.git \
#   &&

### Transcript quantification
# # stringTie
# RUN wget http://ccb.jhu.edu/software/stringtie/dl/stringtie-1.0.3.Linux_x86_64.tar.gz \
#     && tar xfz stringtie-1.0.3.Linux_x86_64.tar.gz \
#     && sudo cp stringtie-1.0.3.Linux_x86_64/stringtie /usr/local/bin \
#     && rm stringtie-1.0.3.Linux_x86_64.tar.gz \
#     && rm -r stringtie-1.0.3.Linux_x86_64

# kallisto
RUN wget https://github.com/pachterlab/kallisto/releases/download/v0.42.1/kallisto_linux-v0.42.1.tar.gz \
    && tar xfz kallisto_linux-v0.42.1.tar.gz \
    && sudo cp kallisto_linux-v0.42.1/kallisto /usr/bin/ \
    && rm -r -f kallisto

# salmon
RUN wget https://github.com/COMBINE-lab/salmon/archive/v0.3.2.tar.gz \
    && tar xfz v0.3.2.tar.gz \
    && cd salmon-0.3.2 \
    && cd build; cmake ..; make \
    && make install; make test \
    && cp SalmonBeta-0.3.2_ubuntu-14.04/bin/salmon /usr/bin/ \
    && rm -r SalmonBeta*

### Motif discovery
# MEME
RUN apt-get install libhtml-template-perl libxml-simple-perl libsoap-lite-perl imagemagick
    && wget 'ftp://ftp.ebi.edu.au/pub/software/MEME/4.8.1/meme_4.8.1.tar.gz' \
    && tar xf meme_4.8.1.tar.gz \
    && rm meme_4.8.1.tar.gz \
    && cd meme_4.8.1 \
    && ./configure --enable-build-libxml2 --with-url=http://meme.nbcr.net/meme
    && make -j 4
    && make test
    && make install
 
# HOMER
## weblogo dependency
# sudo mkdir /usr/local/lib/
# sudo wget http://weblogo.berkeley.edu/release/weblogo.2.8.2.tar.gz -O /usr/local/lib/weblogo.2.8.2.tar.gz
# sudo tar xfz /usr/local/lib/weblogo.2.8.2.tar.gz
## add /usr/local/lib/weblogo to PATH
## and export PERL5LIB=$PERL5LIB:/usr/local/lib/weblogo
## to /etc/environment
 
## blat, samtools and ghostscript are already in!
 
# sudo mkdir /usr/local/lib/homer
# cd /usr/local/lib/homer
# sudo wget http://homer.salk.edu/homer/configureHomer.pl
# sudo perl configureHomer.pl -install
# add 
# :/usr/local/lib/homer/bin
# to /etc/environment

### Peak Callers

# MACS
RUN pip install macs2

# spp + phantompeakqualtools
RUN apt-get install libboost-all-dev \
    && Rscript -e 'install.packages(c("caTools", "snow"))' \
    && wget https://phantompeakqualtools.googlecode.com/files/ccQualityControl.v.1.1.tar.gz \
    && tar xfz ccQualityControl.v.1.1.tar.gz \
    && R CMD INSTALL phantompeakqualtools/spp_1.10.1.tar.gz
    && chmod +x phantompeakqualtools/run_spp*
    && mv phantompeakqualtools/run_spp* /usr/bin
    && rm ccQualityControl.v.1.1.tar.gz
    && rm -r phantompeakqualtools
 

# Default action
CMD ["/bin/bash"]
