# Demo / self-test for the gg-figs skill.
# Builds one figure per recipe from simulated data and writes PNG previews to
# examples/gallery/. Run from the skill folder:
#   Rscript examples/demo.R

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
skill_dir <- if (length(script_argument) > 0) {
  dirname(dirname(normalizePath(sub("^--file=", "", script_argument[1]), winslash = "/")))
} else {
  normalizePath(".", winslash = "/")
}
source(file.path(skill_dir, "assets", "gg_pub.R"))
gallery <- file.path(skill_dir, "examples", "gallery")
data_out <- file.path(skill_dir, "examples", "data")
dir.create(data_out, recursive = TRUE, showWarnings = FALSE)
preview <- function(p, stem, width = "double", height = NULL) {
  save_pub(p, stem, width = width, height = height, dir = gallery, formats = "png", dpi = 200, subdirs = FALSE)
}
set.seed(42)

# 1. One factor, raw replicates, n = 12: violin + box + points, compact letters ----
groups <- c("Control", "Vehicle", "Drug 5 mg/kg", "Drug 10 mg/kg")
d1 <- tibble(group = factor(rep(groups, each = 12), levels = groups),
             value = rnorm(48, rep(c(100, 104, 82, 70), each = 12), 8))
write_csv(d1, file.path(data_out, "one_factor_raw.csv"))
st1 <- compare_groups(d1, "value", "group")
let1 <- cld_letters(st1$pairwise, groups) %>%
  left_join(annotation_y(d1, "value", "group", frac = 0.1), by = "group")
cols1 <- pub_palette(groups)
p1 <- ggplot(d1, aes(group, value, fill = group, color = group)) +
  layers_violin_box() +
  geom_text(data = let1, aes(group, label_y, label = letter), inherit.aes = FALSE,
            fontface = "bold", size = 3) +
  scale_fill_manual(values = cols1) + scale_color_manual(values = cols1) +
  scale_y_continuous(expand = expansion(mult = c(0.04, 0.12))) +
  labs(x = NULL, y = "Serum glucose (mg/dL)",
       subtitle = paste0(st1$omnibus$test, ": ", format_p(st1$omnibus$p), "; ", st1$posthoc, " letters")) +
  theme_pub(legend = "none")
preview(p1, "01_violin_box_letters", "single", 75)

# 2. Two factors, small n (4): points + mean +/- SD, dodged -------------------
d2 <- expand_grid(terpene = c("CAM", "THY", "MEN"), conc = c("0.5%", "1%", "2%"), rep = 1:4) %>%
  mutate(terpene = factor(terpene, c("CAM", "THY", "MEN")), conc = factor(conc, c("0.5%", "1%", "2%")),
         value = rnorm(n(), 60 + as.integer(conc) * 6 + as.integer(terpene) * 3, 3))
write_csv(d2, file.path(data_out, "two_factor_small_n.csv"))
cols2 <- pub_palette(d2$terpene)
p2 <- ggplot(d2, aes(conc, value, color = terpene, shape = terpene)) +
  layers_points_mean(error = "sd", dodge = 0.6) +
  scale_color_manual(values = cols2) + scale_shape_manual(values = pub_shapes(d2$terpene)) +
  labs(x = "Terpene concentration", y = "Entrapment efficiency (%)", color = "Terpene", shape = "Terpene") +
  theme_pub()
preview(p2, "02_points_mean_sd_dodged", "single", 70)

# 3. Summary-only data (mean, sd, n): mean +/- SD across facets ---------------
d3 <- expand_grid(endpoint = c("Size (nm)", "PDI", "Zeta potential (mV)"), ratio = c("90:10", "50:50", "10:90")) %>%
  mutate(mean = c(180, 210, 260, 0.21, 0.25, 0.32, -28, -24, -19),
         sd = abs(mean) * 0.07, n = 3,
         ratio = factor(ratio, c("90:10", "50:50", "10:90")),
         endpoint = factor(endpoint, unique(endpoint)))
write_csv(d3, file.path(data_out, "summary_only.csv"))
p3 <- ggplot(d3, aes(ratio, mean, color = ratio, shape = ratio)) +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.15, linewidth = 0.4) +
  geom_point(size = 2) +
  facet_wrap(~ endpoint, scales = "free_y") +
  scale_color_manual(values = pub_palette(d3$ratio)) + scale_shape_manual(values = pub_shapes(d3$ratio)) +
  labs(x = "Span 20:Tween 80 ratio", y = NULL) +
  theme_pub(legend = "none")
