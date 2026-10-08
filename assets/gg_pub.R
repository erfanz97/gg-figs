# gg_pub.R -- helpers for publication-quality ggplot2 figures (gg-figs skill)
#
# Copy this file into the project (e.g. R/gg_pub.R) and source it at the top of
# every figure script, so the project stays reproducible without the skill:
#   source("R/gg_pub.R")
#
# Contents
#   pub_font()            pick and register the figure font (default Times New Roman)
#   theme_pub()           journal theme sized for figures saved at final print size
#   pub_palette()/...     colorblind-safe named palettes, shapes, linetypes
#   format_p(), p_stars() p-value formatting
#   summarise_mean_error() mean with SD / SE / 95% CI per group
#   annotation_y()        y positions for letters / labels above groups
#   compare_groups()      omnibus + post-hoc tests (ANOVA/Tukey, Welch/Games-Howell, Kruskal/Dunn)
#   cld_letters()         compact letter display from a pairwise table
#   layers_violin_box()   violin + box + points for raw replicates
#   layers_points_mean()  points + mean +/- error for small n
#   save_pub()            PDF (vector) + 600-dpi TIFF/PNG at journal column widths

gg_pub_packages <- c("ggplot2", "dplyr", "tidyr", "readr", "patchwork", "ragg", "scales", "systemfonts")
local({
  missing <- gg_pub_packages[!vapply(gg_pub_packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    stop("Install missing packages: install.packages(c(",
         paste0('"', missing, '"', collapse = ", "), "))", call. = FALSE)
  }
})
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(patchwork)
  library(scales)
})

if (.Platform$OS.type == "windows") {
  try(Sys.setlocale("LC_ALL", "English_United States.utf8"), silent = TRUE)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---------------------------------------------------------------------------
# Font
# ---------------------------------------------------------------------------

# Selects the first installed font among `family` and `fallback`, stores it in
# options(ggpub.font) and makes it the default for text/label geoms.
# A missing font otherwise falls back silently to a different face.
pub_font <- function(family = "Times New Roman",
                     fallback = c("Arial", "Helvetica", "Liberation Serif", "Liberation Sans", "DejaVu Sans")) {
  available <- tolower(unique(c(systemfonts::system_fonts()$family,
                                systemfonts::registry_fonts()$family)))
  chosen <- "sans"
  for (candidate in c(family, fallback)) {
    if (tolower(candidate) %in% available) {
      chosen <- candidate
      break
    }
  }
  if (!identical(chosen, family)) {
    warning("Font '", family, "' not found; using '", chosen, "'.", call. = FALSE)
  }
  options(ggpub.font = chosen)
  update_geom_defaults("text", list(family = chosen))
  update_geom_defaults("label", list(family = chosen))
  invisible(chosen)
}

pub_family <- function() getOption("ggpub.font", "sans")

pub_font(getOption("ggpub.font.request", "Times New Roman"))

# ---------------------------------------------------------------------------
# Theme
# ---------------------------------------------------------------------------

# base_size is the font size in points AT FINAL PRINT SIZE. Save with save_pub()
# at the real column width and keep base_size 7-9 so the printed text is 6-9 pt.
theme_pub <- function(base_size = 8, base_family = pub_family(),
                      grid = c("y", "none", "x", "xy"), legend = "top", border = FALSE) {
  grid <- match.arg(grid)
  lw <- base_size / 20
  out <- theme_classic(base_size = base_size, base_family = base_family) +
    theme(
      text = element_text(color = "black"),
      axis.title = element_text(face = "bold", color = "black"),
      axis.text = element_text(size = rel(0.9), color = "black"),
      axis.line = element_line(color = "black", linewidth = lw),
      axis.ticks = element_line(color = "black", linewidth = lw * 0.8),
      axis.ticks.length = grid::unit(base_size / 4, "pt"),
      panel.grid.minor = element_blank(),
      strip.background = element_blank(),
      strip.text = element_text(face = "bold", size = rel(1), color = "black"),
      plot.title = element_text(face = "bold", size = rel(1.15), hjust = 0),
      plot.title.position = "plot",
      plot.subtitle = element_text(size = rel(0.9), hjust = 0, margin = margin(b = base_size / 2)),
      plot.caption = element_text(size = rel(0.8), hjust = 0, color = "grey30"),
      plot.caption.position = "plot",
      plot.tag = element_text(face = "bold", size = rel(1.25)),
      legend.position = legend,
      legend.title = element_text(face = "bold", size = rel(0.95)),
      legend.text = element_text(size = rel(0.9)),
      legend.key.size = grid::unit(base_size * 1.25, "pt"),
      legend.margin = margin(0, 0, 0, 0),
      legend.box.spacing = grid::unit(base_size / 2, "pt"),
      panel.spacing = grid::unit(base_size, "pt"),
      plot.margin = margin(base_size / 2, base_size * 0.75, base_size / 2, base_size / 2)
    )
  grid_line <- element_line(color = "#E5E5E5", linewidth = lw * 0.6)
  if (grid %in% c("y", "xy")) out <- out + theme(panel.grid.major.y = grid_line)
  if (grid %in% c("x", "xy")) out <- out + theme(panel.grid.major.x = grid_line)
  if (border) {
    out <- out + theme(
      panel.border = element_rect(fill = NA, color = "black", linewidth = lw),
      axis.line = element_blank()
    )
  }
  out
}

# ---------------------------------------------------------------------------
# Palettes, shapes, linetypes
# ---------------------------------------------------------------------------

# Okabe-Ito based, ordered for contrast on white; yellow is left out on purpose.
pub_colors <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00",
                "#56B4E9", "#4D4D4D", "#9467BD", "#8C564B", "#B8860B")
