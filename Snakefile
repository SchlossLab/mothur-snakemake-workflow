import os

configfile: 'config/config.yaml'

dataset = config['dataset']
procs = config['processors']
seed = config['seed']
dist_thresh = config['distance_threshold']
silva_version = config['silva_version']

if os.path.exists("data/SRR_Acc_list.txt"):
    with open(f"data/SRR_Acc_List.txt", 'r') as file:
        sra_list = [line.strip() for line in file]


rule targets:
    input:
        'paper/paper.pdf',
        'README.md',
        'results/stability.opti_mcc.shared'


rule download_demo_data:
    output:
        zip=temp("data/raw/miseqsopdata.zip")
    params:
        outdir="data/raw/"
    shell:
        """
        wget -N -P {params.outdir} https://mothur.s3.us-east-2.amazonaws.com/wiki/miseqsopdata.zip
        unzip {output.zip} -d {params.outdir}
        mv {params.outdir}/MiSeq_SOP/*.fast* {params.outdir}
        rm -rf {params.outdir}/__MACOSX
        rm -rf {params.outdir}/MiSeq_SOP
        """


rule download_sra_data: 
    input:
        txt="data/SRR_Acc_List.txt"
    output:
        fastq=expand("data/raw/{{SRA}}_{i}.fastq", i=(1,2))
    params:
        sra="{SRA}",
        outdir="data/raw"
    shell:
        """
        #source /etc/profile.d/http_proxy.sh  # required for internet on the Great Lakes cluster
        prefetch {params.sra}
        fasterq-dump --split-files {params.sra} -O {params.outdir}
        """


rule download_silva:
    output:
        tar=temp(f"data/references/silva.seed_v{silva_version}.tgz"),
        fasta=temp(f'data/references/silva.seed_v{silva_version}.align'),
        tax=temp(f'data/references/silva.seed_v{silva_version}.tax')
    params:
        outdir="data/references/",
        silva_v=silva_version
    shell:
        """
        #source /etc/profile.d/http_proxy.sh  # required for internet on the Great Lakes cluster
        wget -N -P {params.outdir} https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.seed_v{params.silva_v}.tgz
        tar xzvf {output.tar} -C {params.outdir}
        """

rule process_silva:
    input:
        fasta=rules.download_silva.output.fasta,
        tax=rules.download_silva.output.tax
    output:
        full='data/references/silva.seed.align',
        v4='data/references/silva.v4.align'
    params:
        silva_v=silva_version,
        workdir="data/references/",
        full=f"data/references/silva.seed_v{silva_version}.pick.align",
        v4=f"data/references/silva.seed_v{silva_version}.pick.pcr.align"
    log:
        "log/mothur/get_silva.log"
    resources:
        procs=procs
    shell:
        """
        mothur "#set.logfile(name={log});
                set.dir(output={params.workdir}, input={params.workdir});
                get.lineage(fasta={input.fasta}, taxonomy={input.tax}, taxon=Bacteria);
                degap.seqs(fasta={params.full}, processors={resources.procs});
                pcr.seqs(fasta={params.full}, start=11894, end=25319, keepdots=F, processors={resources.procs})
                "
        mv {params.full} {output.full}
        mv {params.v4} {output.v4}
        """

rule download_rdp:
    output:
        tar=temp("data/references/trainset18_062020.pds.tgz"),
        fasta="data/references/rdp.fasta",
        tax="data/references/rdp.tax"
    params:
        outdir="data/references/",
        fasta="data/references/trainset18_062020.pds/trainset18_062020.pds.fasta",
        tax="data/references/trainset18_062020.pds/trainset18_062020.pds.tax",
        url='https://mothur.s3.us-east-2.amazonaws.com/wiki/trainset18_062020.pds.tgz'
    shell:
        """
        #source /etc/profile.d/http_proxy.sh  # required for internet on the Great Lakes cluster
        wget -N -P {params.outdir} {params.url}
        tar xvzf {output.tar} -C {params.outdir}
        mv {params.fasta} {output.fasta}
        mv {params.tax} {output.tax}
        rm -rf {params.outdir}/trainset18_*.pds/
        """