preview(p3, "03_summary_mean_sd_facets", "double", 65)

# 4. Time course with replicates: mean +/- SD lines ------------------------------
d4 <- expand_grid(formulation = c("F1", "F2", "F3"), time = c(0, 0.5, 1, 2, 4, 6, 8, 12, 24), rep = 1:3) %>%
  mutate(k = c(F1 = 0.25, F2 = 0.15, F3 = 0.08)[formulation],
         value = pmax(0, 100 * (1 - exp(-k * time)) + rnorm(n(), 0, 2.5) * (time > 0)))
write_csv(select(d4, -k), file.path(data_out, "time_course.csv"))
s4 <- summarise_mean_error(d4, "value", c("formulation", "time"), error = "sd")
p4 <- ggplot(s4, aes(time, mean, color = formulation, shape = formulation, linetype = formulation)) +
  geom_errorbar(aes(ymin = pmax(0, lower), ymax = upper), width = 0.4, linewidth = 0.35, linetype = "solid") +
  geom_line(linewidth = 0.5) + geom_point(size = 1.6) +
  scale_color_manual(values = pub_palette(s4$formulation)) +
  scale_shape_manual(values = pub_shapes(s4$formulation)) +
  scale_linetype_manual(values = pub_linetypes(s4$formulation)) +
  scale_x_continuous(breaks = c(0, 2, 4, 6, 8, 12, 24), expand = expansion(mult = c(0.01, 0.03))) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(x = "Time (h)", y = "Cumulative release (%)", color = NULL, shape = NULL, linetype = NULL) +
  theme_pub()
preview(p4, "04_time_course_mean_sd", "single", 70)

# 5. Calibration / regression: scatter + fit + equation ---------------------------
d5 <- tibble(conc = rep(c(2, 4, 8, 12, 16, 20), each = 3)) %>% mutate(abs = 0.004 + 0.048 * conc + rnorm(n(), 0, 0.012))
fit5 <- lm(abs ~ conc, data = d5)
eq5 <- sprintf("italic(y) == %.4f*italic(x) + %.4f*';'~italic(R)^2 == %.4f",
               coef(fit5)[2], coef(fit5)[1], summary(fit5)$r.squared)
p5 <- ggplot(d5, aes(conc, abs)) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = pub_colors[1], fill = pub_colors[1], alpha = 0.15, linewidth = 0.6) +
  geom_point(size = 1.6, color = "black") +
  annotate("text", x = 2, y = max(d5$abs), label = eq5, parse = TRUE, hjust = 0, vjust = 1, size = 2.8) +
  labs(x = expression("Concentration (" * mu * "g mL"^{-1} * ")"), y = "Absorbance") +
  theme_pub(grid = "xy")
preview(p5, "05_calibration_regression", "single", 65)

# 6. Rheology overlay, log-log, G' / G'' by linetype -------------------------
d6 <- expand_grid(formulation = c("1:2", "1:3", "1:4"), freq = 10^seq(-1, 2, length.out = 20)) %>%
  mutate(base = c("1:2" = 800, "1:3" = 400, "1:4" = 150)[formulation],
         `G'` = base * freq^0.12, `G''` = base * 0.25 * freq^0.25) %>%
  pivot_longer(c(`G'`, `G''`), names_to = "modulus", values_to = "value")
p6 <- ggplot(d6, aes(freq, value, color = formulation, linetype = modulus, shape = modulus,
                     group = interaction(formulation, modulus))) +
  geom_line(linewidth = 0.5) + geom_point(size = 1) +
  scale_x_log10(labels = label_number(big.mark = ",", drop0trailing = TRUE)) +
  scale_y_log10(labels = label_number(big.mark = ",", drop0trailing = TRUE)) +
  annotation_logticks(sides = "bl", linewidth = 0.25, short = grid::unit(0.05, "cm"), mid = grid::unit(0.1, "cm"), long = grid::unit(0.15, "cm")) +
  scale_color_manual(values = pub_palette(d6$formulation)) +
  scale_linetype_manual(values = c("G'" = "solid", "G''" = "dashed")) +
  scale_shape_manual(values = c("G'" = 16, "G''" = 1)) +
  labs(x = "Angular frequency (rad/s)", y = "G', G'' (Pa)", color = "Formulation", linetype = "Modulus", shape = "Modulus") +
  theme_pub(grid = "none") +
  theme(legend.box = "vertical", legend.spacing.y = grid::unit(1, "pt"))
