schtools::log_snakemake()
library(schtools)
library(tidyverse)

div_dat <- read_tsv(snakemake@input[['tsv']])
div_plot <- div_dat %>%
    filter(method == 'ave') %>%
    select(group, shannon, invsimpson) %>%
    pivot_longer(-group, names_to = 'diversity_metric', values_to = 'value') %>%
    ggplot(aes(x = diversity_metric, y = value)) +
    facet_wrap(~diversity_metric, scales = 'free') +
    geom_boxplot() +
    geom_jitter() +
    labs(x = "", y = "") +
    theme_sovacool()
ggsave(snakemake@output[['alpha']],
       plot = div_plot, device = 'pdf',
       width = 6, height = 5, units = 'in')
