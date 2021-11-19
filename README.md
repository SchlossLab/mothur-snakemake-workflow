
<!-- README.md is generated from README.Rmd. Please edit that file -->

# MiSeq-SOP-demo

<!-- badges: start -->

[![build](https://github.com/SchlossLab/MiSeq-SOP-demo/actions/workflows/build.yml/badge.svg)](https://github.com/SchlossLab/MiSeq-SOP-demo/actions/workflows/build.yml)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/SchlossLab/MiSeq-SOP-demo/blob/main/LICENSE.md)
<!-- badges: end -->

## Dependencies

-   mothur
-   R
-   snakemake

R packages:

-   here
-   schtools
-   tidyverse

## Re-using this template

If you re-use this template for a real project, you’ll need to fill in
some information in the following files:

-   `LICENSE.md`
    -   `YEAR`
    -   `AUTHORS`
    -   `FIRST_AUTHOR_LASTNAME`
    -   `GITHUB_URL`
-   `MiSeq-SOP-demo.Rproj` - rename this file to match your project.
-   `paper/head.tex`
    -   `RUNNING TITLE`
    -   `FIRST AUTHOR LASTNAME`
    -   `AUTHORS AND AFFILIATIONS`
-   `paper/paper.Rmd`
    -   `TITLE`
    -   Write the actual text of your paper 🤓
-   `paper/references.bib`
    -   Export your references from Zotero (or other reference manager)
        to this file.
-   `README.Rmd`
    -   `MiSeq-SOP-demo` - your project slug.
    -   Change the text as you see fit to explain your project.

## Directory Structure

    [01;34m.[00m
    ├── LICENSE.md
    ├── MiSeq-SOP-demo.Rproj
    ├── README.Rmd
    ├── README.md
    ├── Snakefile
    ├── [01;34mbenchmarks[00m
    │   └── [01;34mmothur[00m
    ├── [01;34mcode[00m
    │   ├── [01;34mR[00m
    │   ├── get_error.batch
    │   ├── get_good_seqs.batch
    │   ├── get_shared_otus.batch
    │   └── [01;34mtests[00m
    ├── [01;34mconfig[00m
    │   ├── cluster.yaml
    │   ├── config.yaml
    │   └── [01;34mslurm[00m
    ├── [01;34mdata[00m
    │   ├── README.md
    │   ├── [01;34mmothur[00m
    │   ├── mouse.dpw.metadata
    │   ├── mouse.time.design
    │   ├── [01;34mprocessed[00m
    │   ├── [01;34mraw[00m
    │   ├── [01;34mreferences[00m
    │   └── stability.files
    ├── [01;34mexploratory[00m
    │   └── README.md
    ├── [01;34mfigures[00m
    ├── [01;34mlog[00m
    │   ├── [01;34mhpc[00m
    │   └── [01;34mmothur[00m
    ├── [01;34mpaper[00m
    │   ├── head.tex
    │   ├── mbio.csl
    │   ├── paper.Rmd
    │   ├── paper.log
    │   ├── paper.md
    │   ├── paper.pdf
    │   ├── preamble.tex
    │   └── references.bib
    └── [01;34mresults[00m
        ├── current_files.summary
        ├── stability.opti_mcc.0.03.cons.tax.summary
        ├── stability.opti_mcc.0.03.cons.taxonomy
        ├── stability.opti_mcc.list
        ├── stability.opti_mcc.sensspec
        ├── stability.opti_mcc.shared
        └── stability.opti_mcc.steps

    19 directories, 30 files