preview(p6, "06_rheology_loglog", "single", 75)

# 7. Spectra / diffractograms: offset stack with peak labels -------------------
two_theta <- seq(5, 60, by = 0.05)
peak <- function(x, c, h, w) h * exp(-((x - c) / w)^2)
d7 <- bind_rows(
  tibble(sample = "Drug", x = two_theta, y = 80 + peak(two_theta, 12.4, 900, 0.15) + peak(two_theta, 24.1, 600, 0.2) + rnorm(length(two_theta), 0, 12)),
  tibble(sample = "Physical mixture", x = two_theta, y = 80 + peak(two_theta, 12.4, 400, 0.15) + peak(two_theta, 21.5, 250, 0.6) + rnorm(length(two_theta), 0, 12)),
  tibble(sample = "Nanoparticles", x = two_theta, y = 80 + peak(two_theta, 21.5, 250, 2.5) + rnorm(length(two_theta), 0, 12))
) %>% mutate(sample = factor(sample, c("Drug", "Physical mixture", "Nanoparticles")))
offset <- 1100
d7 <- d7 %>% mutate(y_off = y + (as.integer(sample) - 1) * offset)
peaks7 <- d7 %>% group_by(sample) %>% slice_max(y, n = 1, with_ties = FALSE) %>% ungroup()
p7 <- ggplot(d7, aes(x, y_off, color = sample)) +
  geom_line(linewidth = 0.35) +
  geom_text(data = peaks7, aes(label = sprintf("%.1f°", x)), vjust = -0.6, size = 2.5, color = "black") +
  geom_text(data = d7 %>% group_by(sample) %>% summarise(y = min(y_off) + 250), aes(x = 59, y = y, label = sample),
            hjust = 1, size = 2.7, fontface = "bold") +
  scale_color_manual(values = pub_palette(d7$sample)) +
  scale_x_continuous(breaks = seq(10, 60, 10), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.06))) +
  labs(x = expression(2 * theta * " (degree)"), y = "Intensity (a.u.)") +
  theme_pub(grid = "none", legend = "none") +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())
preview(p7, "07_xrd_offset_stack", "single", 80)

# 8. Kaplan-Meier with number-at-risk table ------------------------------------
if (requireNamespace("survival", quietly = TRUE)) {
  d8 <- tibble(arm = rep(c("Placebo", "Treatment"), each = 60),
               time = c(rexp(60, 1 / 14), rexp(60, 1 / 24)),
               status = rbinom(120, 1, 0.8)) %>% mutate(time = pmin(time, 36), status = ifelse(time == 36, 0, status))
  fit8 <- survival::survfit(survival::Surv(time, status) ~ arm, data = d8)
  km <- tibble(time = fit8$time, surv = fit8$surv, lower = fit8$lower, upper = fit8$upper,
               n.risk = fit8$n.risk, n.censor = fit8$n.censor,
               arm = rep(sub("arm=", "", names(fit8$strata)), fit8$strata))
  km <- bind_rows(distinct(km, arm) %>% mutate(time = 0, surv = 1, lower = 1, upper = 1), km) %>% arrange(arm, time)
  lr <- survival::survdiff(survival::Surv(time, status) ~ arm, data = d8)
  lr_p <- stats::pchisq(lr$chisq, length(lr$n) - 1, lower.tail = FALSE)
  cols8 <- pub_palette(c("Placebo", "Treatment"))
  breaks8 <- seq(0, 36, 6)
  p8_curve <- ggplot(km, aes(time, surv, color = arm, fill = arm)) +
    geom_step(linewidth = 0.55) +
    geom_point(data = filter(km, n.censor > 0), shape = 3, size = 1.2, show.legend = FALSE) +
    annotate("text", x = 1, y = 0.08, label = paste("Log-rank", format_p(lr_p)), hjust = 0, size = 2.8) +
    scale_color_manual(values = cols8) +
    scale_x_continuous(breaks = breaks8, limits = c(0, 36)) +
    scale_y_continuous(labels = label_percent(), limits = c(0, 1)) +
    labs(x = NULL, y = "Survival probability", color = NULL) +
    theme_pub(legend = "inside") + theme(legend.position.inside = c(0.85, 0.9))
  risk <- summary(fit8, times = breaks8, extend = TRUE)
  risk_tbl <- tibble(time = risk$time, n = risk$n.risk, arm = sub("arm=", "", as.character(risk$strata)))
  p8_risk <- ggplot(risk_tbl, aes(time, arm, label = n, color = arm)) +
    geom_text(size = 2.6, show.legend = FALSE) +
    scale_color_manual(values = cols8) +
    scale_x_continuous(breaks = breaks8, limits = c(0, 36)) +
    labs(x = "Time (months)", y = NULL, title = "Number at risk") +
    theme_pub(grid = "none") +
    theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), plot.title = element_text(size = 7))
  p8 <- p8_curve / p8_risk + plot_layout(heights = c(4, 1))
  preview(p8, "08_kaplan_meier_risk_table", "single", 85)
}

