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
g <- c("Bigel-Nano", "1:2, 12%", "Drug (10 mg/kg)", "Control")
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

# Saving at journal width
p <- ggplot(d, aes(group, value)) + geom_point() + theme_pub()
out <- save_pub(p, "test_fig", width = "single", journal = "nature", dir = tempdir(), formats = c("pdf", "png", "tiff"), dpi = 300)
check(all(file.exists(out)), "save_pub writes pdf, png, tiff")
if (requireNamespace("png", quietly = TRUE)) {
  dims <- dim(png::readPNG(out[2]))
  check(abs(dims[2] - round(89 / 25.4 * 300)) <= 1, "PNG width equals 89 mm at 300 dpi")
}
cat("All tests passed.\n")
