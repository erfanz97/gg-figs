# <Project name> -- manuscript figures
# Run from the project folder:  Rscript R/make_figures.R
# Layout: R/ (this script + gg_pub.R), data/ (tidy CSVs), figures/{pdf,tiff,png}/

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
project_dir <- if (length(script_argument) > 0) {
  dirname(dirname(normalizePath(sub("^--file=", "", script_argument[1]), winslash = "/")))
} else {
  normalizePath(getwd(), winslash = "/")
}
source(file.path(project_dir, "R", "gg_pub.R"))
# pub_font("Arial")                      # uncomment if the journal wants sans-serif
data_dir <- file.path(project_dir, "data")
fig_dir <- file.path(project_dir, "figures")
JOURNAL <- "default"                     # elsevier, springer, nature, cell, acs, wiley, plos, science, mdpi

# ---- shared levels and palettes: define once, reuse in every figure ----------
group_levels <- c("Control", "Treatment A", "Treatment B")
group_colors <- pub_palette(group_levels)
group_shapes <- pub_shapes(group_levels)

# ---- Figure 1: <what it shows> ------------------------------------------------
fig1_data <- read_csv(file.path(data_dir, "fig1.csv"), show_col_types = FALSE) %>%
  mutate(group = factor(group, levels = group_levels))

p1 <- ggplot(fig1_data, aes(group, value, color = group, shape = group)) +
  layers_points_mean(error = "sd") +
  scale_color_manual(values = group_colors) +
  scale_shape_manual(values = group_shapes) +
  labs(x = NULL, y = "Response (unit)") +
  theme_pub(legend = "none")
save_pub(p1, "Figure_01_short_name", width = "single", height = 70, journal = JOURNAL, dir = fig_dir)

# ---- manifest -------------------------------------------------------------------
manifest <- tibble::tribble(
  ~figure, ~file_stem,              ~plot_type,                ~statistics,
  "1",     "Figure_01_short_name",  "points + mean +/- SD",    "none"
)
write_csv(manifest, file.path(fig_dir, "figure_manifest.csv"))
