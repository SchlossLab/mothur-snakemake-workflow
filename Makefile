REFS = data/references/
FIGS = results/figures
TABLES = results/tables
PROC = data/process
FINAL = submission/

# utility function to print various variables. For example, running the
# following at the command line:
#
#	make print-BAM
#
# will generate:
#	BAM=data/raw_june/V1V3_0001.bam data/raw_june/V1V3_0002.bam ...
print-%:
	@echo '$*=$($*)'


################################################################################
#
# Part 1: Get the references
#
# We will need several reference files to complete the analyses including the
# SILVA reference alignment and RDP reference taxonomy. Note that this code
# assumes that mothur is in your PATH. If not (e.g. it's in code/mothur/, you
# will need to replace `mothur` with `code/mothur/mothur` throughout the
# following code.
#
################################################################################

# We want the latest greatest reference alignment and the SILVA reference
# alignment is the best reference alignment on the market. This version is from
# 138.1 and described at https://mothur.org/blog/2021/SILVA-v138_1-reference-files/

$(REFS)silva.bacteria.align :
	wget -N -P $(REFS) https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.nr_v138_1.tgz; \
	tar xvzf $(REFS)silva.nr_v138_1.tgz -C $(REFS);
	mothur "#get.lineage(fasta=$(REFS)silva.nr_v138_1.align, taxonomy=$(REFS)silva.nr_v138_1.tax, taxon=Bacteria)";
	mv $(REFS)silva.nr_v138_1.pick.align $(REFS)silva.bacteria.align; \
	rm $(REFS)silva.nr_v138_1.*
	git checkout -- $(REFS)README.md


$(REFS)silva.v4.align : $(REFS)silva.bacteria.align
	mothur "#pcr.seqs(fasta=$(REFS)/silva.bacteria.align, start=11894, end=25319, keepdots=F, processors=8)"
	mv $(REFS)silva.bacteria.pcr.align $(REFS)silva.v4.align


# Next, we want the RDP reference taxonomy. The current version is v18 and we
# use a "special" pds version of the database files, which are described at
# https://mothur.org/blog/2021/RDP-v18-reference-files/

$(REFS)trainset18_062020.pds.tax $(REFS)trainset18_062020.pds.fasta :
	wget -N -P $(REFS) https://mothur.s3.us-east-2.amazonaws.com/wiki/trainset18_062020.pds.tgz; \
	tar xvzf $(REFS)trainset18_062020.pds.tgz -C $(REFS);\
	mv $(REFS)trainset18_062020.pds/trainset18_062020.* $(REFS);\
	rm -rf $(REFS)trainset18_062020.pds


# We'd like to get the Mock community reference sequences for assessing error
# rates

$(REFS)HMP_MOCK.fasta :
	wget --no-check-certificate -N -P $(REFS) https://raw.githubusercontent.com/SchlossLab/Kozich_MiSeqSOP_AEM_2013/master/data/references/HMP_MOCK.fasta

#align the mock community reference sequeces
$(REFS)HMP_MOCK.v4.fasta : $(REFS)HMP_MOCK.fasta $(REFS)silva.v4.align
	mothur "#align.seqs(fasta=$(REFS)HMP_MOCK.fasta, reference=$(REFS)silva.v4.align);\
			degap.seqs()";\
	mv $(REFS)HMP_MOCK.ng.fasta $(REFS)HMP_MOCK.v4.fasta;\
	rm -f $(REFS)HMP_MOCK.align;\
	rm -f $(REFS)HMP_MOCK.align.report;\
	rm -f $(REFS)HMP_MOCK.flip.accnos


################################################################################
#
# Part 2: Get and run data through mothur
#
#	Process fastq data through the generation of files that will be used in the
# overall analysis.
#
################################################################################

# Change stability to the * part of your *.files file that lives in data/raw/
BASIC_STEM = data/mothur/stability.trim.contigs.good.unique.good.filter.unique.precluster