rule process_data:
    input:
        #fastq=expand("data/raw/{SRA}_{i}.fastq", SRA = sra_list, i = [1,2]),
        silva_v4=rules.process_silva.output.v4,
        rdp_fasta=rules.download_rdp.output.fasta,
        rdp_tax=rules.download_rdp.output.tax
    output:
        files="data/mothur/{dataset}.files",
        filter="data/processed/{dataset}.filter",
        count_table="data/processed/{dataset}.count_table",
        tax="data/processed/{dataset}.tax",
        fasta="data/processed/{dataset}.fasta"
    params:
        inputdir='data/raw/',
        workdir="data/mothur/",
        files="data/mothur/{dataset}.paired.files",
        filter="data/mothur/{dataset}.filter",
        tax="data/mothur/{dataset}.trim.contigs.good.unique.good.filter.unique.precluster.pick.rdp.wang.pick.taxonomy",
        fasta="data/mothur/{dataset}.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.fasta",
        count_table="data/mothur/{dataset}.trim.contigs.good.unique.good.filter.unique.precluster.denovo.uchime.pick.pick.count_table",
        trim_contigs='data/mothur/{dataset}.trim.contigs.fasta',
        contigs_groups='data/mothur/{dataset}.contigs.groups'
    log:
        "log/mothur/process_data_{dataset}.log"
    resources:
        procs=procs
    shell:
        """
        mothur '#set.logfile(name={log});
            set.dir(input={params.inputdir}, output={params.workdir});
            make.file(inputdir={params.inputdir}, type=fastq, prefix={wildcards.dataset});
            rename.file(input={params.files}, new={output.files});
            make.contigs(inputdir={params.inputdir}, file={output.files}, processors={resources.procs});
            set.dir(input={params.workdir}, output={params.workdir});
            screen.seqs(fasta={params.trim_contigs}, group={params.contigs_groups}, maxambig=0, maxlength=275, maxhomop=8);
            unique.seqs();
            count.seqs(name=current, group=current);
            align.seqs(fasta=current, reference={input.silva_v4}, processors={resources.procs});
            screen.seqs(fasta=current, count=current, start=1968, end=11550);
            filter.seqs(fasta=current, vertical=T, trump=.);
            unique.seqs(fasta=current, count=current);
            pre.cluster(fasta=current, count=current, diffs=2);
            chimera.uchime(fasta=current, count=current, dereplicate=T);
            remove.seqs(fasta=current, accnos=current);
            classify.seqs(fasta=current, count=current, reference={input.rdp_fasta}, taxonomy={input.rdp_tax}, cutoff=80);
            remove.lineage(fasta=current, count=current, taxonomy=current, taxon=Chloroplast-Mitochondria-unknown-Archaea-Eukaryota) '
        mv {params.filter} {output.filter}
        mv {params.tax} {output.tax}
        mv {params.fasta} {output.fasta}
        mv {params.count_table} {output.count_table}
        
        """

rule calc_dists:
    input:
        fasta=rules.process_data.output.fasta
    output:
        column="data/processed/{dataset}.dist"
    params:
        outdir="data/processed/",
        cutoff=dist_thresh
    log:
        "log/mothur/calc_dists_{dataset}.log"
    resources:
        procs=procs
    shell:
        """
        mothur '#set.logfile(name={log}); set.dir(output={params.outdir});
            dist.seqs(fasta={input.fasta}, cutoff={params.cutoff}, processors={resources.procs}) '
        """

rule cluster_OTUs:
    input:
        dist=rules.calc_dists.output.column,
        count_table=rules.process_data.output.count_table
    output:
        list="results/{dataset}.opti_mcc.list",
        sensspec='results/{dataset}.opti_mcc.sensspec',
        steps='results/{dataset}.opti_mcc.steps'
    params:
        outdir="results/",
        cutoff=dist_thresh,
        seed=seed,
        procs=procs
    log:
        "log/mothur/cluster_{dataset}.log"
    benchmark:
        "benchmarks/mothur/cluster_{dataset}.txt"
    resources:
        procs=procs
    shell:
        """
        mothur '#set.logfile(name={log}); set.dir(output={params.outdir});
            set.seed(seed={params.seed});
            set.current(processors={resources.procs});
            cluster(column={input.dist}, count={input.count_table}, cutoff={params.cutoff}) '
        """

rule get_shared:
    input:
        list=rules.cluster_OTUs.output.list,
        count_table=rules.process_data.output.count_table,
        tax=rules.process_data.output.tax
    output:
        shared='results/{dataset}.opti_mcc.shared'
    params:
        outdir='results/',
        label=dist_thresh
    log:
        "log/mothur/get_shared_{dataset}.log"
    shell:
        """
        mothur '#set.logfile(name={log}); set.dir(output={params.outdir});
            make.shared(list={input.list}, count={input.count_table}, label={params.label});
            classify.otu(list=current, count=current, taxonomy={input.tax}, label={params.label}) '
        """

rule render_paper:
    input:
        Rmd="paper/paper.Rmd",
        R="code/R/render-rmd.R"
    output:
        pdf="paper/paper.pdf",
        md="paper/paper.md"
    script:
        "code/R/render-rmd.R"
        
rule render_readme:
    input:
        Rmd="README.Rmd",
        R="code/R/render-rmd.R"
    output:
        md="README.md"
    script:
        "code/R/render-rmd.R"