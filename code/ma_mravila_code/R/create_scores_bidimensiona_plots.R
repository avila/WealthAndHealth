
# libs --------------------------------------------------------------------------------------------------


library(ggplot2)
library(dplyr)

# params ------------------------------------------------------------------------------------------------

list_of_params <- list(
  sample_frac = 1/4
)


# data --------------------------------------------------------------------------------------------------


dta_health_factor_scores <- haven::read_dta("data/intermediary/health_factor_scores.dta")
if(interactive()) glimpse(dta_health_factor_scores)
df_sample_fs <- dta_health_factor_scores |> sample_frac(size = list_of_params$sample_frac)


# funs --------------------------------------------------------------------------------------------------

ggsave2 <- function(filename, plot=last_plot(), device="pdf", ...) {
  ggsave(
    filename, plot,
    device=device,
    dpi = 600,
    width = 5,
    height = 5,
    ...)
}

label_x <- function(p) {
  b <- ggplot_build(p)
  x <- b$plot$data[[b$plot$labels$x]]

  p + scale_x_continuous(
    attributes(x)$label,
    breaks = attributes(x)$labels,
    labels = names(attributes(x)$labels)
  )
}

my.theme <- theme_light() + theme(aspect.ratio = 1) + theme(legend.position = "none")

my.lab <- labs(x = "pcs", y = "mcs")
my.x.coord <- xlim(0, 80)
my.y.coord <- ylim(0, 80)


# plots -------------------------------------------------------------------------------------------------

## p_def ----

(p_def <- ggplot(
  df_sample_fs, mapping = aes(x=pcs_def, y=mcs_def)) +
   ggrastr::geom_point_rast(color = alpha("blue", 20/100), size = 1/10) +
   stat_density_2d(aes(color = ..level..), bins=10, adjust = 5/4, linewidth = 1) +
   my.x.coord + my.y.coord + my.lab +
   scale_color_viridis_c() +
   my.theme
)

(p_def_marg <- ggExtra::ggMarginal(p_def, type="densigram", size=4, fill="blue", alpha=.3))
ggsave2("./output/figures/factor/fig_bidim_marg_def.pdf", plot = p_def_marg,
        device = "pdf")


## p_main ----

(p_main <- ggplot(
  df_sample_fs, mapping = aes(x=pcs_main, y=mcs_main)) +
      ggrastr::geom_point_rast(color = alpha("blue", 20/100), size = 1/10) +
   stat_density_2d(aes(color = ..level..), bins=10, adjust = 5/4, linewidth = 1) +
   my.x.coord + my.y.coord + my.lab +
   scale_color_viridis_c() +
   my.theme
 )

(p_main_marg <- ggExtra::ggMarginal(p_main, type="densigram",size=4, fill="blue", alpha=.3))
ggsave2("./output/figures/factor/fig_bidim_marg_main.pdf", plot = p_main_marg)


## p_obli ----

(p_obli <- ggplot(
  df_sample_fs, mapping = aes(x=pcs_obli, y=mcs_obli)) +
      ggrastr::geom_point_rast(color = alpha("blue", 20/100), size = 1/10) +
   stat_density_2d(aes(color = ..level..), bins=10, adjust = 5/4, linewidth = 1) +
   my.x.coord + my.y.coord + my.lab +
   scale_color_viridis_c() +
   my.theme
 )
(p_obli_marg <- ggExtra::ggMarginal(p_obli, type="densigram",size=4, fill="blue", alpha=.3))
ggsave2("./output/figures/factor/fig_bidim_marg_obli.pdf", plot = p_obli_marg)

## p_ortho ----

(p_ortho <- ggplot(
  df_sample_fs, mapping = aes(x=pcs_ortho, y=mcs_ortho)) +
      ggrastr::geom_point_rast(color = alpha("blue", 20/100), size = 1/10) +
   stat_density_2d(aes(color = ..level..), bins=10, adjust = 5/4, linewidth = 1) +
   my.x.coord + my.y.coord + my.lab +
   scale_color_viridis_c() +
   my.theme
 )
(p_ortho_marg <- ggExtra::ggMarginal(p_ortho, type="densigram",size=4, fill="blue", alpha=.3))
ggsave2("./output/figures/factor/fig_bidim_marg_ortho.pdf", plot = p_ortho_marg)


## p_nort ----

(p_nort <- ggplot(
  df_sample_fs, mapping = aes(x=pcs_nort, y=mcs_nort)) +
   ggrastr::geom_point_rast(color = alpha("blue", 20/100), size = 1/10) +
   stat_density_2d(aes(color = ..level..), bins=10, adjust = 5/4, linewidth = 1) +
   my.x.coord + my.y.coord + my.lab +
   scale_color_viridis_c() +
   my.theme
 )
(p_nort_marg <- ggExtra::ggMarginal(p_nort, type="densigram",size=4, fill="blue", alpha=.3))
ggsave2("./output/figures/factor/fig_bidim_marg_nort.pdf", plot = p_nort_marg)

