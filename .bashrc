if [ -f ~/.profile ]; then
    source ~/.profile
fi

if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# This makes sure it's only executed in the CeMM cluster
if [[ -s /cm ]]; then
    module load python/2.7.12
    module load slurm
    module load java/jdk/1.8.0
    module load FastQC
    module load trimmomatic/0.32
    module load htslib
    module load samtools
    module load bamtools/bamtools
    module load bedtools/2.20.1
    module load gcc/4.8.2
    module load boost/1.55
    module load bowtie/2.2.4
    module load tophat/2.0.14
    module load meme
    # module load openmpi/gcc/64/1.8.1
    module load openmpi/1.10.0
    module load R/3.2.1
    module load preseq

    export PATH=$PATH:/home/arendeiro/.local/bin
    export PYTHONPATH=/home/arendeiro/.local/lib/python2.7/site-packages

    # tmpdir
    export TMPDIR=/scratch/users/arendeiro/tmp/
    export TMP_DIR=/scratch/users/arendeiro/tmp/

    cancelAllJobs () {
        for J in `sq | unexpand -t 4 | cut -f 3`; do scancel $J; done
    }

    scancelall () {
        for J in `qstat | grep are | unexpand -t 4 | cut -f 1 | tail -n +2`; do scancel $J; done
    }
fi
