# Gallery: one polished example per chart type, all on SIMULATED data.
# Writes PNG previews to examples/gallery/. Run from the skill folder:
#   Rscript examples/gallery.R
# Each section is self-contained and mirrors a recipe in references/recipes.md.

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
skill_dir <- if (length(script_argument) > 0) {
  dirname(dirname(normalizePath(sub("^--file=", "", script_argument[1]), winslash = "/")))
} else {
  normalizePath(".", winslash = "/")
}
source(file.path(skill_dir, "assets", "gg_pub.R"))
OUT <- file.path(skill_dir, "examples", "gallery")
DATA_OUT <- file.path(skill_dir, "examples", "data")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(DATA_OUT, recursive = TRUE, showWarnings = FALSE)
preview <- function(p, stem, width = 85, height = 75) {
  save_pub(p, stem, width = width, height = height, dir = OUT, formats = "png", dpi = 300, subdirs = FALSE)
}
set.seed(2025)

# ===========================================================================
# 01  Raincloud: raw replicates, brackets for significant pairs vs control
# ===========================================================================
g1 <- c("Control", "Vehicle", "Low dose", "High dose")
d1 <- tibble(
  group = factor(rep(g1, each = 14), levels = g1),
  value = rnorm(56, rep(c(102, 100, 89, 72), each = 14), rep(c(8, 9, 8, 10), each = 14))
)
write_csv(d1, file.path(DATA_OUT, "raincloud_raw.csv"))
st1 <- compare_groups(d1, "value", "group")
b1 <- pairwise_brackets(st1$pairwise, d1, "group", "value", omnibus_p = st1$omnibus$p, vs = "Control")
cols1 <- pub_palette(g1)
p01 <- ggplot(d1, aes(group, value, fill = group, color = group)) +
  layers_raincloud() +
  geom_brackets(b1) +
  scale_fill_manual(values = cols1) + scale_color_manual(values = cols1) +
  scale_x_discrete(labels = function(x) paste0(x, "\n(n = 14)")) +
  scale_y_continuous(breaks = seq(60, 140, 20)) +
  labs(x = NULL, y = "Fasting glucose (mg/dL)") +
  theme_pub(legend = "none")
preview(p01, "01_raincloud_brackets", 90, 80)

# ===========================================================================
# 02  Violin + box + points, facets by time point, brackets vs control per panel
# ===========================================================================
g2 <- c("Control", "Drug A", "Drug B")
means2 <- tibble(group = rep(g2, each = 3), week = rep(c("Week 2", "Week 4", "Week 8"), 3),
                 mu = c(2, 4, 6, 1.2, 0.2, -2, 0.5, -3, -7.5))
d2 <- expand_grid(week = c("Week 2", "Week 4", "Week 8"), group = g2, id = 1:10) %>%
  left_join(means2, by = c("group", "week")) %>%
  mutate(value = rnorm(n(), mu, 2.4), group = factor(group, levels = g2)) %>% select(-mu)
pw2 <- d2 %>% group_by(week) %>%
  group_modify(~ {
    res <- compare_groups(.x, "value", "group")
    if (res$omnibus$p >= 0.05) res$pairwise[0, ] else res$pairwise
  }) %>% ungroup()
b2 <- pairwise_brackets(pw2, d2, "group", "value", facet = "week", label = "stars", vs = "Control")
cols2 <- pub_palette(g2)
p02 <- ggplot(d2, aes(group, value, fill = group, color = group)) +
  layers_violin_box() +
  geom_hline(yintercept = 0, linewidth = 0.3, color = "grey40") +
  geom_brackets(b2) +
  facet_wrap(~ week) +
  scale_fill_manual(values = cols2) + scale_color_manual(values = cols2) +
  labs(x = NULL, y = "Body-weight change (%)") +
  theme_pub(legend = "none")
preview(p02, "02_violin_box_facets_brackets", 175, 75)

# ===========================================================================
# 03  Points + mean +/- SD, dodged, faceted by gene
# ===========================================================================
d3 <- expand_grid(gene = c("Adipoq", "Pparg", "Srebf1"), genotype = c("WT", "KO"), treatment = c("Vehicle", "Drug"), id = 1:5) %>%
  mutate(effect = ifelse(treatment == "Drug", ifelse(genotype == "WT", 2.1, 1.1), 1) *
           c(Adipoq = 1, Pparg = 0.8, Srebf1 = 1.4)[gene] * ifelse(genotype == "KO" & treatment == "Vehicle", 0.6, 1),
         value = pmax(0.05, rnorm(n(), effect, 0.18 * effect)),
         treatment = factor(treatment, c("Vehicle", "Drug")), genotype = factor(genotype, c("WT", "KO")))