pub_shape_set <- c(16, 17, 15, 18, 1, 2, 0, 5, 3, 8)
pub_fill_shape_set <- c(21, 24, 22, 23, 25)
pub_linetype_set <- c("solid", "dashed", "dotdash", "dotted", "longdash", "twodash")

.pub_levels <- function(levels) {
  if (is.factor(levels)) levels(levels) else unique(as.character(levels))
}

# Named vectors keep every group the same color/shape in every figure of a paper.
pub_palette <- function(levels, colors = pub_colors) {
  levels <- .pub_levels(levels)
  if (length(levels) > length(colors)) {
    warning(length(levels), " groups but only ", length(colors),
            " distinct colors; consider facets or grouping.", call. = FALSE)
  }
  setNames(rep_len(colors, length(levels)), levels)
}
pub_shapes <- function(levels, shapes = pub_shape_set) {
  levels <- .pub_levels(levels)
  setNames(rep_len(shapes, length(levels)), levels)
}
pub_linetypes <- function(levels, linetypes = pub_linetype_set) {
  levels <- .pub_levels(levels)
  setNames(rep_len(linetypes, length(levels)), levels)
}

# Grey ramp for ordered levels (e.g. doses) when hue would imply categories.
pub_ordered <- function(levels, from = "#C6DBEF", to = "#08306B") {
  levels <- .pub_levels(levels)
  setNames(grDevices::colorRampPalette(c(from, to))(length(levels)), levels)
}

# ---------------------------------------------------------------------------
# p-values
# ---------------------------------------------------------------------------

format_p <- function(p, digits = 3, prefix = "p") {
  threshold <- 10^-digits
  ifelse(
    is.na(p), NA_character_,
    ifelse(p < threshold,
           paste0(prefix, " < ", format(threshold, scientific = FALSE)),
           paste0(prefix, " = ", formatC(p, format = "f", digits = digits)))
  )
}

p_stars <- function(p, ns = "ns") {
  as.character(cut(p, c(-Inf, 1e-4, 1e-3, 1e-2, 0.05, Inf),
                   labels = c("****", "***", "**", "*", ns)))
}

# ---------------------------------------------------------------------------
# Summaries and label positions
# ---------------------------------------------------------------------------

