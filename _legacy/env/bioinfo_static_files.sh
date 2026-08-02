#!/usr/env bash

# Get static files (genomes, annotations, etc...)

# Genome-related
for GENOME in hg19 mm10 danRer10
do
    ### Genome
    mkdir -p resources/${GENOME}
    cd resources/${GENOME}
    wget http://hgdownload.cse.ucsc.edu/goldenPath/${GENOME}/bigZips/${GENOME}.2bit
    twoBitToFa ${GENOME}.2bit ${GENOME}.fa
    samtools faidx ${GENOME}.fa
    cd ../..

    ### Bowtie2 genome index
    mkdir -p resources/${GENOME}/forBowtie2
    cd resources/${GENOME}/forBowtie2
    wget ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/${GENOME}.zip
    unzip ${GENOME}.zip
    cd ../../..

    ### Chromosome sizes
    cd resources
    mysql --user=genome --host=genome-mysql.cse.ucsc.edu -A -e \
    "select chrom, size from ${GENOME}.chromInfo" | tail -n +2 > ${GENOME}/${GENOME}.chrom-sizes.tsv
    cd ..

    ### Hisat index
    mkdir -p resources/${GENOME}/forHisat
    cd resources/${GENOME}/forHisat
    wget ftp://ftp.ccb.jhu.edu/pub/data/hisat_indexes/hg19_hisat.tar.gz
    tar xfz hg19_hisat.tar.gz
    cd ../../..

    ### Mappability regions
    if [ $GENOME == hg19 ]
    then
        mkdir -p resources/${GENOME}/mappability
        cd resources/${GENOME}/mappability

        wget http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeMapability/wgEncodeCrgMapabilityAlign36mer.bigWig
        wget http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeMapability/wgEncodeCrgMapabilityAlign50mer.bigWig

        bigWigToBedgraph wgEncodeCrgMapabilityAlign36mer.bigWig wgEncodeCrgMapabilityAlign36mer.bedgraph
        bigWigToBedgraph wgEncodeCrgMapabilityAlign50mer.bigWig wgEncodeCrgMapabilityAlign50mer.bedgraph

        awk '$4 == 1 {OFS="\t"; print $1, $2, $3}' wgEncodeCrgMapabilityAlign36mer.bedgraph > wgEncodeCrgMapabilityAlign36mer.bed
        awk '$4 == 1 {OFS="\t"; print $1, $2, $3}' wgEncodeCrgMapabilityAlign50mer.bedgraph > wgEncodeCrgMapabilityAlign50mer.bed

        cd ../../..
    fi
done

# ERCCs
mkdir -p resources/ercc
cd resources/ercc

wget https://tools.lifetechnologies.com/content/sfs/manuals/cms_095047.txt
wget https://tools.lifetechnologies.com/content/sfs/manuals/cms_095046.txt

# get Fasta
# remove poly-As; version *with* polyA is now called ERCC92_polyA

# Make bowtie2 index
mkdir indexed_bowtie2
cd indexed_bowtie2
bowtie2-build -f ../ERCC92.fa ERCC92
bowtie2-build -f ../ERCC92_polyA.fa ERCC92_polyA
cd ..

#

cd ../..



