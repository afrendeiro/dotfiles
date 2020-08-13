if [ -f ~/.profile ]; then
    source ~/.ssh/profile.sh
fi

if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# Stuff inside is only executed in the CeMM cluster
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

    loadpython3 () {
        module unload python
        module unload gcc
        module load gcc/4.8.2
        module load python/3.6.1
        # this is annoying but I must regress to R/3.3.2 because of gcc version :(
	    module unload R
	    module load R/3.3.2
    }

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
	loadpython3
        srun -p develop --mem 80000 -c 8 --time 08:00:00 --pty --x11 ipython3
    }
    jobd () {
	loadpython3
        srun -p develop --mem 80000 -c 8 --time 08:00:00 --pty --x11 ipython3
    }
    jobs () {
	loadpython3
        srun -p shortq --mem 80000 -c 8 --time 08:00:00 --pty --x11 ipython3
    }
    jobm () {
	loadpython3
        srun -p mediumq --mem 80000 -c 8 --time 1-08:00:00 --pty --x11 ipython3
    }
    jobl () {
	loadpython3
        srun -p longq --mem 80000 -c 8 --time 2-08:00:00 --pty --x11 ipython3
    }

    countjobsperuser () {
        qstat | tail -n +3 | sed 's/ /\t/g' | sed -e "s/\t\+/\t/g" | cut -f 3 | sort | uniq -c
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

    # Looperenv
    export LOOPERENV=/home/$USER/workspace/looperenv/cemm.yaml

    # RNA-seq pipelines
    export PICARD=/cm/shared/apps/picard-tools/2.9.0/picard.jar
    export TRIMMOMATIC_EPIGNOME=/cm/shared/apps/trimmomatic/0.32/trimmomatic-0.32-epignome.jar

fi

PYTHONIOENCODING="UTF-8"
