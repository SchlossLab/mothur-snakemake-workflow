#!/bin/bash
snakemake -n --rulegraph | dot -T png > figures/rulegraph.png
snakemake -n --dag | dot -T png > figures/dag.png