# The following code will download the stability data that are used in the MiSeq
# SOP. The data will be deposited into data/raw. Be sure to remove these lines (and files if you've run this code!) for when you run your own data.

data/raw/Mock_S280_L001_R2_001.fastq :
	wget --no-check-certificate -N https://mothur.s3.us-east-2.amazonaws.com/wiki/miseqsopdata.zip
	unzip miseqsopdata.zip
	mv MiSeq_SOP/*.fastq data/raw
	rm -rf __MACOSX MiSeq_SOP miseqsopdata.zip


# here we go from the raw fastq files and the files file to generate a fasta,
# taxonomy, and count_table file that has had the chimeras removed as well as
# any non bacterial sequences.

# Edit code/get_good_seqs.batch to include the proper name of your *files file
$(BASIC_STEM).denovo.vsearch.pick.pick.count_table $(BASIC_STEM).pick.pick.fasta $(BASIC_STEM).pick.pds.wang.pick.taxonomy : code/get_good_seqs.batch\
					data/references/silva.v4.align\
					data/references/trainset18_062020.pds.fasta\
					data/references/trainset18_062020.pds.tax
	mothur code/get_good_seqs.batch
	rm data/mothur/*.map



# here we go from the good sequences and generate a shared file and a
# cons.taxonomy file based on OTU data

# Edit code/get_shared_otus.batch to include the proper root name of your files file
# Edit code/get_shared_otus.batch to include the proper group names to remove

$(BASIC_STEM).pick.pick.pick.opti_mcc.unique_list.shared $(BASIC_STEM).pick.pick.pick.opti_mcc.unique_list.0.03.cons.taxonomy : code/get_shared_otus.batch\
					$(BASIC_STEM).denovo.vsearch.pick.pick.count_table\
					$(BASIC_STEM).pick.pick.fasta\
					$(BASIC_STEM).pick.pds.wang.pick.taxonomy
	mothur code/get_shared_otus.batch
	rm $(BASIC_STEM).denovo.vsearch.pick.pick.pick.count_table
	rm $(BASIC_STEM).pick.pick.pick.fasta
	rm $(BASIC_STEM).pick.pds.wang.pick.pick.taxonomy



# Edit code/get_error.batch to include the proper root name of your files file
# Edit code/get_error.batch to include the proper group names for your mocks

$(BASIC_STEM).pick.pick.pick.error.summary : code/get_error.batch\
					$(BASIC_STEM).denovo.vsearch.pick.pick.count_table\
					$(BASIC_STEM).pick.pick.fasta\
					$(REFS)/HMP_MOCK.v4.fasta
	mothur code/get_error.batch



################################################################################
#
# Part 3: Figure and table generation
#
#	Run scripts to generate figures and tables
#
################################################################################



################################################################################
#
# Part 4: Pull it all together
#
# Render the manuscript
#
################################################################################


$(FINAL)/manuscript.% : 			\ #include data files that are needed for paper don't leave this line with a : \
						$(FINAL)/mbio.csl\
						$(FINAL)/references.bib\
						$(FINAL)/manuscript.Rmd
	R -e 'render("$(FINAL)/manuscript.Rmd", clean=FALSE)'
	mv $(FINAL)/manuscript.knit.md submission/manuscript.md
	rm $(FINAL)/manuscript.utf8.md


write.paper : $(TABLES)/table_1.pdf $(TABLES)/table_2.pdf\ #customize to include
				$(FIGS)/figure_1.pdf $(FIGS)/figure_2.pdf\	# appropriate tables and
				$(FIGS)/figure_3.pdf $(FIGS)/figure_4.pdf\	# figures
				$(FINAL)/manuscript.Rmd $(FINAL)/manuscript.md\
				$(FINAL)/manuscript.tex $(FINAL)/manuscript.pdf\
				$(FINAL)/manuscript.docx