cols3 <- pub_palette(levels(d3$treatment), c("#7F7F7F", "#D55E00"))
p03 <- ggplot(d3, aes(genotype, value, color = treatment, shape = treatment)) +
  geom_hline(yintercept = 1, linetype = "dashed", linewidth = 0.3, color = "grey55") +
  layers_points_mean(error = "sd", dodge = 0.65, point_size = 1.5) +
  facet_wrap(~ gene, scales = "free_y") +
  scale_color_manual(values = cols3) + scale_shape_manual(values = c(Vehicle = 16, Drug = 17)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  labs(x = NULL, y = "Relative mRNA expression", color = NULL, shape = NULL) +
  theme_pub()
preview(p03, "03_points_mean_sd_dodged_facets", 175, 70)

# ===========================================================================
# 04  Release profiles from t = 0, ribbon = SD, direct labels instead of a legend
# ===========================================================================
tt <- c(0, 0.5, 1, 2, 4, 6, 8, 12, 24)
rates <- c("Liposome" = 0.11, "Niosome" = 0.19, "Free drug" = 0.55, "Hydrogel" = 0.045)
d4 <- expand_grid(formulation = names(rates), time = tt, rep = 1:3) %>%
  mutate(value = pmin(100, pmax(0, 100 * (1 - exp(-rates[formulation] * time)) + rnorm(n(), 0, 2) * (time > 0))),
         formulation = factor(formulation, names(rates)))
s4 <- summarise_mean_error(d4, "value", c("formulation", "time"), "sd")
ends4 <- s4 %>% filter(time == max(time)) %>% arrange(mean) %>%
  mutate(y_lab = spread_labels(mean, gap = 7))
cols4 <- pub_palette(names(rates))
p04 <- ggplot(s4, aes(time, mean, color = formulation, fill = formulation)) +
  geom_ribbon(aes(ymin = pmax(0, lower), ymax = pmin(100, upper)), alpha = 0.15, color = NA) +
  geom_line(linewidth = 0.6) +
  geom_point(aes(shape = formulation), size = 1.6) +
  geom_text(data = ends4, aes(x = max(tt) + 0.8, y = y_lab, label = formulation), hjust = 0, size = 2.7, fontface = "bold",
            show.legend = FALSE) +
  scale_color_manual(values = cols4) + scale_fill_manual(values = cols4) + scale_shape_manual(values = pub_shapes(names(rates))) +
  scale_x_continuous(breaks = c(0, 2, 4, 8, 12, 24), expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_continuous(breaks = seq(0, 100, 25), expand = expansion(mult = c(0, 0.02))) +
  coord_cartesian(ylim = c(0, 100), clip = "off") +
  labs(x = "Time (h)", y = "Cumulative release (%)") +
  theme_pub(legend = "none", plot.margin = margin(8, 48, 4, 4))
preview(p04, "04_release_profiles_direct_labels", 90, 70)

# ===========================================================================
# 05  Pharmacokinetics: semi-log plasma concentration, LLOQ line
# ===========================================================================
tp <- c(0.25, 0.5, 1, 2, 4, 6, 8, 12, 24)
conc <- function(t, dose) dose * (45 * exp(-1.6 * t) + 30 * exp(-0.085 * t))
d5 <- expand_grid(dose = c("5 mg/kg", "10 mg/kg"), time = tp, id = 1:6) %>%
  mutate(value = conc(time, ifelse(dose == "5 mg/kg", 5, 10)) * exp(rnorm(n(), 0, 0.16)))
s5 <- d5 %>% group_by(dose, time) %>% summarise(mean = mean(value), sd = sd(value), .groups = "drop") %>%
  mutate(dose = factor(dose, c("5 mg/kg", "10 mg/kg")))
cols5 <- pub_palette(levels(s5$dose), c("#0072B2", "#D55E00"))
p05 <- ggplot(s5, aes(time, mean, color = dose, shape = dose)) +
  geom_hline(yintercept = 10, linetype = "dashed", linewidth = 0.3, color = "grey45") +
  annotate("text", x = 24, y = 10, label = "LLOQ", hjust = 1, vjust = -0.6, size = 2.4, color = "grey35") +
  geom_errorbar(aes(ymin = pmax(mean - sd, mean / 1.6), ymax = mean + sd), width = 0.5, linewidth = 0.4) +
  geom_line(linewidth = 0.5) + geom_point(size = 1.8, fill = "white", stroke = 0.6) +
  scale_color_manual(values = cols5) + scale_shape_manual(values = c(`5 mg/kg` = 21, `10 mg/kg` = 24)) +
  scale_x_continuous(breaks = c(0, 4, 8, 12, 16, 20, 24), limits = c(0, 24.5), expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_log10(breaks = c(10, 100, 1000), labels = label_comma(), limits = c(5, 3000)) +
  annotation_logticks(sides = "l", linewidth = 0.25, short = grid::unit(0.5, "mm"), mid = grid::unit(0.9, "mm"), long = grid::unit(1.3, "mm")) +
  labs(x = "Time after dose (h)", y = "Plasma concentration (ng/mL)", color = NULL, shape = NULL) +
  theme_pub(grid = "y")
preview(p05, "05_pharmacokinetics_semilog", 85, 75)

# ===========================================================================
# 06  Dose-response: 4-parameter logistic fits with EC50
# ===========================================================================
conc6 <- 10^seq(-3, 2, length.out = 8)
truth <- tibble(compound = c("Compound A", "Compound B", "Compound C"),
                bottom = c(3, 5, 4), top = c(100, 98, 86), ec50 = c(0.05, 0.8, 12), hill = c(1.2, 0.9, 1.5))
d6 <- expand_grid(truth, conc = conc6, rep = 1:3) %>%
  mutate(response = bottom + (top - bottom) / (1 + (ec50 / conc)^hill) + rnorm(n(), 0, 3.5)) %>%
  select(compound, conc, rep, response)
fits6 <- lapply(split(d6, d6$compound), function(z) nls(response ~ SSfpl(log10(conc), A, B, xmid, scal), data = z))
ec6 <- vapply(fits6, function(f) 10^coef(f)[["xmid"]], numeric(1))
grid6 <- do.call(rbind, lapply(names(fits6), function(nm) {
  lc <- seq(-3, 2, length.out = 200)
  tibble(compound = nm, conc = 10^lc, response = predict(fits6[[nm]], newdata = data.frame(conc = 10^lc)))
}))
s6 <- summarise_mean_error(d6, "response", c("compound", "conc"), "sd")
lab6 <- sprintf("%s  (EC50 = %s \u00b5M)", names(ec6), trimws(formatC(ec6, digits = 2, format = "fg")))
names(lab6) <- names(ec6)
cols6 <- pub_palette(names(ec6))
p06 <- ggplot() +
  geom_hline(yintercept = c(0, 100), linewidth = 0.25, color = "grey70") +
  geom_line(data = grid6, aes(conc, response, color = compound), linewidth = 0.7) +
  geom_errorbar(data = s6, aes(conc, ymin = lower, ymax = upper, color = compound), width = 0.07, linewidth = 0.35) +
  geom_point(data = s6, aes(conc, mean, color = compound, shape = compound), size = 1.8) +
  scale_color_manual(values = cols6, labels = lab6) + scale_shape_manual(values = pub_shapes(names(ec6)), labels = lab6) +
  scale_x_log10(breaks = 10^(-3:2), labels = label_log(digits = 1)) +
  annotation_logticks(sides = "b", linewidth = 0.25, short = grid::unit(0.5, "mm"), mid = grid::unit(0.9, "mm"), long = grid::unit(1.3, "mm")) +
  scale_y_continuous(breaks = seq(0, 100, 25)) +
  guides(color = guide_legend(nrow = 3), shape = guide_legend(nrow = 3)) +
  labs(x = "Concentration (\u00b5M)", y = "Response (% of control)", color = NULL, shape = NULL) +
  theme_pub(grid = "none", legend.justification = "left")
preview(p06, "06_dose_response_4pl", 90, 85)

# ===========================================================================
# 07  Calibration curve with confidence and prediction bands + residuals
# ===========================================================================
d7 <- tibble(conc = rep(c(2, 4, 8, 12, 16, 20), each = 3)) %>% mutate(absorbance = 0.006 + 0.0485 * conc + rnorm(n(), 0, 0.014))
write_csv(d7, file.path(DATA_OUT, "calibration.csv"))
fit7 <- lm(absorbance ~ conc, data = d7)
nd7 <- tibble(conc = seq(0, 22, length.out = 100))
ci7 <- cbind(nd7, predict(fit7, nd7, interval = "confidence"))
pi7 <- cbind(nd7, predict(fit7, nd7, interval = "prediction"))
eq7 <- sprintf("italic(y) == %.4f * italic(x) + %.4f", coef(fit7)[2], coef(fit7)[1])
r2_7 <- sprintf("italic(R)^2 == %.4f", summary(fit7)$r.squared)
p07a <- ggplot() +
  geom_ribbon(data = pi7, aes(conc, ymin = lwr, ymax = upr), fill = "grey85") +
  geom_ribbon(data = ci7, aes(conc, ymin = lwr, ymax = upr), fill = pub_colors[1], alpha = 0.3) +
  geom_line(data = ci7, aes(conc, fit), color = pub_colors[1], linewidth = 0.6) +
  geom_point(data = d7, aes(conc, absorbance), size = 1.5) +
  annotate("text", x = -Inf, y = Inf, label = eq7, parse = TRUE, hjust = -0.08, vjust = 1.6, size = 2.8) +
  annotate("text", x = -Inf, y = Inf, label = r2_7, parse = TRUE, hjust = -0.1, vjust = 3.6, size = 2.8) +
  annotate("text", x = Inf, y = -Inf, label = "Bands: 95% confidence (blue), 95% prediction (grey)", hjust = 1.02, vjust = -1.2, size = 2.1, color = "grey35") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.02))) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.02))) +
  labs(x = expression("Concentration (" * mu * "g mL"^{-1} * ")"), y = "Absorbance (a.u.)") +
  theme_pub(grid = "xy")
