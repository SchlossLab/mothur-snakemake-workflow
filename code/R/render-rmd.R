rmarkdown::render(
  here::here(snakemake@input[["Rmd"]]),
  output_format = "all"
)
