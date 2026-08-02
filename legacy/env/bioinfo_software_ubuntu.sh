
# python
sudo apt-get install -y python3-dev python3-pip python3-virtualenv

# general bioinfo
sudo apt-get install -y bedtools samtools bedtools picard-tools fastqc ghostscript


# general python data science stack
# since neither pip or easy_install can install system-level dependencies, let's use apt-get
sudo apt-get install -y libatlas-base-dev libfreetype6-dev
sudo apt-get install -y cython3
python3 -m pip install numpy pandas seaborn ipython

# python bioinfo
sudo apt-get install -y libmysqlclient-dev libpq-dev
sudo apt-get install -y python3-biopython 
python3 -m pip install pysam htseq pybedtools macs2


# R
sudo apt-get install -y r-base r-base-dev
python3 -m pip install rpy2

# R packages (install for everyone)
sudo R
install.packages("ggplot2") # bunch of stuff more

# R bioconductor
source("http://bioconductor.org/biocLite.R")
biocLite(c("DiffBind", "DESeq", "GenomicRanges", "ballgown"))
quit(save="no")

# EC2 <--> S3 data transfer
sudo apt-get install s3cmd
s3cmd --configure

# Libraries installed from source
# globally

# install to: $HOME/.local/bin/
# add to .bashrc or .bash_profile:
# PATH=$PATH:$HOME/.local/bin
# source .bashrc

# sambamba
V=0.6.8
wget https://github.com/biod/sambamba/releases/download/v${V}/sambamba-${V}-linux-static.gz
extract sambamba-${V}-linux-static.gz
chmod +x sambamba*
mv sambamba* $HOME/.local/bin/sambamba

# bamtools
git clone git://github.com/pezmaster31/bamtools.git
cd bamtools
mkdir build
cd build
cmake ..
make
cd ..
sudo mv bin/bamtools-2.3.0 $HOME/.local/bin/bamtools
cd ..
rm -r bamtools

# trimmomatic
wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.33.zip
unzip Trimmomatic-0.33.zip
chmod +x Trimmomatic-0.33/trimmomatic-0.33.jar
sudo mv Trimmomatic-0.33/trimmomatic-0.33.jar /usr/bin/
# run as java -jar `which trimmomatic-0.33.jar`

# skewer
git clone https://github.com/relipmoc/skewer.git
cd skewer
make
sudo make install
cd ..
sudo rm -r skewer

# hisat
wget http://ccb.jhu.edu/software/hisat/downloads/hisat-0.1.5-beta-Linux_x86_64.zip
unzip hisat-0.1.5-beta-Linux_x86_64.zip
sudo cp hisat-0.1.5-beta/hisat* $HOME/.local/bin
rm hisat-0.1.5-beta-Linux_x86_64.zip
rm -r hisat-0.1.5-beta/

# stringTie
wget http://ccb.jhu.edu/software/stringtie/dl/stringtie-1.0.3.Linux_x86_64.tar.gz
tar xfz stringtie-1.0.3.Linux_x86_64.tar.gz
sudo cp stringtie-1.0.3.Linux_x86_64/stringtie $HOME/.local/bin
rm stringtie-1.0.3.Linux_x86_64.tar.gz
rm -r stringtie-1.0.3.Linux_x86_64

# ucsc tools
rsync -aP rsync://hgdownload.cse.ucsc.edu/genome/admin/exe/linux.x86_64/ ucscTools
sudo cp ucscTools/* $HOME/.local/bin
sudo cp ucscTools/blat/blat $HOME/.local/bin

# MEME
sudo apt-get install libhtml-template-perl libxml-simple-perl libsoap-lite-perl imagemagick

wget http://meme-suite.org/meme-software/4.10.1/meme_4.10.1_3.tar.gz
tar xf meme_4.10.1_3.tar.gz
cd meme_4.10.1/
sudo mkdir -p $HOME/.local/meme
./configure --prefix=$HOME/.local/meme --enable-build-libxml2 --with-url=http://meme.nbcr.net/meme
make -j 4
make test
sudo make install

# homer
## weblogo dependency
sudo mkdir $HOME/.local/lib/
sudo wget http://weblogo.berkeley.edu/release/weblogo.2.8.2.tar.gz -O $HOME/.local/lib/weblogo.2.8.2.tar.gz
sudo tar xfz $HOME/.local/lib/weblogo.2.8.2.tar.gz
## add $HOME/.local/lib/weblogo to PATH
## and export PERL5LIB=$PERL5LIB:$HOME/.local/lib/weblogo
## to /etc/environment

## blat, samtools and ghostscript are already in!

sudo mkdir $HOME/.local/lib/homer
cd $HOME/.local/lib/homer
sudo wget http://homer.salk.edu/homer/configureHomer.pl
sudo perl configureHomer.pl -install
# add 
# :$HOME/.local/lib/homer/bin
# to /etc/environment

# spp + phantompeakqualtools
sudo apt-get install libboost-all-dev
sudo R
install.packages(c("caTools", "snow"))
quit(save="no")

wget https://phantompeakqualtools.googlecode.com/files/ccQualityControl.v.1.1.tar.gz
tar xfz ccQualityControl.v.1.1.tar.gz
sudo R CMD INSTALL phantompeakqualtools/spp_1.10.1.tar.gz
# add #! /usr/bin/env R to first line of phantompeakqualtools/run_spp*
chmod +x phantompeakqualtools/run_spp*
sudo mv phantompeakqualtools/run_spp* $HOME/.local/bin
rm ccQualityControl.v.1.1.tar.gz
rm -r phantompeakqualtools

# run with Rscript `which run_spp.R`