p07b <- ggplot(tibble(fitted = fitted(fit7), resid = residuals(fit7)), aes(fitted, resid)) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_point(size = 1.5) +
  labs(x = "Fitted absorbance", y = "Residual") +
  theme_pub(grid = "xy")
preview(p07a + p07b + plot_annotation(tag_levels = "A"), "07_calibration_bands_residuals", 175, 70)

# ===========================================================================
# 08  Bland-Altman agreement
# ===========================================================================
truth8 <- runif(80, 20, 140)
d8 <- tibble(a = truth8 + rnorm(80, 0, 4), b = truth8 + 2.1 + rnorm(80, 0, 5)) %>%
  mutate(mean = (a + b) / 2, diff = b - a)
bias <- mean(d8$diff); sdd <- sd(d8$diff); loa <- bias + c(-1.96, 1.96) * sdd
se_loa <- sqrt(3 * sdd^2 / nrow(d8)); tcrit <- qt(0.975, nrow(d8) - 1)
p08 <- ggplot(d8, aes(mean, diff)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = loa[1] - tcrit * se_loa, ymax = loa[1] + tcrit * se_loa, fill = "grey85") +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = loa[2] - tcrit * se_loa, ymax = loa[2] + tcrit * se_loa, fill = "grey85") +
  geom_hline(yintercept = bias, color = pub_colors[1], linewidth = 0.6) +
  geom_hline(yintercept = loa, linetype = "dashed", linewidth = 0.4) +
  geom_point(size = 1.4, alpha = 0.8) +
  annotate("text", x = Inf, y = bias, label = sprintf("Bias
%.1f", bias), hjust = -0.12, size = 2.5, color = pub_colors[1], lineheight = 0.9) +
  annotate("text", x = Inf, y = loa[2], label = sprintf("+1.96 SD
%.1f", loa[2]), hjust = -0.12, size = 2.5, lineheight = 0.9) +
  annotate("text", x = Inf, y = loa[1], label = sprintf("\u22121.96 SD
%.1f", loa[1]), hjust = -0.12, size = 2.5, lineheight = 0.9) +
  scale_x_continuous(limits = c(15, 148), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(x = "Mean of the two methods (mg/L)", y = "Difference, B \u2212 A (mg/L)") +
  theme_pub(grid = "none", plot.margin = margin(4, 40, 4, 4))
preview(p08, "08_bland_altman", 85, 70)

# ===========================================================================
# 09  ROC curves with AUC (95% CI)
# ===========================================================================
if (requireNamespace("pROC", quietly = TRUE)) {
  n9 <- 140; y9 <- rbinom(n9, 1, 0.45)
  d9 <- tibble(status = y9, `Marker A` = rnorm(n9, y9 * 1.1), `Marker B` = rnorm(n9, y9 * 0.6), Combined = NA_real_)
  d9$Combined <- d9$`Marker A` + 0.7 * d9$`Marker B` + rnorm(n9, 0, 0.3)
  rocs <- lapply(c("Marker A", "Marker B", "Combined"), function(m) pROC::roc(d9$status, d9[[m]], quiet = TRUE, direction = "<"))
  names(rocs) <- c("Marker A", "Marker B", "Combined")
  curve9 <- bind_rows(lapply(names(rocs), function(m) {
    co <- pROC::coords(rocs[[m]], "all", ret = c("specificity", "sensitivity"), transpose = FALSE)
    tibble(marker = m, fpr = 1 - co$specificity, tpr = co$sensitivity)
  })) %>% mutate(marker = factor(marker, names(rocs)))
  auc_lab <- vapply(names(rocs), function(m) {
    ci <- pROC::ci.auc(rocs[[m]])
    sprintf("%s: AUC %.2f (%.2f\u2013%.2f)", m, ci[2], ci[1], ci[3])
  }, "")
  cols9 <- pub_palette(names(rocs))
  p09 <- ggplot(curve9, aes(fpr, tpr, color = marker)) +
    geom_abline(linetype = "dashed", color = "grey60", linewidth = 0.4) +
    geom_step(linewidth = 0.7, direction = "hv") +
    scale_color_manual(values = cols9, labels = auc_lab[names(cols9)]) +
    scale_x_continuous(breaks = seq(0, 1, 0.25), expand = c(0.01, 0.01)) +
    scale_y_continuous(breaks = seq(0, 1, 0.25), expand = c(0.01, 0.01)) +
    coord_equal() +
    guides(color = guide_legend(nrow = 3)) +
    labs(x = "1 \u2212 Specificity", y = "Sensitivity", color = NULL) +
    theme_pub(grid = "xy", legend.justification = "left")
  preview(p09, "09_roc_curves", 85, 95)
}

# ===========================================================================
# 10  Kaplan-Meier with number-at-risk table
# ===========================================================================
if (requireNamespace("survival", quietly = TRUE)) {
  d10 <- tibble(arm = rep(c("Placebo", "Treatment"), each = 70),
                time = c(rexp(70, 1 / 13), rexp(70, 1 / 24)), status = rbinom(140, 1, 0.82)) %>%
    mutate(status = ifelse(time > 36, 0, status), time = pmin(time, 36))
  fit10 <- survival::survfit(survival::Surv(time, status) ~ arm, data = d10)
  strata <- sub("arm=", "", names(fit10$strata))
  km <- tibble(time = fit10$time, surv = fit10$surv, lower = fit10$lower, upper = fit10$upper,
               n.censor = fit10$n.censor, arm = rep(strata, fit10$strata))
  km <- bind_rows(tibble(arm = strata, time = 0, surv = 1, lower = 1, upper = 1, n.censor = 0), km) %>% arrange(arm, time)
  lr <- survival::survdiff(survival::Surv(time, status) ~ arm, data = d10)
  lr_p <- pchisq(lr$chisq, length(lr$n) - 1, lower.tail = FALSE)
  cox <- summary(survival::coxph(survival::Surv(time, status) ~ arm, data = d10))
  hr_txt <- sprintf("HR %.2f (%.2f\u2013%.2f)", cox$conf.int[1, 1], cox$conf.int[1, 3], cox$conf.int[1, 4])
  cols10 <- pub_palette(c("Placebo", "Treatment"), c("#4D4D4D", "#D55E00"))
  brk <- seq(0, 36, 6)
  p10a <- ggplot(km, aes(time, surv, color = arm)) +
    geom_step(linewidth = 0.7) +
    geom_point(data = filter(km, n.censor > 0), shape = 3, size = 1.3, show.legend = FALSE) +
    annotate("text", x = 0.8, y = 0.1, hjust = 0, size = 2.6, label = paste0(hr_txt, "\nLog-rank ", format_p(lr_p))) +
    scale_color_manual(values = cols10) +
    scale_x_continuous(breaks = brk, limits = c(0, 36), expand = expansion(add = c(1.6, 1.2))) +
    scale_y_continuous(labels = label_percent(), limits = c(0, 1), expand = expansion(mult = c(0, 0.02))) +
    labs(x = NULL, y = "Progression-free survival", color = NULL) +
    theme_pub(legend = "inside", legend.position.inside = c(0.84, 0.9), axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.line.x = element_blank())
  rk <- summary(fit10, times = brk, extend = TRUE)
  risk <- tibble(time = rk$time, n = rk$n.risk, arm = sub("arm=", "", as.character(rk$strata)))
  p10b <- ggplot(risk, aes(time, factor(arm, c("Treatment", "Placebo")), label = n, color = arm)) +
    geom_text(size = 2.6, show.legend = FALSE) +
    scale_color_manual(values = cols10) +
    scale_x_continuous(breaks = brk, limits = c(0, 36), expand = expansion(add = c(1.6, 1.2))) +
    labs(x = "Time since randomisation (months)", y = NULL, title = "Number at risk") +
    theme_pub(grid = "none", plot.title = element_text(size = 6.5, face = "bold"), axis.line.y = element_blank(), axis.ticks.y = element_blank())
  preview(p10a / p10b + plot_layout(heights = c(4.2, 1)), "10_kaplan_meier_risk_table", 90, 90)
}

# ===========================================================================
# 11  Volcano with labelled hits
# ===========================================================================
n11 <- 3500
d11 <- tibble(gene = paste0("GENE", seq_len(n11)), log2fc = rnorm(n11, 0, 0.9)) %>%
  mutate(p = 10^-(abs(log2fc)^1.3 * runif(n11, 0.4, 3.2) * 1.4 + rexp(n11, 4)), padj = p.adjust(p, "BH"),
         class = case_when(padj < 0.05 & log2fc >= 1 ~ "Up", padj < 0.05 & log2fc <= -1 ~ "Down", TRUE ~ "n.s."))
write_csv(d11, file.path(DATA_OUT, "volcano.csv"))
top11 <- d11 %>% filter(class != "n.s.") %>% group_by(class) %>% slice_min(padj, n = 5) %>% ungroup()
cnt <- table(factor(d11$class, c("Down", "n.s.", "Up")))
p11 <- ggplot(d11, aes(log2fc, -log10(padj), color = class)) +
  geom_point(size = 0.55, alpha = 0.65, stroke = 0) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.3, color = "grey45") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.3, color = "grey45") +
  scale_color_manual(values = c(Up = "#D55E00", Down = "#0072B2", `n.s.` = "grey78")) +
  annotate("text", x = -Inf, y = -Inf, label = paste0("Down: ", cnt[["Down"]]), hjust = -0.15, vjust = -0.9, size = 2.7, color = "#0072B2", fontface = "bold") +
  annotate("text", x = Inf, y = -Inf, label = paste0("Up: ", cnt[["Up"]]), hjust = 1.15, vjust = -0.9, size = 2.7, color = "#D55E00", fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0.01, 0.1))) +
  labs(x = expression(log[2] * " fold change"), y = expression(-log[10] * " adjusted " * italic(p)), color = NULL) +
  theme_pub(grid = "none", legend = "none")
if (requireNamespace("ggrepel", quietly = TRUE)) {
  p11 <- p11 + ggrepel::geom_text_repel(data = top11, aes(label = gene), size = 2.1, family = pub_family(), color = "black",
                                        min.segment.length = 0, segment.size = 0.2, box.padding = 0.25, max.overlaps = Inf, seed = 4)
}
preview(p11, "11_volcano_labelled", 85, 80)

# ===========================================================================
# 12  Forest plot (random-effects meta-analysis layout)
# ===========================================================================
d12 <- tibble(study = c("Almeida 2018", "Becker 2019", "Chen 2020", "Duarte 2021", "Eriksson 2021", "Farah 2022", "Gupta 2023", "Hansen 2023"),
              n = c(120, 340, 85, 210, 150, 410, 95, 260)) %>%
  mutate(est = c(0.78, 0.66, 0.92, 0.71, 0.60, 0.74, 0.55, 0.81), se = 0.5 / sqrt(n) * 3,
         lower = exp(log(est) - 1.96 * se), upper = exp(log(est) + 1.96 * se), w = 1 / se^2, type = "Study")
pooled <- d12 %>% summarise(lest = sum(w * log(est)) / sum(w), lse = sqrt(1 / sum(w))) %>%
  transmute(study = "Pooled (random effects)", est = exp(lest), lower = exp(lest - 1.96 * lse), upper = exp(lest + 1.96 * lse),
            n = sum(d12$n), w = NA_real_, type = "Pooled")
d12 <- bind_rows(d12, pooled) %>%
  mutate(study = factor(study, rev(study)), label = sprintf("%.2f (%.2f\u2013%.2f)", est, lower, upper))
p12a <- ggplot(d12, aes(est, study)) +
  geom_vline(xintercept = 1, linetype = "dashed", linewidth = 0.3) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y", width = 0.22, linewidth = 0.4) +
  geom_point(data = filter(d12, type == "Study"), aes(size = w), shape = 15) +
  geom_point(data = filter(d12, type == "Pooled"), shape = 18, size = 4, color = "#D55E00") +
  scale_size_area(max_size = 3, guide = "none") +
  scale_x_log10(breaks = c(0.4, 0.6, 0.8, 1, 1.25), labels = c("0.4", "0.6", "0.8", "1.0", "1.25")) +
  labs(x = "Hazard ratio (95% CI), log scale
\u2190 favours treatment          favours control \u2192", y = NULL) +
  theme_pub(grid = "none")
p12b <- ggplot(d12, aes(0, study)) +
  geom_text(aes(label = label), hjust = 0, size = 2.5, fontface = ifelse(d12$type == "Pooled", "bold", "plain")) +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  labs(title = "HR (95% CI)") +
  theme_void(base_family = pub_family()) + theme(plot.title = element_text(size = 6.5, face = "bold", hjust = 0))
preview(p12a + p12b + plot_layout(widths = c(3, 1.25)), "12_forest_meta_analysis", 120, 70)

# ===========================================================================
# 13  Correlation matrix: circle size = |r|, colour = r, stars = significance
# ===========================================================================
n13 <- 90
X13 <- tibble(BMI = rnorm(n13)) %>%
  mutate(FBS = 0.45 * BMI + rnorm(n13, 0, 0.9), Insulin = 0.6 * BMI + 0.3 * FBS + rnorm(n13, 0, 0.8),
         `HOMA-IR` = 0.6 * Insulin + 0.5 * FBS + rnorm(n13, 0, 0.5), TG = 0.45 * BMI + 0.3 * Insulin + rnorm(n13, 0, 0.9),
         HDL = -0.5 * TG - 0.25 * BMI + rnorm(n13, 0, 0.8), LDL = 0.3 * TG + rnorm(n13, 0, 1),
         `hs-CRP` = 0.5 * BMI + rnorm(n13, 0, 0.9))
vars13 <- names(X13)
cm13 <- cor(X13, method = "spearman")
pm13 <- outer(vars13, vars13, Vectorize(function(a, b) if (a == b) NA else suppressWarnings(cor.test(X13[[a]], X13[[b]], method = "spearman")$p.value)))
long13 <- expand_grid(i = seq_along(vars13), j = seq_along(vars13)) %>%
  filter(i > j) %>%
  mutate(a = factor(vars13[j], vars13), b = factor(vars13[i], rev(vars13)),
         r = cm13[cbind(i, j)], p = pm13[cbind(i, j)],
         stars = case_when(p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ ""))
p13 <- ggplot(long13, aes(a, b)) +
  geom_point(aes(size = abs(r), fill = r), shape = 21, color = "grey25", stroke = 0.25) +
  geom_text(aes(label = stars), size = 2.6, vjust = 0.75, color = "black") +
  scale_size_area(max_size = 7.5, limits = c(0, 1), guide = "none") +
  scale_fill_pub_div(limits = c(-1, 1), breaks = c(-1, -0.5, 0, 0.5, 1), name = "Spearman \u03c1",
                     guide = guide_colourbar(barheight = unit(28, "mm"), barwidth = unit(2.5, "mm"), ticks.colour = "black")) +
  scale_x_discrete(drop = FALSE, limits = vars13[-length(vars13)]) +
  scale_y_discrete(drop = FALSE, limits = rev(vars13[-1])) +
  coord_equal() +
  labs(x = NULL, y = NULL) +
  theme_pub(grid = "xy", legend = "right", axis.text.x = element_text(angle = 40, hjust = 1), axis.line = element_blank(),
            axis.ticks = element_blank(), panel.grid.major = element_line(color = "grey92", linewidth = 0.25))
preview(p13, "13_correlation_matrix_circles", 95, 82)

# ===========================================================================
# 14  Clustered heatmap with group annotation bar
# ===========================================================================
n_genes <- 28; n_samp <- 16
grp14 <- rep(c("Control", "Treated"), each = n_samp / 2)
m14 <- matrix(rnorm(n_genes * n_samp), n_genes, n_samp,
              dimnames = list(c("Il6", "Tnf", "Il1b", "Ccl2", "Nfkb1", "Cxcl10", "Ptgs2", "Icam1", "Vcam1", "Mmp9", "Socs3", "Stat3", "Jun", "Fos",
                                "Adipoq", "Pparg", "Cebpa", "Lpl", "Fabp4", "Cd36", "Ppargc1a", "Ucp1", "Cpt1a", "Acox1", "Srebf1", "Fasn", "Acaca", "Scd1"),
                              paste0("S", sprintf("%02d", seq_len(n_samp)))))
m14[1:14, grp14 == "Treated"] <- m14[1:14, grp14 == "Treated"] - 1.6
m14[15:24, grp14 == "Treated"] <- m14[15:24, grp14 == "Treated"] + 1.5
m14[25:28, grp14 == "Treated"] <- m14[25:28, grp14 == "Treated"] - 1.0
z14 <- t(scale(t(m14)))
row_ord <- hclust(dist(z14), "ward.D2")$order
col_ord <- hclust(dist(t(z14)), "ward.D2")$order
long14 <- as_tibble(z14, rownames = "gene") %>% pivot_longer(-gene, names_to = "sample", values_to = "z") %>%
  mutate(gene = factor(gene, rownames(z14)[row_ord]), sample = factor(sample, colnames(z14)[col_ord]))
ann14 <- tibble(sample = factor(colnames(z14), colnames(z14)[col_ord]), Group = factor(grp14, c("Control", "Treated")))
heat <- ggplot(long14, aes(sample, gene, fill = z)) +
  geom_tile(color = "white", linewidth = 0.25) +
  scale_fill_pub_div(limits = c(-2.5, 2.5), oob = squish, name = "Row z-score",
                     guide = guide_colourbar(barheight = unit(24, "mm"), barwidth = unit(2.5, "mm"), ticks.colour = "black")) +
  scale_y_discrete(position = "right", expand = c(0, 0)) + scale_x_discrete(expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = NULL) +
  theme_pub(grid = "none", legend = "right", axis.line = element_blank(), axis.ticks = element_blank(),
            axis.text.x = element_blank(), axis.text.y = element_text(face = "italic", size = 6.5))
annbar <- ggplot(ann14, aes(sample, 1, fill = Group)) +
  geom_tile(color = "white", linewidth = 0.25, height = 1) +
  scale_fill_manual(values = c(Control = "#7F7F7F", Treated = "#D55E00")) +
  scale_x_discrete(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0)) +
  theme_void(base_family = pub_family(), base_size = 8) + theme(legend.position = "right", legend.title = element_text(face = "bold"))
preview(annbar / heat + plot_layout(heights = c(1, 22), guides = "collect"), "14_clustered_heatmap_annotation", 100, 105)

# ===========================================================================
# 15  PCA biplot: scores, 95% ellipses and loading arrows
# ===========================================================================
vars15 <- c("Size", "PDI", "Zeta", "EE", "Release 8 h", "Hardness", "Viscosity", "Adhesion")
base15 <- matrix(rnorm(8 * 8), 8, 8)
d15 <- bind_rows(lapply(1:3, function(k) {
  shift <- list(c(1.4, 0.4, -1.1, 1.2, -0.6, 0.3, 0.8, 0.2), c(-0.8, 0.7, 0.9, -0.5, 1.2, -0.8, -0.2, 0.9), c(-0.3, -1.0, 0.2, -0.6, -0.9, 1.1, -0.9, -1.0))[[k]]
  as_tibble(matrix(rnorm(14 * 8, rep(shift, each = 14), 0.7), 14, 8, dimnames = list(NULL, vars15))) %>%
    mutate(group = c("F1 (liposome)", "F2 (niosome)", "F3 (hydrogel)")[k])
}))
pc15 <- prcomp(select(d15, all_of(vars15)), scale. = TRUE)
ve15 <- summary(pc15)$importance[2, 1:2] * 100
sc15 <- bind_cols(select(d15, group), as_tibble(pc15$x[, 1:2]))
ld15 <- as_tibble(pc15$rotation[, 1:2], rownames = "var") %>%
  mutate(across(c(PC1, PC2), ~ .x * max(abs(sc15[c("PC1", "PC2")])) * 0.85))
cols15 <- pub_palette(unique(sc15$group))
p15 <- ggplot(sc15, aes(PC1, PC2)) +
  geom_hline(yintercept = 0, linewidth = 0.25, color = "grey70") + geom_vline(xintercept = 0, linewidth = 0.25, color = "grey70") +
  stat_ellipse(aes(fill = group, color = group), geom = "polygon", level = 0.95, alpha = 0.12, linewidth = 0.35) +
  geom_point(aes(color = group, shape = group), size = 1.8) +
  geom_segment(data = ld15, aes(x = 0, y = 0, xend = PC1, yend = PC2), inherit.aes = FALSE,
               arrow = arrow(length = unit(1.6, "mm"), type = "closed"), linewidth = 0.3, color = "grey25") +
  ggrepel::geom_text_repel(data = ld15, aes(PC1, PC2, label = var), inherit.aes = FALSE, size = 2.3, family = pub_family(),
                           color = "grey15", segment.color = NA, box.padding = 0.2, seed = 3) +
  scale_color_manual(values = cols15) + scale_fill_manual(values = cols15) + scale_shape_manual(values = pub_shapes(names(cols15))) +
  coord_equal() +
  labs(x = sprintf("PC1 (%.1f%%)", ve15[1]), y = sprintf("PC2 (%.1f%%)", ve15[2]), color = NULL, fill = NULL, shape = NULL) +
  theme_pub(grid = "none")
preview(p15, "15_pca_biplot", 90, 85)

# ===========================================================================
# 16  Ridgeline: particle-size distributions with median lines
# ===========================================================================
if (requireNamespace("ggridges", quietly = TRUE)) {
  f16 <- c("F1", "F2", "F3", "F4", "F5")
  mu16 <- c(4.9, 5.1, 5.35, 5.55, 5.9); sg16 <- c(0.20, 0.17, 0.24, 0.18, 0.26)
  d16 <- bind_rows(lapply(seq_along(f16), function(i) tibble(formulation = f16[i], size = rlnorm(600, mu16[i], sg16[i])))) %>%
    mutate(formulation = factor(formulation, rev(f16)))
  cols16 <- pub_palette(f16)
  p16 <- ggplot(d16, aes(size, formulation, fill = formulation)) +
    ggridges::geom_density_ridges(scale = 1.5, rel_min_height = 0.005, quantile_lines = TRUE, quantiles = 2,
                                  alpha = 0.8, color = "white", linewidth = 0.4, vline_color = "white") +
    scale_fill_manual(values = cols16) +
    scale_x_continuous(breaks = seq(100, 700, 100), expand = expansion(mult = c(0, 0.02))) +
    scale_y_discrete(expand = expansion(mult = c(0.02, 0.35))) +
    coord_cartesian(xlim = c(40, 700)) +
    labs(x = "Hydrodynamic diameter (nm)", y = NULL) +
    theme_pub(grid = "x", legend = "none")
  preview(p16, "16_ridgeline_size_distributions", 85, 80)
}

# ===========================================================================
# 17  Response-surface contour from a central composite design
# ===========================================================================
ccd <- tibble(c1 = c(-1, 1, -1, 1, -1.414, 1.414, 0, 0, 0, 0, 0), c2 = c(-1, -1, 1, 1, 0, 0, -1.414, 1.414, 0, 0, 0)) %>%
  mutate(span = 100 + 35 * c1, time = 6 + 2.8 * c2,
         EE = 71 + 7.5 * c1 + 3.2 * c2 - 5.6 * c1^2 - 4.1 * c2^2 + 1.8 * c1 * c2 + rnorm(n(), 0, 0.9))
fit17 <- lm(EE ~ c1 + c2 + I(c1^2) + I(c2^2) + c1:c2, data = ccd)
g17 <- expand_grid(c1 = seq(-1.6, 1.6, length.out = 160), c2 = seq(-1.6, 1.6, length.out = 160)) %>%
  mutate(span = 100 + 35 * c1, time = 6 + 2.8 * c2, EE = predict(fit17, newdata = tibble(c1 = c1, c2 = c2)))
opt17 <- g17[which.max(g17$EE), ]
p17 <- ggplot(g17, aes(span, time)) +
  geom_contour_filled(aes(z = EE), bins = 10) +
  geom_contour(aes(z = EE), bins = 10, color = "white", linewidth = 0.2, alpha = 0.7) +
  geom_point(data = ccd, shape = 21, fill = "white", color = "black", size = 1.8, stroke = 0.5) +
  geom_point(data = opt17, shape = 8, size = 3, color = "white", stroke = 0.7) +
  annotate("label", x = Inf, y = -Inf, hjust = 1.04, vjust = -0.3, label = sprintf("Optimum (star): %.0f mg, %.1f min\nEE = %.1f%%", opt17$span, opt17$time, opt17$EE),
           size = 2.2, family = pub_family(), fill = alpha("white", 0.92), lineheight = 0.95) +
  scale_fill_viridis_d(option = "D", name = "EE (%)") +
  scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0)) +
  labs(x = "Polymer (mg)", y = "Sonication time (min)") +
  theme_pub(grid = "none", legend = "right", legend.key.size = unit(3.2, "mm"))
preview(p17, "17_response_surface_contour", 100, 80)

# ===========================================================================
# 18  100% stacked bars with percentage labels
# ===========================================================================
sev <- c("Grade 1", "Grade 2", "Grade 3", "Grade 4")
d18 <- tibble(arm = rep(c("Placebo", "Low dose", "High dose"), each = 4), grade = factor(rep(sev, 3), sev),
              n = c(31, 18, 7, 2, 28, 22, 11, 3, 20, 25, 18, 7)) %>%
  group_by(arm) %>% mutate(total = sum(n), pct = n / total, arm_lab = paste0(arm, "\n(n = ", total, ")")) %>% ungroup() %>%
  mutate(arm_lab = factor(arm_lab, unique(arm_lab)))
cols18 <- pub_ordered(sev, "#DCE9F5", "#08306B")
p18 <- ggplot(d18, aes(arm_lab, pct, fill = grade)) +
  geom_col(position = position_stack(reverse = TRUE), width = 0.7, color = "white", linewidth = 0.3) +
  geom_text(aes(label = ifelse(pct >= 0.06, percent(pct, accuracy = 1), ""), color = grade),
            position = position_stack(vjust = 0.5, reverse = TRUE), size = 2.5, show.legend = FALSE) +
  scale_fill_manual(values = cols18) + scale_color_manual(values = c("black", "black", "white", "white")) +
  scale_y_continuous(labels = label_percent(), expand = expansion(mult = c(0, 0.02))) +
  labs(x = NULL, y = "Patients with adverse events", fill = NULL) +
  theme_pub(grid = "none")
preview(p18, "18_stacked_percent_bars", 85, 75)

# ===========================================================================
# 19  Dumbbell chart: baseline vs follow-up per site
# ===========================================================================
d19 <- tibble(site = paste("Site", LETTERS[1:12]), Baseline = rnorm(12, 8.6, 0.5)) %>%
  mutate(`Week 12` = Baseline - runif(12, 0.3, 1.7)) %>% arrange(Baseline - `Week 12`) %>% mutate(site = factor(site, site))
cols19 <- c(Baseline = "#7F7F7F", `Week 12` = "#0072B2")
p19 <- ggplot(d19) +
  geom_segment(aes(x = `Week 12`, xend = Baseline, y = site, yend = site), color = "grey70", linewidth = 0.9, lineend = "round") +
  geom_point(aes(Baseline, site, color = "Baseline"), size = 2.4) +
  geom_point(aes(`Week 12`, site, color = "Week 12"), size = 2.4) +
  scale_color_manual(values = cols19, breaks = names(cols19)) +
  scale_x_continuous(breaks = seq(6.5, 9.5, 0.5)) +
  labs(x = "HbA1c (%)", y = NULL, color = NULL) +
  theme_pub(grid = "x")
preview(p19, "19_dumbbell_baseline_followup", 85, 85)

# ===========================================================================
# 20  Waterfall: best percentage change from baseline per patient
# ===========================================================================
d20 <- tibble(change = sort(c(rnorm(14, -45, 18), rnorm(14, -5, 14), rnorm(10, 35, 18)), decreasing = TRUE)) %>%
  mutate(id = row_number(), response = case_when(change >= 20 ~ "Progressive disease", change <= -30 ~ "Partial response", TRUE ~ "Stable disease"),
         response = factor(response, c("Partial response", "Stable disease", "Progressive disease")))
p20 <- ggplot(d20, aes(id, change, fill = response)) +
  geom_col(width = 0.8) +
  geom_hline(yintercept = c(20, -30), linetype = "dashed", linewidth = 0.3) +
  annotate("text", x = nrow(d20) + 0.4, y = 20, label = "+20%", hjust = 1, vjust = -0.5, size = 2.3) +
  annotate("text", x = 0.6, y = -30, label = "\u221230%", hjust = 0, vjust = 1.4, size = 2.3) +
  scale_fill_manual(values = c(`Partial response` = "#0072B2", `Stable disease` = "#9E9E9E", `Progressive disease` = "#D55E00")) +
  scale_x_continuous(expand = expansion(mult = 0.02)) +
  scale_y_continuous(labels = function(x) paste0(x, "%"), breaks = seq(-80, 80, 20)) +
  labs(x = "Individual patients", y = "Best change in tumour size", fill = NULL) +
  theme_pub(grid = "y", axis.text.x = element_blank(), axis.ticks.x = element_blank())
preview(p20, "20_waterfall_response", 120, 70)

# ===========================================================================
# 21  Rheology: storage (G') and loss (G'') moduli, log-log
# ===========================================================================
freq <- 10^seq(-1, 2, length.out = 24)
d21 <- expand_grid(formulation = c("Gel A", "Gel B", "Gel C", "Gel D"), freq = freq) %>%
  mutate(base = c("Gel A" = 900, "Gel B" = 520, "Gel C" = 260, "Gel D" = 110)[formulation],
         `G'` = base * freq^0.11 * exp(rnorm(n(), 0, 0.012)), `G''` = base * 0.27 * freq^0.2 * exp(rnorm(n(), 0, 0.012))) %>%
  pivot_longer(c(`G'`, `G''`), names_to = "modulus", values_to = "value")
cols21 <- pub_palette(unique(d21$formulation))
p21 <- ggplot(d21, aes(freq, value, color = formulation, linetype = modulus, shape = modulus, group = interaction(formulation, modulus))) +
  geom_line(linewidth = 0.5) + geom_point(size = 1.1) +
  scale_x_log10(labels = label_number(big.mark = ",", drop0trailing = TRUE)) +
  scale_y_log10(labels = label_number(big.mark = ",", drop0trailing = TRUE)) +
  annotation_logticks(sides = "bl", linewidth = 0.25, short = grid::unit(0.5, "mm"), mid = grid::unit(0.9, "mm"), long = grid::unit(1.3, "mm")) +
  scale_color_manual(values = cols21) +
  scale_linetype_manual(values = c("G'" = "solid", "G''" = "dashed")) +
  scale_shape_manual(values = c("G'" = 16, "G''" = 1)) +
  guides(color = guide_legend(order = 1), linetype = guide_legend(order = 2), shape = guide_legend(order = 2)) +
  labs(x = "Angular frequency (rad/s)", y = "G', G'' (Pa)", color = "Formulation", linetype = NULL, shape = NULL) +
  theme_pub(grid = "none", legend.box = "vertical", legend.spacing.y = grid::unit(0, "pt"))
preview(p21, "21_rheology_loglog_moduli", 90, 80)

# ===========================================================================
# 22  Diffractograms: offset stack with labelled peaks
# ===========================================================================
tth <- seq(5, 60, by = 0.05)
pk <- function(x, c, h, w) h * exp(-((x - c) / w)^2)
d22 <- bind_rows(
  tibble(sample = "Pure drug", x = tth, y = 60 + pk(tth, 12.4, 900, 0.15) + pk(tth, 17.2, 420, 0.16) + pk(tth, 24.1, 650, 0.2) + pk(tth, 27.8, 300, 0.2)),
  tibble(sample = "Physical mixture", x = tth, y = 60 + pk(tth, 12.4, 380, 0.15) + pk(tth, 24.1, 240, 0.2) + pk(tth, 21.5, 230, 1.0)),
  tibble(sample = "Loaded nanoparticles", x = tth, y = 60 + pk(tth, 21.5, 230, 3.0))
) %>% mutate(y = y + rnorm(n(), 0, 11), sample = factor(sample, c("Pure drug", "Physical mixture", "Loaded nanoparticles")))
off <- 1150
d22 <- d22 %>% mutate(yo = y + (as.integer(sample) - 1) * off)
pk22 <- d22 %>% group_by(sample) %>% slice_max(y, n = 1, with_ties = FALSE) %>% ungroup()
cols22 <- pub_palette(levels(d22$sample))
p22 <- ggplot(d22, aes(x, yo, color = sample)) +
  geom_line(linewidth = 0.3) +
  geom_text(data = pk22, aes(label = sprintf("%.1f\u00b0", x)), vjust = -0.7, size = 2.3, color = "black") +
  geom_text(data = d22 %>% group_by(sample) %>% summarise(x = 59, y = min(yo) + 260), aes(x, y, label = sample, color = sample),
            hjust = 1, size = 2.6, fontface = "bold", inherit.aes = FALSE) +
  scale_color_manual(values = cols22) +
  scale_x_continuous(breaks = seq(10, 60, 10), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.07))) +
  labs(x = expression(2 * theta ~ "(degrees)"), y = "Intensity (a.u.)") +
  theme_pub(grid = "none", legend = "none", axis.text.y = element_blank(), axis.ticks.y = element_blank())
