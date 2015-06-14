#!/bin/bash

if [ -f ~/.profile ]; then
    source ~/.profile
fi

if [[ -s /cm ]]; then
    module load slurm
    module load java/jdk/1.7.0_51
    module load FastQC/0.11.2
    module load trimmomatic/0.32
    module load bowtie/2.2.4
    module load tophat/2.0.13
    module load samtools
    module load bamtools/bamtools
    module load bedtools
    module load boost/1.57
    module load gcc/4.8.2
    module load openmpi/gcc/64/1.8.1
fi