# 9. Volcano plot with labelled hits -----------------------------------------
d9 <- tibble(gene = paste0("G", 1:2000), log2fc = rnorm(2000, 0, 1.1)) %>%
  mutate(p = 10^-(abs(log2fc) * runif(2000, 0.5, 3.2)), padj = p.adjust(p, "BH"),
         class = case_when(padj < 0.05 & log2fc > 1 ~ "Up", padj < 0.05 & log2fc < -1 ~ "Down", TRUE ~ "NS"))
write_csv(d9, file.path(data_out, "volcano.csv"))
top9 <- d9 %>% filter(class != "NS") %>% slice_min(padj, n = 8)
p9 <- ggplot(d9, aes(log2fc, -log10(padj), color = class)) +
  geom_point(size = 0.6, alpha = 0.7) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.3, color = "grey40") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.3, color = "grey40") +
  scale_color_manual(values = c(Up = "#D55E00", Down = "#0072B2", NS = "grey75")) +
  labs(x = expression(log[2] * " fold change"), y = expression(-log[10] * " adjusted p"), color = NULL) +
  theme_pub(grid = "none")
if (requireNamespace("ggrepel", quietly = TRUE)) {
  p9 <- p9 + ggrepel::geom_text_repel(data = top9, aes(label = gene), size = 2.3, family = pub_family(),
                                      color = "black", min.segment.length = 0, segment.size = 0.25, max.overlaps = Inf)
}
preview(p9, "09_volcano", "single", 75)

# 10. Forest plot ----------------------------------------------------------------
d10 <- tibble(study = c("Smith 2019", "Lee 2020", "Garcia 2021", "Chen 2022", "Kumar 2023", "Pooled"),
              est = c(0.82, 0.65, 0.91, 0.71, 0.58, 0.73), lower = c(0.61, 0.44, 0.70, 0.55, 0.38, 0.64),
              upper = c(1.10, 0.96, 1.18, 0.92, 0.89, 0.83), pooled = c(rep(FALSE, 5), TRUE)) %>%
  mutate(study = factor(study, rev(study)), label = sprintf("%.2f (%.2f–%.2f)", est, lower, upper))
# Estimate column is a separate panel so it never clips or collides with the CIs.
p10_plot <- ggplot(d10, aes(est, study)) +
  geom_vline(xintercept = 1, linetype = "dashed", linewidth = 0.3) +
  geom_errorbar(aes(xmin = lower, xmax = upper), width = 0.2, linewidth = 0.4, orientation = "y") +
  geom_point(aes(shape = pooled, size = pooled)) +
  scale_shape_manual(values = c(`FALSE` = 15, `TRUE` = 18), guide = "none") +
  scale_size_manual(values = c(`FALSE` = 1.8, `TRUE` = 3.2), guide = "none") +
  scale_x_log10(breaks = c(0.4, 0.6, 0.8, 1, 1.2)) +
  labs(x = "Hazard ratio (95% CI, log scale)", y = NULL) +
  theme_pub(grid = "none")
p10_text <- ggplot(d10, aes(0, study, label = label)) +
  geom_text(hjust = 0, size = 2.6) +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  labs(x = NULL, y = NULL, title = "HR (95% CI)") +
  theme_void(base_family = pub_family()) +
  theme(plot.title = element_text(size = 7, face = "bold", hjust = 0))
