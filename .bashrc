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

    # SLURM CONTROL
    ## job cancelation
    scancelall () {
        readarray -t JOBS < <(qstat | grep are | unexpand -t 4 | cut -f 1 | tail -n +2)
        function join_by { local IFS="$1"; shift; echo "$*"; }
        JOBS_STR=`join_by , "${JOBS[@]}"`
        scancel $JOBS_STR
    }
    scancelQ () {
        readarray -t JOBS < <(qstat | grep are | grep Q | unexpand -t 4 | cut -f 1 | tail -n +2)
        function join_by { local IFS="$1"; shift; echo "$*"; }
        JOBS_STR=`join_by , "${JOBS[@]}"`
        scancel $JOBS_STR   
    }
    scancelR () {
        readarray -t JOBS < <(qstat | grep are | grep R | unexpand -t 4 | cut -f 1 | tail -n +2)
        function join_by { local IFS="$1"; shift; echo "$*"; }
        JOBS_STR=`join_by , "${JOBS[@]}"`
        scancel $JOBS_STR
    }

    ## quick job allocation
    job () {
        srun -p develop --mem 80000 -c 8 --time 08:00:00 --pty --x11 ipython
    }
    jobd () {
        srun -p develop --mem 80000 -c 8 --time 08:00:00 --pty --x11 ipython
    }
    jobs () {
        srun -p shortq --mem 80000 -c 8 --time 08:00:00 --pty --x11 ipython
    }
    jobl () {
        srun -p longq --mem 80000 -c 8 --time 08:00:00 --pty --x11 ipython
    }

    # Change looper jobs from queue
    changeLooperQueue () {
        find submission/*sub -exec sed -i 's/5-12:00:00/7:00:00/g' {} \;
        find submission/*sub -exec sed -i 's/4-00:00:00/7:00:00/g' {} \;
        find submission/*sub -exec sed -i 's/longq/shortq/g' {} \;
        find submission/*sub -exec cat  {} \; | grep "time="
        find submission/*sub -exec cat  {} \; | grep "partition"
        find submission/*sub -exec sbatch {} \;
    }

fi
