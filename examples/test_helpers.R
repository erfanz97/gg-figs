# Assertion tests for assets/gg_pub.R. Run from the skill folder:
#   Rscript examples/test_helpers.R

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
skill_dir <- if (length(script_argument) > 0) {
  dirname(dirname(normalizePath(sub("^--file=", "", script_argument[1]), winslash = "/")))
} else {
  normalizePath(".", winslash = "/")
}
source(file.path(skill_dir, "assets", "gg_pub.R"))
check <- function(ok, what) {
  if (!isTRUE(ok)) stop("FAILED: ", what, call. = FALSE)
  cat("ok -", what, "\n")
}
set.seed(1)

# Group names with hyphens, colons, spaces and percent signs
g <- c("Drug-Nano", "1:2, 12%", "Drug (10 mg/kg)", "Control")
d <- tibble(group = factor(rep(g, each = 10), levels = g), value = rnorm(40, rep(c(10, 10.2, 14, 18), each = 10), 1))

for (m in c("anova", "welch", "kruskal", "auto")) {
  r <- compare_groups(d, "value", "group", method = m)
  check(nrow(r$pairwise) == 6 && all(c(r$pairwise$group1, r$pairwise$group2) %in% g),
        paste(m, "returns 6 pairs with original group names"))
  check(r$omnibus$p < 0.001, paste(m, "detects the simulated difference"))
}

# TukeyHSD agrees with compare_groups(anova)
r_aov <- compare_groups(d, "value", "group", method = "anova")
tk <- TukeyHSD(aov(value ~ group, data = d))$group
check(isTRUE(all.equal(sort(unname(tk[, "p adj"])), sort(r_aov$pairwise$p.adj))), "Tukey p values match TukeyHSD()")

# Dunn's test agrees with rstatix when available
if (requireNamespace("rstatix", quietly = TRUE)) {
  dn <- rstatix::dunn_test(d, value ~ group, p.adjust.method = "holm")
  ours <- compare_groups(d, "value", "group", method = "kruskal")$pairwise
  check(isTRUE(all.equal(sort(dn$p.adj), sort(ours$p.adj), tolerance = 1e-6)), "Dunn p values match rstatix::dunn_test()")
  gh <- rstatix::games_howell_test(d, value ~ group)
  ours_gh <- compare_groups(d, "value", "group", method = "welch")$pairwise
  check(isTRUE(all.equal(sort(gh$p.adj), sort(ours_gh$p.adj), tolerance = 1e-3)), "Games-Howell p values match rstatix")
}

# Two groups
r2 <- compare_groups(filter(d, group %in% g[1:2]) %>% droplevels(), "value", "group", method = "welch")
check(r2$omnibus$test == "Welch's t-test" && nrow(r2$pairwise) == 1, "two groups use Welch's t-test")

# Compact letters
let <- cld_letters(r_aov$pairwise, g)
check(nrow(let) == 4 && let$letter[1] == let$letter[2] && let$letter[3] != let$letter[4],
      "letters: first two groups share a letter, last two differ")
same <- tibble(group1 = c("A", "A", "B"), group2 = c("B", "C", "C"), p.adj = c(0.5, 0.6, 0.7))
check(all(cld_letters(same, c("A", "B", "C"))$letter == ""), "letters blanked when all groups share one")

# Formatting
check(identical(format_p(c(0.0004, 0.0123, NA)), c("p < 0.001", "p = 0.012", NA)), "format_p")
check(identical(p_stars(c(0.00001, 0.004, 0.03, 0.2)), c("****", "**", "*", "ns")), "p_stars")

# Summaries and positions
s <- summarise_mean_error(d, "value", "group", error = "se")
check(all(abs(s$upper - s$mean - s$sd / sqrt(10)) < 1e-12), "summarise_mean_error se")
y <- annotation_y(d, "value", "group", frac = 0.1)
check(all(y$label_y > tapply(d$value, d$group, max)[as.character(y$group)]), "annotation_y above group max")

# Brackets: only significant pairs, only when the omnibus test is significant, one stack per facet
br <- pairwise_brackets(r_aov$pairwise, d, "group", "value", omnibus_p = r_aov$omnibus$p)
check(nrow(br) == sum(r_aov$pairwise$p.adj < 0.05) && all(br$xmin_n < br$xmax_n), "pairwise_brackets keeps only significant pairs, ordered left to right")
check(!is.unsorted(br$y_position) && all(diff(br$y_position) > 0), "pairwise_brackets stacks brackets without overlap")
check(nrow(pairwise_brackets(r_aov$pairwise, d, "group", "value", omnibus_p = 0.2)) == 0, "no brackets when omnibus p >= 0.05")
check(all(grepl("Control|Drug-Nano|1:2, 12%|Drug", c(pairwise_brackets(r_aov$pairwise, d, "group", "value", vs = "Control")$xmin,
                                                      pairwise_brackets(r_aov$pairwise, d, "group", "value", vs = "Control")$xmax))),
      "vs = keeps comparisons against one group")
check(is.null(geom_brackets(br[0, ])), "geom_brackets() on an empty table returns NULL, so p + geom_brackets(b) is always safe")
pf <- bind_rows(mutate(r_aov$pairwise, panel = "P1"), mutate(r_aov$pairwise, panel = "P2"))
df2 <- bind_rows(mutate(d, panel = "P1"), mutate(d, panel = "P2"))
check(setequal(unique(pairwise_brackets(pf, df2, "group", "value", facet = "panel")$panel), c("P1", "P2")), "brackets per facet panel")

# spread_labels
sp <- spread_labels(c(100, 98.5, 92, 66), gap = 7)
check(all(diff(sort(sp)) >= 7 - 1e-6) && identical(order(sp), order(c(100, 98.5, 92, 66))), "spread_labels separates neighbours and keeps order")

# Scales and half violin build and draw
pp <- ggplot(d, aes(group, value, fill = group, colour = group, shape = group)) + geom_half_violin() + geom_point() +
  scale_fill_pub() + scale_colour_pub() + scale_shape_pub() + theme_pub()
png_tmp <- tempfile(fileext = ".png"); ragg::agg_png(png_tmp, 400, 300); print(pp); dev.off()
check(file.exists(png_tmp), "geom_half_violin + scale_*_pub render")
check(inherits(theme_pub(legend.key.width = grid::unit(2, "cm")), "theme"), "theme_pub passes ... to theme()")

# Saving at journal width
p <- ggplot(d, aes(group, value)) + geom_point() + theme_pub()
out <- save_pub(p, "test_fig", width = "single", journal = "nature", dir = tempdir(), formats = c("pdf", "png", "tiff"), dpi = 300)
check(all(file.exists(out)), "save_pub writes pdf, png, tiff")
if (requireNamespace("png", quietly = TRUE)) {
  dims <- dim(png::readPNG(out[2]))
  check(abs(dims[2] - round(89 / 25.4 * 300)) <= 1, "PNG width equals 89 mm at 300 dpi")
}
cat("All tests passed.\n")