p10 <- p10_plot + p10_text + plot_layout(widths = c(3, 1.3))
preview(p10, "10_forest_plot", "single", 60)

# 11. Correlation heatmap -------------------------------------------------------
m11 <- matrix(rnorm(40 * 6), 40, 6, dimnames = list(NULL, c("BMI", "FBS", "TG", "HDL", "LDL", "Insulin")))
m11[, "TG"] <- m11[, "TG"] + m11[, "FBS"]; m11[, "HDL"] <- m11[, "HDL"] - 0.8 * m11[, "TG"]
cm <- cor(m11)
d11 <- as_tibble(cm, rownames = "a") %>% pivot_longer(-a, names_to = "b", values_to = "r") %>%
  mutate(a = factor(a, colnames(cm)), b = factor(b, rev(colnames(cm))))
p11 <- ggplot(d11, aes(a, b, fill = r)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%.2f", r), color = abs(r) > 0.6), size = 2.4, show.legend = FALSE) +
  scale_color_manual(values = c(`TRUE` = "white", `FALSE` = "black")) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", limits = c(-1, 1), name = "r") +
  coord_equal() + labs(x = NULL, y = NULL) +
  theme_pub(grid = "none", legend = "right") +
  theme(axis.line = element_blank(), axis.ticks = element_blank())
preview(p11, "11_correlation_heatmap", "single", 75)

# 12. PCA scores with 95% ellipses ----------------------------------------------
d12 <- bind_rows(lapply(1:3, function(i) as_tibble(matrix(rnorm(20 * 5, i), 20, 5, dimnames = list(NULL, paste0("V", 1:5)))) %>%
  mutate(group = c("HFD", "Treatment A", "Treatment B")[i])))
pca <- prcomp(select(d12, starts_with("V")), scale. = TRUE)
ve <- summary(pca)$importance[2, 1:2] * 100
d12s <- bind_cols(d12, as_tibble(pca$x[, 1:2]))
p12 <- ggplot(d12s, aes(PC1, PC2, color = group, fill = group, shape = group)) +
  stat_ellipse(geom = "polygon", alpha = 0.12, level = 0.95, linewidth = 0.3) +
  geom_point(size = 1.6) +
  scale_color_manual(values = pub_palette(d12s$group)) + scale_fill_manual(values = pub_palette(d12s$group)) +
  scale_shape_manual(values = pub_shapes(d12s$group)) +
  labs(x = sprintf("PC1 (%.1f%%)", ve[1]), y = sprintf("PC2 (%.1f%%)", ve[2]), color = NULL, fill = NULL, shape = NULL) +
  theme_pub(grid = "xy")
preview(p12, "12_pca_scores", "single", 75)

# 13. Paired before/after ----------------------------------------------------------
d13 <- tibble(subject = rep(1:12, 2), time = factor(rep(c("Before", "After"), each = 12), c("Before", "After")),
              value = c(rnorm(12, 250, 20), rnorm(12, 215, 20)))
tt13 <- t.test(d13$value[d13$time == "Before"], d13$value[d13$time == "After"], paired = TRUE)
p13 <- ggplot(d13, aes(time, value)) +
  geom_line(aes(group = subject), color = "grey65", linewidth = 0.3) +
  geom_point(aes(color = time), size = 1.5, show.legend = FALSE) +
  stat_summary(fun.data = mean_error_fun("sd"), geom = "errorbar", width = 0.12, linewidth = 0.5,
               position = position_nudge(x = c(-0.18, 0.18))) +
  stat_summary(fun = mean, geom = "point", size = 2.6, shape = 18, position = position_nudge(x = c(-0.18, 0.18))) +
  scale_color_manual(values = pub_palette(d13$time)) +
  labs(x = NULL, y = "Total cholesterol (mg/dL)", subtitle = paste("Paired t-test:", format_p(tt13$p.value))) +
  theme_pub()
preview(p13, "13_paired_before_after", "single", 70)

# 14. Composite plate with patchwork tags -----------------------------------------
# Tag style comes from theme_pub(); avoid `& theme()` (warns with patchwork 1.3.1 + ggplot2 4.x).
plate <- (p1 | p2) / (p4 | p12) + plot_annotation(tag_levels = "A")
preview(plate, "14_composite_plate", "double", 150)

message("Demo finished: ", length(list.files(gallery, pattern = "\\.png$")), " PNG files in ", gallery)
