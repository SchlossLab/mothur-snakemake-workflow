#!/bin/bash

# demo dataset from original miseq sop
snakemake -n --rulegraph | dot -T png > figures/rulegraph_demo.png
snakemake -n --dag | dot -T png > figures/dag_demo.png

# crc dataset from Hannigan paper
snakemake -n --configfile config/crc/crc.yaml --rulegraph | dot -T png > figures/rulegraph_crc.png
snakemake -n --configfile config/crc/crc.yaml --dag | dot -T png > figures/dag_crc.png   