summarise_mean_error <- function(data, value, by, error = c("sd", "se", "ci95")) {
  error <- match.arg(error)
  out <- data %>%
    group_by(across(all_of(by))) %>%
    summarise(
      n = sum(!is.na(.data[[value]])),
      mean = mean(.data[[value]], na.rm = TRUE),
      sd = stats::sd(.data[[value]], na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      se = sd / sqrt(n),
      ci95 = stats::qt(0.975, pmax(n - 1, 1)) * se
    )
  out$err <- out[[error]]
  out %>%
    mutate(
      err = ifelse(is.na(err), 0, err),
      lower = mean - err,
      upper = mean + err,
      error_type = error
    )
}

# Per-group label height: max(value) + frac * (range of value within the facet).
# `value` may be "value" for raw data or "upper" for mean +/- error summaries.
annotation_y <- function(data, value, by, facet = NULL, frac = 0.08) {
  facet <- as.character(facet)
  data %>%
    group_by(across(all_of(facet))) %>%
    mutate(.span = {
      r <- diff(range(.data[[value]], na.rm = TRUE))
      if (!is.finite(r) || r == 0) max(abs(.data[[value]]), 1, na.rm = TRUE) else r
    }) %>%
    group_by(across(all_of(c(facet, by)))) %>%
    summarise(label_y = max(.data[[value]], na.rm = TRUE) + frac * first(.span), .groups = "drop")
}

# ---------------------------------------------------------------------------
# Statistics
# ---------------------------------------------------------------------------

# Dunn's test with tie correction (no extra package needed).
.dunn_test <- function(y, g, p_adjust = "holm") {
  n_total <- length(y)
  ranks <- rank(y)
  ties <- table(y)
  tie_term <- sum(ties^3 - ties) / (12 * (n_total - 1))
  levels_g <- levels(g)
  mean_rank <- tapply(ranks, g, mean)
  n <- tapply(ranks, g, length)
  pairs <- utils::combn(levels_g, 2)
  z <- apply(pairs, 2, function(pr) {
    (mean_rank[pr[1]] - mean_rank[pr[2]]) /
      sqrt((n_total * (n_total + 1) / 12 - tie_term) * (1 / n[pr[1]] + 1 / n[pr[2]]))
  })
  p <- 2 * stats::pnorm(-abs(z))
  tibble::tibble(group1 = pairs[1, ], group2 = pairs[2, ], statistic = unname(z),
                 p = unname(p), p.adj = stats::p.adjust(p, p_adjust))
}

# Games-Howell post-hoc test for unequal variances.
.games_howell <- function(y, g) {
  levels_g <- levels(g)
  k <- length(levels_g)
  m <- tapply(y, g, mean)
  v <- tapply(y, g, stats::var)
  n <- tapply(y, g, length)
  pairs <- utils::combn(levels_g, 2)
  res <- apply(pairs, 2, function(pr) {
    a <- pr[1]; b <- pr[2]
    se <- sqrt(v[a] / n[a] + v[b] / n[b])
    t <- (m[a] - m[b]) / se
    df <- (v[a] / n[a] + v[b] / n[b])^2 /
      ((v[a] / n[a])^2 / (n[a] - 1) + (v[b] / n[b])^2 / (n[b] - 1))
    c(t = unname(t), df = unname(df),
      p = stats::ptukey(abs(unname(t)) * sqrt(2), k, unname(df), lower.tail = FALSE))
  })
  tibble::tibble(group1 = pairs[1, ], group2 = pairs[2, ], statistic = res["t", ],
                 p = res["p", ], p.adj = res["p", ])
}

# One-factor group comparison. method = "auto" picks the test from residual
# normality (Shapiro-Wilk) and variance homogeneity (Fligner-Killeen); always
# report which test was used. Returns omnibus, pairwise (group1, group2, p.adj)
# and diagnostics. Group labels may contain any character.
compare_groups <- function(data, value, group, method = c("auto", "anova", "welch", "kruskal"),
                           p_adjust = "holm", alpha = 0.05) {
  method <- match.arg(method)
  d <- data[!is.na(data[[value]]) & !is.na(data[[group]]), , drop = FALSE]
  g_orig <- if (is.factor(d[[group]])) droplevels(d[[group]]) else factor(d[[group]], levels = unique(d[[group]]))
  lv <- levels(g_orig)
  if (length(lv) < 2) stop("Need at least two groups.", call. = FALSE)
  safe <- setNames(paste0("g", seq_along(lv)), lv)
  g <- factor(safe[as.character(g_orig)], levels = safe)
  y <- d[[value]]
  fit <- stats::aov(y ~ g)
  res <- stats::residuals(fit)
  shapiro_p <- if (length(res) >= 3 && length(res) <= 5000 && stats::var(res) > 0) stats::shapiro.test(res)$p.value else NA_real_
  fligner_p <- tryCatch(stats::fligner.test(y, g)$p.value, error = function(e) NA_real_)
  if (method == "auto") {
    method <- if (!is.na(shapiro_p) && shapiro_p < alpha) "kruskal"
      else if (!is.na(fligner_p) && fligner_p < alpha) "welch"
      else "anova"
  }
  if (length(lv) == 2) {
    tt <- if (method == "kruskal") stats::wilcox.test(y ~ g, exact = FALSE) else stats::t.test(y ~ g, var.equal = method == "anova")
    test_name <- if (method == "kruskal") "Mann-Whitney U test" else if (method == "anova") "Student's t-test" else "Welch's t-test"
    omnibus <- tibble::tibble(test = test_name, statistic = unname(tt$statistic),
                              df = as.character(round(unname(tt$parameter %||% NA_real_), 2)), p = tt$p.value)
    pairwise <- tibble::tibble(group1 = unname(safe[1]), group2 = unname(safe[2]), statistic = unname(tt$statistic),
                               p = tt$p.value, p.adj = tt$p.value)
    posthoc <- "none (two groups)"
  } else if (method == "anova") {
    s <- summary(fit)[[1]]
    omnibus <- tibble::tibble(test = "One-way ANOVA", statistic = s[["F value"]][1],
                              df = paste(s$Df[1], s$Df[2], sep = ", "), p = s[["Pr(>F)"]][1])
    tk <- stats::TukeyHSD(fit)$g
    parts <- strsplit(rownames(tk), "-", fixed = TRUE)
    pairwise <- tibble::tibble(group1 = vapply(parts, `[`, "", 1), group2 = vapply(parts, `[`, "", 2),
                               statistic = unname(tk[, "diff"]), p = unname(tk[, "p adj"]),
                               p.adj = unname(tk[, "p adj"]))
    posthoc <- "Tukey HSD"
  } else if (method == "welch") {
    w <- stats::oneway.test(y ~ g, var.equal = FALSE)
    omnibus <- tibble::tibble(test = "Welch's ANOVA", statistic = unname(w$statistic),
                              df = paste(round(w$parameter, 2), collapse = ", "), p = w$p.value)
    pairwise <- .games_howell(y, g)
    posthoc <- "Games-Howell"
  } else {
    kw <- stats::kruskal.test(y ~ g)
    omnibus <- tibble::tibble(test = "Kruskal-Wallis test", statistic = unname(kw$statistic),
                              df = as.character(kw$parameter), p = kw$p.value)
    pairwise <- .dunn_test(y, g, p_adjust)
    posthoc <- paste0("Dunn's test (", p_adjust, " adjustment)")
  }
  back <- setNames(lv, safe)
  pairwise$group1 <- unname(back[pairwise$group1])
  pairwise$group2 <- unname(back[pairwise$group2])
  pairwise$significant <- pairwise$p.adj < alpha
  list(
    method = method,
    omnibus = omnibus,
    posthoc = posthoc,
    pairwise = pairwise,
    diagnostics = tibble::tibble(shapiro_residuals_p = shapiro_p, fligner_p = fligner_p,
                                 n_per_group = paste(tapply(y, g, length), collapse = "/")),
    levels = lv
  )
}

# Compact letter display. Groups sharing a letter are not significantly different.
# Works with any group names (hyphens included). Returns blank letters when all
# groups share one letter, because a row of identical letters adds nothing.
cld_letters <- function(pairwise, group_levels, p_col = "p.adj", g1 = "group1", g2 = "group2",
                        alpha = 0.05, blank_if_all_same = TRUE) {
  if (!requireNamespace("multcompView", quietly = TRUE)) {
    stop("Install multcompView: install.packages(\"multcompView\")", call. = FALSE)
  }
  lv <- .pub_levels(group_levels)
  ids <- setNames(paste0("g", seq_along(lv)), lv)
  a <- ids[as.character(pairwise[[g1]])]
  b <- ids[as.character(pairwise[[g2]])]
  if (anyNA(a) || anyNA(b)) {
    unknown <- setdiff(unique(c(pairwise[[g1]], pairwise[[g2]])), lv)
    stop("Pairwise table has groups not in group_levels: ", paste(unknown, collapse = ", "), call. = FALSE)
  }
  p <- setNames(pairwise[[p_col]], paste(a, b, sep = "-"))
  letters_found <- multcompView::multcompLetters(p, threshold = alpha)$Letters
  out <- tibble::tibble(group = factor(lv, levels = lv), letter = unname(letters_found[ids]))
  if (blank_if_all_same && dplyr::n_distinct(out$letter, na.rm = TRUE) <= 1) out$letter <- ""
  out
}

# ---------------------------------------------------------------------------
# Layer bundles
# ---------------------------------------------------------------------------

# Violin + box + raw points. Map fill and color to the same variable.
# Use for n >= ~10 per group; for smaller n prefer layers_points_mean() unless
# the project's existing figures already use violins. trim = TRUE keeps the
# density inside the observed range, so annotation_y() labels clear the violin.
layers_violin_box <- function(dodge = NULL, violin_alpha = 0.25, box_width = 0.16,
                              point_size = 1, point_alpha = 0.8, jitter = 0.06,
                              violin = TRUE, points = TRUE, trim = TRUE, seed = 1) {
  if (is.null(dodge)) {
    pos_main <- "identity"
    pos_pts <- position_jitter(width = jitter, height = 0, seed = seed)
  } else {
    pos_main <- position_dodge(width = dodge)
    pos_pts <- position_jitterdodge(jitter.width = jitter, jitter.height = 0, dodge.width = dodge, seed = seed)
  }
  out <- list()
  if (violin) {
    out <- c(out, list(geom_violin(position = pos_main, width = 0.8, alpha = violin_alpha,
                                   linewidth = 0.3, trim = trim, scale = "width")))
  }
  out <- c(out, list(geom_boxplot(position = pos_main, width = box_width, outlier.shape = NA,
                                  alpha = 0.85, linewidth = 0.35, staplewidth = 0)))
  if (points) {
    out <- c(out, list(geom_point(position = pos_pts, size = point_size, alpha = point_alpha,
                                  show.legend = FALSE)))
  }
  out
}

.mean_err_fun <- function(error) {
  switch(error,
    sd = function(y) { m <- mean(y); s <- stats::sd(y); s <- ifelse(is.na(s), 0, s)
                       data.frame(y = m, ymin = m - s, ymax = m + s) },
    se = function(y) { m <- mean(y); s <- stats::sd(y) / sqrt(length(y)); s <- ifelse(is.na(s), 0, s)
                       data.frame(y = m, ymin = m - s, ymax = m + s) },
    ci95 = function(y) { m <- mean(y); n <- length(y)
                         h <- if (n > 1) stats::qt(0.975, n - 1) * stats::sd(y) / sqrt(n) else 0
                         data.frame(y = m, ymin = m - h, ymax = m + h) },
    stop("error must be 'sd', 'se' or 'ci95'", call. = FALSE)
  )
}

# fun.data for stat_summary(): mean with SD, SE or 95% CI limits.
mean_error_fun <- function(error = "sd") .mean_err_fun(error)

# Raw points + mean (horizontal bar) +/- error. Honest default for small n.
layers_points_mean <- function(error = "sd", dodge = NULL, point_size = 1.3, point_alpha = 0.75,
                               jitter = 0.08, bar_width = 0.22, mean_width = 0.36, seed = 1) {
  f <- .mean_err_fun(error)
  if (is.null(dodge)) {
    pos_sum <- "identity"
    pos_pts <- position_jitter(width = jitter, height = 0, seed = seed)
  } else {
    pos_sum <- position_dodge(width = dodge)
    pos_pts <- position_jitterdodge(jitter.width = jitter, jitter.height = 0, dodge.width = dodge, seed = seed)
  }
  list(
    geom_point(position = pos_pts, size = point_size, alpha = point_alpha),
    stat_summary(fun.data = f, geom = "errorbar", width = bar_width, linewidth = 0.4, position = pos_sum),
    stat_summary(fun = mean, fun.min = mean, fun.max = mean, geom = "crossbar",
                 width = mean_width, linewidth = 0.35, position = pos_sum, show.legend = FALSE)
  )
}

# ---------------------------------------------------------------------------
# Saving
# ---------------------------------------------------------------------------

# Column widths (mm) from publisher author guidelines; verify for the target journal.
pub_journals <- list(
  default  = list(single = 85,  onehalf = 120, double = 175, max_height = 230),
  elsevier = list(single = 90,  onehalf = 140, double = 190, max_height = 240),
  springer = list(single = 84,  onehalf = 129, double = 174, max_height = 234),
  nature   = list(single = 89,  onehalf = 120, double = 183, max_height = 247),
  cell     = list(single = 85,  onehalf = 114, double = 174, max_height = 225),
  acs      = list(single = 82.5, onehalf = 120, double = 178, max_height = 241),
  wiley    = list(single = 80,  onehalf = 125, double = 170, max_height = 230),
  plos     = list(single = 132, onehalf = 132, double = 190.5, max_height = 222),
  science  = list(single = 55,  onehalf = 120, double = 183, max_height = 230),
  mdpi     = list(single = 85,  onehalf = 125, double = 170, max_height = 230)
)

# width: "single", "onehalf", "double" or a number in mm. height in mm
# (default width * aspect). Writes <dir>/<format>/<stem>.<ext> and returns the paths.
save_pub <- function(plot, stem, width = "double", height = NULL, journal = "default",
                     dir = "figures", formats = c("pdf", "tiff", "png"), dpi = 600,
                     aspect = 0.62, bg = "white", subdirs = TRUE) {
  spec <- pub_journals[[tolower(journal)]]
  if (is.null(spec)) stop("Unknown journal '", journal, "'. Known: ", paste(names(pub_journals), collapse = ", "), call. = FALSE)
  width_mm <- if (is.numeric(width)) width else spec[[width]]
  if (is.null(width_mm)) stop("width must be single, onehalf, double or a number (mm).", call. = FALSE)
  height_mm <- height %||% round(width_mm * aspect)
  if (height_mm > spec$max_height) {
    warning(sprintf("Height %.0f mm exceeds the %s maximum of %.0f mm.", height_mm, journal, spec$max_height), call. = FALSE)
  }
  paths <- character()
  for (fmt in formats) {
    out_dir <- if (subdirs) file.path(dir, fmt) else dir
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    path <- file.path(out_dir, paste0(stem, ".", fmt))
    args <- list(filename = path, plot = plot, width = width_mm, height = height_mm, units = "mm", bg = bg)
    if (fmt == "pdf") {
      args$device <- if (capabilities("cairo")) grDevices::cairo_pdf else "pdf"
    } else if (fmt == "png") {
      args$device <- ragg::agg_png; args$dpi <- dpi
    } else if (fmt %in% c("tif", "tiff")) {
      args$device <- ragg::agg_tiff; args$dpi <- dpi; args$compression <- "lzw"
    } else if (fmt == "svg") {
      if (!requireNamespace("svglite", quietly = TRUE)) stop("Install svglite for SVG output.", call. = FALSE)
      args$device <- svglite::svglite
    } else if (fmt == "eps") {
      args$device <- grDevices::cairo_ps
    } else if (fmt %in% c("jpg", "jpeg")) {
      args$device <- ragg::agg_jpeg; args$dpi <- dpi
    } else {
      stop("Unsupported format: ", fmt, call. = FALSE)
    }
    do.call(ggsave, args)
    paths <- c(paths, path)
  }
  message(sprintf("Saved %s (%.0f x %.0f mm): %s", stem, width_mm, height_mm, paste(basename(paths), collapse = ", ")))
  invisible(paths)
}
