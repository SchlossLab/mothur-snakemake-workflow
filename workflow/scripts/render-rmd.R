schtools::log_snakemake()
rmarkdown::render(
  here::here(snakemake@input[["Rmd"]]),
  output_format = "all"
)