preview(p22, "22_xrd_offset_stack", 90, 80)

# ===========================================================================
# 23  Paired before / after with subject lines and group means
# ===========================================================================
d23 <- tibble(subject = rep(1:14, 2), time = factor(rep(c("Before", "After"), each = 14), c("Before", "After")),
              value = c(rnorm(14, 248, 22), rnorm(14, 214, 24)))
tt23 <- t.test(d23$value[d23$time == "Before"], d23$value[d23$time == "After"], paired = TRUE)
cols23 <- pub_palette(levels(d23$time), c("#7F7F7F", "#0072B2"))
p23 <- ggplot(d23, aes(time, value)) +
  geom_line(aes(group = subject), color = "grey70", linewidth = 0.3) +
  geom_point(aes(color = time), size = 1.7, show.legend = FALSE) +
  stat_summary(aes(group = 1), fun = mean, geom = "line", linewidth = 0.9, color = "black") +
  stat_summary(fun = mean, geom = "point", size = 3, shape = 23, fill = "white", color = "black", stroke = 0.8) +
  geom_brackets(tibble(xmin = "Before", xmax = "After", xmin_n = 1, xmax_n = 2, annotations = format_p(tt23$p.value),
                       y_position = max(d23$value) * 1.05, tip = 3)) +
  scale_color_manual(values = cols23) +
  labs(x = NULL, y = "Total cholesterol (mg/dL)") +
  theme_pub(legend = "none")
preview(p23, "23_paired_before_after", 70, 80)

# ===========================================================================
# 24  Multi-panel plate: shared style, panel tags A-D
# ===========================================================================
plate <- (p01 + p04) / (p06 + p11) + plot_annotation(tag_levels = "A")
preview(plate, "24_multipanel_plate", 175, 170)

message("Gallery finished: ", length(list.files(OUT, pattern = "\\.png$")), " figures in ", OUT)
