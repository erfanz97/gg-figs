# Recipes

Short, copy-ready code for each chart type. Every recipe assumes `source("R/gg_pub.R")` (the skill's
`assets/gg_pub.R`). The full, runnable version of each is in `examples/gallery.R` (section number in brackets),
rendered in `examples/gallery/`. All gallery data are simulated.

Sizes are for figures saved at final print size with `save_pub()`; keep `theme_pub(base_size = 7-9)`.
Every recipe works with the rest of ggplot2: add any geom, scale, coord, facet or `theme()` call (see
`ggplot2-reference.md`).

## Contents
- [violin-box-points](#violin-box-points) [01, 02] - raw replicates; raincloud, facets, brackets
- [points-mean-error](#points-mean-error) [03] - small n or when densities are not wanted
- [summary-only-data](#summary-only-data) - only mean/SD/n available
- [bars](#bars) [18] - counts, proportions, one value per group
- [paired-data](#paired-data) [23] - before/after, repeated measures
- [time-course](#time-course) [04] - release, kinetics, growth (always from t = 0)
- [pk-semilog](#pk-semilog) [05] - concentration-time on a log axis
- [dose-response](#dose-response) [06] - 4-parameter logistic fits and EC50
- [scatter-regression](#scatter-regression) [07] - calibration with bands and residuals
- [bland-altman](#bland-altman) [08]
- [roc](#roc) [09]
- [kaplan-meier](#kaplan-meier) [10]
- [volcano](#volcano) [11]
- [forest-plot](#forest-plot) [12]
- [correlation-heatmap](#correlation-heatmap) [13]
- [clustered-heatmap](#clustered-heatmap) [14]
- [pca](#pca) [15]
- [ridgeline](#ridgeline) [16]
- [response-surface](#response-surface) [17]
- [dumbbell](#dumbbell) [19]
- [waterfall](#waterfall) [20]
- [rheology](#rheology) [21]
- [spectra-and-instrument-curves](#spectra-and-instrument-curves) [22]
- [annotations](#annotations)
- [composite-plates](#composite-plates) [24]

---

## violin-box-points
Default for raw replicates (3+ per group): show every observation, summarise with a box, add shape with a violin.
Annotate with **adjusted p-value brackets for significant pairs only, and only when the omnibus test is significant**.
```r
lv <- c("Control", "Vehicle", "Low dose", "High dose")
d$group <- factor(d$group, lv)
st <- compare_groups(d, "value", "group")                       # picks ANOVA/Tukey, Welch/Games-Howell or Kruskal/Dunn
b  <- pairwise_brackets(st$pairwise, d, "group", "value", omnibus_p = st$omnibus$p, vs = "Control")  # drop vs= for all pairs
cols <- pub_palette(lv)
p <- ggplot(d, aes(group, value, fill = group, color = group)) +
  layers_raincloud() +                       # or layers_violin_box() (symmetric violin); both take dodge = for 2 factors
  geom_brackets(b) +                         # NULL (nothing drawn) when no pair is significant
  scale_fill_manual(values = cols) + scale_color_manual(values = cols) +
  scale_x_discrete(labels = function(x) paste0(x, "\n(n = ", table(d$group)[x], ")")) +
  labs(x = NULL, y = "Fasting glucose (mg/dL)") + theme_pub(legend = "none")
save_pub(p, "Figure_02", width = 90, height = 80)
```
- **Facets** [02]: compare within each panel, keep results only if the omnibus test is significant, then
  `pairwise_brackets(pw, d, "group", "value", facet = "week", label = "stars", vs = "Control")` and `facet_wrap(~ week)`.
  Free y scales work (`geom_brackets()` extends each panel).
- `label = "p"` (default, exact value), `"p.adj"`, `"stars"`, `"both"`. Report the post-hoc method in the caption.
- Two crossed factors: dodge (`layers_violin_box(dodge = 0.8)` with `group = interaction(a, b)`) or, with brackets,
  put one factor in facets.
- Few points per group: violin with `trim = TRUE` (the default here) never extends beyond the data; for n < 6 consider
  `layers_points_mean()` and say so.
- Letters (compact letter display) only if the user asks: `cld_letters()` + `annotation_y()` (see [annotations](#annotations)).

## points-mean-error
```r
p <- ggplot(d, aes(genotype, value, color = treatment, shape = treatment)) +
  geom_hline(yintercept = 1, linetype = "dashed", linewidth = 0.3, color = "grey55") +   # reference level
  layers_points_mean(error = "sd", dodge = 0.65) +                                       # "se" and "ci95" also available
  facet_wrap(~ gene, scales = "free_y") +
  scale_color_manual(values = cols) + scale_shape_manual(values = c(Vehicle = 16, Drug = 17)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  labs(x = NULL, y = "Relative mRNA expression", color = NULL, shape = NULL) + theme_pub()
```
State "mean +/- SD, n = 5" in the caption. Add brackets with `pairwise_brackets()` exactly as above.

## summary-only-data
Raw values unavailable (only mean, SD, n): points with error bars. Never invent replicates, violins or boxes; tell the user
the raw values are needed for violin/box plots.
```r
pd <- position_dodge(width = 0.6)
p <- ggplot(s, aes(ratio, mean, color = carrier, shape = carrier)) +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.15, linewidth = 0.4, position = pd) +
  geom_point(size = 2, position = pd) +
  facet_wrap(~ endpoint, scales = "free_y", labeller = as_labeller(c(Size = "Size (nm)", PDI = "PDI", Zeta = "Zeta potential (mV)"))) +
  scale_color_manual(values = pub_palette(s$carrier)) + scale_shape_manual(values = pub_shapes(s$carrier)) +
  labs(x = "Polymer:lipid ratio", y = NULL) + theme_pub()
```
Statistics from a supplied pairwise table can still be shown as brackets with `pairwise_brackets()` (it needs only group names and adjusted p).

## bars
```r
# 100% stacked proportions with labels [18]
cols <- pub_ordered(levels(d$grade), "#DCE9F5", "#08306B")
ggplot(d, aes(arm_lab, pct, fill = grade)) +
  geom_col(position = position_stack(reverse = TRUE), width = 0.7, color = "white", linewidth = 0.3) +
  geom_text(aes(label = ifelse(pct >= 0.06, percent(pct, accuracy = 1), ""), color = grade),
            position = position_stack(vjust = 0.5, reverse = TRUE), size = 2.5, show.legend = FALSE) +
  scale_fill_manual(values = cols) + scale_color_manual(values = c("black", "black", "white", "white")) +
  scale_y_continuous(labels = label_percent(), expand = expansion(mult = c(0, 0.02))) + theme_pub(grid = "none")
```
Single value per group: `geom_col(width = 0.7, color = "black", linewidth = 0.3)` with `expansion(mult = c(0, 0.08))`, no error bars.
Bars always start at zero. Avoid pie charts.

## paired-data
```r
ggplot(d, aes(time, value)) +
  geom_line(aes(group = subject), color = "grey70", linewidth = 0.3) +
  geom_point(aes(color = time), size = 1.7, show.legend = FALSE) +
  stat_summary(aes(group = 1), fun = mean, geom = "line", linewidth = 0.9) +
  stat_summary(fun = mean, geom = "point", size = 3, shape = 23, fill = "white", stroke = 0.8) +
  geom_brackets(tibble(xmin = "Before", xmax = "After", xmin_n = 1, xmax_n = 2,
                       annotations = format_p(tt$p.value), y_position = max(d$value) * 1.05, tip = 3)) +
  theme_pub(legend = "none")
```
Test with `t.test(x_before, x_after, paired = TRUE)` (the formula method does not accept `paired` in R >= 4.4).

## time-course
Always start at the true baseline (add the 0 h point to the data if the protocol had one) and use lines + points, never bars.
```r
s <- summarise_mean_error(d, "value", c("formulation", "time"), "sd")
ends <- s %>% filter(time == max(time)) %>% arrange(mean) %>% mutate(y_lab = spread_labels(mean, gap = 7))
p <- ggplot(s, aes(time, mean, color = formulation, fill = formulation)) +
  geom_ribbon(aes(ymin = pmax(0, lower), ymax = pmin(100, upper)), alpha = 0.15, color = NA) +
  geom_line(linewidth = 0.6) + geom_point(aes(shape = formulation), size = 1.6) +
  geom_text(data = ends, aes(x = max(s$time) + 0.8, y = y_lab, label = formulation), hjust = 0, size = 2.7, fontface = "bold", show.legend = FALSE) +
  scale_color_manual(values = cols) + scale_fill_manual(values = cols) + scale_shape_manual(values = pub_shapes(names(cols))) +
  scale_x_continuous(breaks = c(0, 2, 4, 8, 12, 24), expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_continuous(breaks = seq(0, 100, 25), expand = expansion(mult = c(0, 0.02))) +
  coord_cartesian(ylim = c(0, 100), clip = "off") +                  # labels may sit outside the panel
  labs(x = "Time (h)", y = "Cumulative release (%)") + theme_pub(legend = "none", plot.margin = margin(8, 48, 4, 4))
```
Use error bars (`geom_errorbar(aes(ymin, ymax), width = 0.4)`) instead of a ribbon when few time points; facets
(`facet_wrap(~ factor1)`, color = factor2) when more than 5 series. Kinetic model lines: fit with `nls()` per group and draw
`geom_line(data = predictions)`; report the model and R^2 in the caption.

## pk-semilog
```r
ggplot(s, aes(time, mean, color = dose, shape = dose)) +
  geom_hline(yintercept = 10, linetype = "dashed", linewidth = 0.3, color = "grey45") +   # LLOQ
  geom_errorbar(aes(ymin = pmax(mean - sd, mean / 1.6), ymax = mean + sd), width = 0.5, linewidth = 0.4) +
  geom_line(linewidth = 0.5) + geom_point(size = 1.8, fill = "white", stroke = 0.6) +        # shapes 21/24 for hollow markers
  scale_shape_manual(values = c(`5 mg/kg` = 21, `10 mg/kg` = 24)) +
  scale_y_log10(breaks = c(10, 100, 1000), labels = label_comma(), limits = c(5, 3000)) +
  annotation_logticks(sides = "l", linewidth = 0.25, short = unit(0.5, "mm"), mid = unit(0.9, "mm"), long = unit(1.3, "mm")) +
  theme_pub()
```
Values below the LLOQ are not plotted (or are shown at LLOQ/2 only if the methods say so). Lower error bars that would go
below zero on a log axis are clamped.

## dose-response
```r
fits <- lapply(split(d, d$compound), function(z) nls(response ~ SSfpl(log10(conc), A, B, xmid, scal), data = z))
ec50 <- vapply(fits, function(f) 10^coef(f)[["xmid"]], numeric(1))
grid <- bind_rows(lapply(names(fits), function(nm) { lc <- seq(-3, 2, length.out = 200)
  tibble(compound = nm, conc = 10^lc, response = predict(fits[[nm]], data.frame(conc = 10^lc))) }))
lab <- sprintf("%s  (EC50 = %s µM)", names(ec50), trimws(formatC(ec50, digits = 2, format = "fg"))); names(lab) <- names(ec50)
ggplot() + geom_line(data = grid, aes(conc, response, color = compound), linewidth = 0.7) +
  geom_errorbar(data = s, aes(conc, ymin = lower, ymax = upper, color = compound), width = 0.07) +
  geom_point(data = s, aes(conc, mean, color = compound, shape = compound), size = 1.8) +
  scale_color_manual(values = cols, labels = lab) + scale_shape_manual(values = pub_shapes(names(cols)), labels = lab) +
  scale_x_log10(breaks = 10^(-3:2), labels = label_log(digits = 1)) + annotation_logticks(sides = "b") +
  guides(color = guide_legend(nrow = 3), shape = guide_legend(nrow = 3)) + theme_pub(grid = "none")
```
`SSfpl` is the 4-parameter logistic self-starter; `drc::drm()` is an alternative with built-in EC50 confidence intervals.

## scatter-regression
```r
fit <- lm(absorbance ~ conc, data = d)
nd <- tibble(conc = seq(0, 22, length.out = 100))
ci <- cbind(nd, predict(fit, nd, interval = "confidence")); pi <- cbind(nd, predict(fit, nd, interval = "prediction"))
eq <- sprintf("italic(y) == %.4f * italic(x) + %.4f", coef(fit)[2], coef(fit)[1]); r2 <- sprintf("italic(R)^2 == %.4f", summary(fit)$r.squared)
pa <- ggplot() + geom_ribbon(data = pi, aes(conc, ymin = lwr, ymax = upr), fill = "grey85") +
  geom_ribbon(data = ci, aes(conc, ymin = lwr, ymax = upr), fill = pub_colors[1], alpha = 0.3) +
  geom_line(data = ci, aes(conc, fit), color = pub_colors[1]) + geom_point(data = d, aes(conc, absorbance)) +
  annotate("text", x = -Inf, y = Inf, label = eq, parse = TRUE, hjust = -0.08, vjust = 1.6, size = 2.8) +
  annotate("text", x = -Inf, y = Inf, label = r2, parse = TRUE, hjust = -0.1, vjust = 3.6, size = 2.8) +
  labs(x = expression("Concentration (" * mu * "g mL"^{-1} * ")"), y = "Absorbance (a.u.)") + theme_pub(grid = "xy")
pb <- ggplot(tibble(fitted = fitted(fit), resid = residuals(fit)), aes(fitted, resid)) +
  geom_hline(yintercept = 0, linewidth = 0.3) + geom_point() + labs(x = "Fitted absorbance", y = "Residual") + theme_pub(grid = "xy")
pa + pb + plot_annotation(tag_levels = "A")
```
Several series (wide table): `pivot_longer()`, color + shape by series, `geom_smooth(method = "lm", formula = y ~ x)`;
put equations in a table or caption. Correlation: report Pearson/Spearman r and p in the caption, no line unless a model is claimed.
Dose-response and kinetics: see the other recipes.

## bland-altman
```r
bias <- mean(d$diff); sdd <- sd(d$diff); loa <- bias + c(-1.96, 1.96) * sdd
se <- sqrt(3 * sdd^2 / nrow(d)); tc <- qt(0.975, nrow(d) - 1)
ggplot(d, aes(mean, diff)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = loa[1] - tc * se, ymax = loa[1] + tc * se, fill = "grey85") +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = loa[2] - tc * se, ymax = loa[2] + tc * se, fill = "grey85") +
  geom_hline(yintercept = bias, color = pub_colors[1], linewidth = 0.6) + geom_hline(yintercept = loa, linetype = "dashed") +
  geom_point(alpha = 0.8) + coord_cartesian(clip = "off") +
  annotate("text", x = Inf, y = bias, label = sprintf("Bias\n%.1f", bias), hjust = -0.12, size = 2.5) +   # labels outside the panel
  theme_pub(grid = "none", plot.margin = margin(4, 40, 4, 4))
```

## roc
```r
rocs <- lapply(markers, function(m) pROC::roc(d$status, d[[m]], quiet = TRUE, direction = "<")); names(rocs) <- markers
curve <- bind_rows(lapply(names(rocs), function(m) { co <- pROC::coords(rocs[[m]], "all", ret = c("specificity", "sensitivity"), transpose = FALSE)
  tibble(marker = m, fpr = 1 - co$specificity, tpr = co$sensitivity) })) %>% mutate(marker = factor(marker, names(rocs)))
auc <- vapply(names(rocs), function(m) { ci <- pROC::ci.auc(rocs[[m]]); sprintf("%s: AUC %.2f (%.2f–%.2f)", m, ci[2], ci[1], ci[3]) }, "")
ggplot(curve, aes(fpr, tpr, color = marker)) + geom_abline(linetype = "dashed", color = "grey60") + geom_step(linewidth = 0.7) +
  scale_color_manual(values = pub_palette(names(rocs)), labels = auc) + coord_equal() +
  guides(color = guide_legend(nrow = 3)) + labs(x = "1 − Specificity", y = "Sensitivity", color = NULL) + theme_pub(grid = "xy")
```
Compare AUCs with `pROC::roc.test()` and report the p-value in the caption.

## kaplan-meier
```r
fit <- survival::survfit(survival::Surv(time, status) ~ arm, data = d)
strata <- sub("arm=", "", names(fit$strata))
km <- tibble(time = fit$time, surv = fit$surv, n.censor = fit$n.censor, arm = rep(strata, fit$strata))
km <- bind_rows(tibble(arm = strata, time = 0, surv = 1, n.censor = 0), km) %>% arrange(arm, time)
lr <- survival::survdiff(survival::Surv(time, status) ~ arm, data = d); p_lr <- pchisq(lr$chisq, length(lr$n) - 1, lower.tail = FALSE)
cox <- summary(survival::coxph(survival::Surv(time, status) ~ arm, data = d))
brk <- seq(0, 36, 6)
pa <- ggplot(km, aes(time, surv, color = arm)) + geom_step(linewidth = 0.7) +
  geom_point(data = filter(km, n.censor > 0), shape = 3, size = 1.3, show.legend = FALSE) +
  annotate("text", x = 0.8, y = 0.1, hjust = 0, size = 2.6, label = sprintf("HR %.2f (%.2f–%.2f)\nLog-rank %s", cox$conf.int[1, 1], cox$conf.int[1, 3], cox$conf.int[1, 4], format_p(p_lr))) +
  scale_x_continuous(breaks = brk, limits = c(0, 36), expand = expansion(add = c(1.6, 1.2))) +
  scale_y_continuous(labels = label_percent(), limits = c(0, 1), expand = expansion(mult = c(0, 0.02))) +
  theme_pub(legend = "inside", legend.position.inside = c(0.84, 0.9), axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.line.x = element_blank())
rk <- summary(fit, times = brk, extend = TRUE); risk <- tibble(time = rk$time, n = rk$n.risk, arm = sub("arm=", "", as.character(rk$strata)))
pb <- ggplot(risk, aes(time, arm, label = n, color = arm)) + geom_text(size = 2.6, show.legend = FALSE) +
  scale_x_continuous(breaks = brk, limits = c(0, 36), expand = expansion(add = c(1.6, 1.2))) +
  labs(x = "Time since randomisation (months)", y = NULL, title = "Number at risk") + theme_pub(grid = "none")
pa / pb + plot_layout(heights = c(4.2, 1))
```
Give both panels the same x scale, breaks and expansion so the table columns align under the curve.

## volcano
```r
d <- d %>% mutate(class = case_when(padj < 0.05 & log2fc >= 1 ~ "Up", padj < 0.05 & log2fc <= -1 ~ "Down", TRUE ~ "n.s."))
top <- d %>% filter(class != "n.s.") %>% group_by(class) %>% slice_min(padj, n = 5) %>% ungroup()
ggplot(d, aes(log2fc, -log10(padj), color = class)) + geom_point(size = 0.55, alpha = 0.65, stroke = 0) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.3) + geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.3) +
  ggrepel::geom_text_repel(data = top, aes(label = gene), size = 2.1, family = pub_family(), color = "black", min.segment.length = 0, max.overlaps = Inf, seed = 4) +
  scale_color_manual(values = c(Up = "#D55E00", Down = "#0072B2", `n.s.` = "grey78")) +
  annotate("text", x = -Inf, y = -Inf, label = paste0("Down: ", n_down), hjust = -0.15, vjust = -0.9, size = 2.7, color = "#0072B2", fontface = "bold") +
  labs(x = expression(log[2] * " fold change"), y = expression(-log[10] * " adjusted " * italic(p))) + theme_pub(grid = "none", legend = "none")
```
State the thresholds (|log2FC| >= 1, FDR < 0.05) in the caption. 20k+ points make heavy PDFs: also export TIFF/PNG.

## forest-plot
Estimate column in its own panel so nothing clips:
```r
pa <- ggplot(d, aes(est, study)) + geom_vline(xintercept = 1, linetype = "dashed") +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y", width = 0.22) +
  geom_point(data = filter(d, type == "Study"), aes(size = w), shape = 15) + scale_size_area(max_size = 3, guide = "none") +
  geom_point(data = filter(d, type == "Pooled"), shape = 18, size = 4, color = "#D55E00") +
  scale_x_log10(breaks = c(0.4, 0.6, 0.8, 1, 1.25), labels = c("0.4", "0.6", "0.8", "1.0", "1.25")) +
  labs(x = "Hazard ratio (95% CI), log scale\n← favours treatment          favours control →", y = NULL) + theme_pub(grid = "none")
pb <- ggplot(d, aes(0, study, label = label)) + geom_text(hjust = 0, size = 2.5) + scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  labs(title = "HR (95% CI)") + theme_void(base_family = pub_family()) + theme(plot.title = element_text(size = 6.5, face = "bold", hjust = 0))
pa + pb + plot_layout(widths = c(3, 1.25))
```
Ratios (OR/HR/RR) on a log axis with the null at 1; differences (MD/SMD) on a linear axis with the null at 0. Square size = weight.
Meta-analysis fits: `meta::metagen()` / `metafor::rma()`.

## correlation-heatmap
Circles (size = |r|, fill = r) for the lower triangle with significance stars [13]; compute `cor()` and `cor.test()` p-values,
`filter(i > j)`, `geom_point(shape = 21, aes(size = abs(r), fill = r))`, `scale_size_area(max_size = 7.5, limits = c(0, 1))`,
`scale_fill_pub_div(limits = c(-1, 1))`, `coord_equal()`. Use Spearman for non-normal data and state it. Adjust p-values
(`p.adjust(method = "BH")`) when many pairs are tested and say which stars mean what.

## clustered-heatmap
Row-z-scored matrix ordered by `hclust(dist(z), "ward.D2")$order` on both axes, tiles with white borders, gene names in italics at the right,
and an annotation bar on top built as a one-row tile plot; combine with `annbar / heat + plot_layout(heights = c(1, 22), guides = "collect")` [14].
`scale_fill_pub_div(limits = c(-2.5, 2.5), oob = squish)` keeps outliers from washing out the scale. Dendrograms: `ggh4x::scale_x_dendrogram()`
or `ComplexHeatmap` when they are required.

## pca
```r
pc <- prcomp(select(d, all_of(vars)), scale. = TRUE); ve <- summary(pc)$importance[2, 1:2] * 100
sc <- bind_cols(select(d, group), as_tibble(pc$x[, 1:2]))
ld <- as_tibble(pc$rotation[, 1:2], rownames = "var") %>% mutate(across(c(PC1, PC2), ~ .x * max(abs(sc[c("PC1", "PC2")])) * 0.85))
ggplot(sc, aes(PC1, PC2)) + stat_ellipse(aes(fill = group, color = group), geom = "polygon", level = 0.95, alpha = 0.12, linewidth = 0.35) +
  geom_point(aes(color = group, shape = group), size = 1.8) +
  geom_segment(data = ld, aes(x = 0, y = 0, xend = PC1, yend = PC2), arrow = arrow(length = unit(1.6, "mm"), type = "closed"), linewidth = 0.3) +
  ggrepel::geom_text_repel(data = ld, aes(label = var), size = 2.3, family = pub_family(), segment.color = NA) +
  coord_equal() + labs(x = sprintf("PC1 (%.1f%%)", ve[1]), y = sprintf("PC2 (%.1f%%)", ve[2])) + theme_pub(grid = "none")
```
`stat_ellipse()` needs >= 4 points per group. Scale variables (`scale. = TRUE`) unless they share units.

## ridgeline
```r
ggplot(d, aes(size, formulation, fill = formulation)) +
  ggridges::geom_density_ridges(scale = 1.5, rel_min_height = 0.005, quantile_lines = TRUE, quantiles = 2, alpha = 0.8, color = "white", vline_color = "white") +
  scale_fill_manual(values = cols) + scale_y_discrete(expand = expansion(mult = c(0.02, 0.35))) +
  coord_cartesian(xlim = c(40, 700)) + labs(x = "Hydrodynamic diameter (nm)", y = NULL) + theme_pub(grid = "x", legend = "none")
```
White lines mark the medians. Use `coord_cartesian()` for the range; `scale_x_continuous(limits=)` would drop data and distort the densities.

## response-surface
```r
fit <- lm(EE ~ c1 + c2 + I(c1^2) + I(c2^2) + c1:c2, data = ccd)          # coded factors
g <- expand_grid(c1 = seq(-1.6, 1.6, length.out = 160), c2 = seq(-1.6, 1.6, length.out = 160)) %>%
  mutate(span = 100 + 35 * c1, time = 6 + 2.8 * c2, EE = predict(fit, newdata = tibble(c1 = c1, c2 = c2)))
ggplot(g, aes(span, time)) + geom_contour_filled(aes(z = EE), bins = 10) + geom_contour(aes(z = EE), bins = 10, color = "white", linewidth = 0.2) +
  geom_point(data = ccd, shape = 21, fill = "white", size = 1.8) +                   # design points
  scale_fill_viridis_d(name = "EE (%)") + scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0)) + theme_pub(grid = "none", legend = "right")
```
Report the model (ANOVA table, R^2, adjusted R^2, lack of fit) in the text, not on the plot. For two factors the contour is the
standard figure; add a 3D surface only if the journal asks (use `plotly`/`rsm`, outside ggplot2).

## dumbbell
```r
ggplot(d) + geom_segment(aes(x = `Week 12`, xend = Baseline, y = site, yend = site), color = "grey70", linewidth = 0.9, lineend = "round") +
  geom_point(aes(Baseline, site, color = "Baseline"), size = 2.4) + geom_point(aes(`Week 12`, site, color = "Week 12"), size = 2.4) +
  scale_color_manual(values = c(Baseline = "#7F7F7F", `Week 12` = "#0072B2"), breaks = c("Baseline", "Week 12")) + theme_pub(grid = "x")
```
Order categories by the quantity of interest (`arrange()` then `factor(site, site)`).

## waterfall
```r
ggplot(d, aes(id, change, fill = response)) + geom_col(width = 0.8) +
  geom_hline(yintercept = c(20, -30), linetype = "dashed", linewidth = 0.3) +
  scale_fill_manual(values = c(`Partial response` = "#0072B2", `Stable disease` = "#9E9E9E", `Progressive disease` = "#D55E00")) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) + labs(x = "Individual patients", y = "Best change in tumour size", fill = NULL) +
  theme_pub(axis.text.x = element_blank(), axis.ticks.x = element_blank())
```
Sort descending before assigning `id`; thresholds follow the response criteria (RECIST: +20%, -30%).

## rheology
```r
long <- d %>% pivot_longer(c(storage_modulus, loss_modulus), names_to = "modulus", values_to = "value") %>%
  mutate(modulus = factor(modulus, c("storage_modulus", "loss_modulus"), c("G'", "G''"))) %>%
  filter(is.finite(freq), is.finite(value), freq > 0, value > 0)                     # log axes need positive values
ggplot(long, aes(freq, value, color = formulation, linetype = modulus, shape = modulus, group = interaction(formulation, modulus))) +
  geom_line(linewidth = 0.5) + geom_point(size = 1.1) +
  scale_x_log10(labels = label_number(big.mark = ",", drop0trailing = TRUE)) + scale_y_log10(labels = label_number(big.mark = ",", drop0trailing = TRUE)) +
  annotation_logticks(sides = "bl", linewidth = 0.25, short = unit(0.5, "mm"), mid = unit(0.9, "mm"), long = unit(1.3, "mm")) +
  scale_linetype_manual(values = c("G'" = "solid", "G''" = "dashed")) + scale_shape_manual(values = c("G'" = 16, "G''" = 1)) +   # filled = G', open = G''
  guides(color = guide_legend(order = 1), linetype = guide_legend(order = 2), shape = guide_legend(order = 2)) +
  labs(x = "Angular frequency (rad/s)", y = "G', G'' (Pa)") + theme_pub(grid = "none", legend.box = "vertical")
```
Flow curves: `aes(shear_rate, viscosity, color = formulation, shape = formulation)`. Temperature sweeps: linear x, log y.
Do **not** use `annotation_logticks()` on faceted plots (it draws on every panel); use `guide_axis_logticks()` per axis instead.

## spectra-and-instrument-curves
Single instrumental runs: lines only, no error bars, no statistics; peak labels with positions printed to one decimal.
```r
off <- 1150                                   # vertical offset between samples
d <- d %>% mutate(yo = y + (as.integer(sample) - 1) * off)
peaks <- d %>% group_by(sample) %>% slice_max(y, n = 1, with_ties = FALSE) %>% ungroup()
ggplot(d, aes(x, yo, color = sample)) + geom_line(linewidth = 0.3) +
  geom_text(data = peaks, aes(label = sprintf("%.1f°", x)), vjust = -0.7, size = 2.3, color = "black") +
  geom_text(data = d %>% group_by(sample) %>% summarise(x = 59, y = min(yo) + 260), aes(x, y, label = sample, color = sample), hjust = 1, size = 2.6, fontface = "bold", inherit.aes = FALSE) +
  scale_color_manual(values = cols) + labs(x = expression(2 * theta ~ "(degrees)"), y = "Intensity (a.u.)") +
  theme_pub(grid = "none", legend = "none", axis.text.y = element_blank(), axis.ticks.y = element_blank())
```
- FTIR: `scale_x_reverse()`, x = `expression("Wavenumber (cm"^{-1} * ")")`, y = transmittance (%) or absorbance; label bands with `ggrepel`.
- DSC: one panel per sample or overlay; mark peaks with arrow + `"italic(T)[peak] == 123.4*degree*C"` (`parse = TRUE`); state whether endotherms point up or down.
- TGA + DTG: two panels side by side (`p_tg | p_dtg`), label the DTG minimum.
- UV-Vis: absorbance vs wavelength, label lambda-max. Raman/NMR: similar, `scale_x_reverse()` for ppm.
- Keep raw intensities when peak heights are compared; normalise only if shape matters, and say so.

## annotations
- **Default: adjusted p-value brackets** (`pairwise_brackets()` + `geom_brackets()`), only significant pairs and only after a
  significant omnibus test. Details and options in the first recipe.
- **Omnibus significant, no adjusted pair significant**: no brackets; put the overall p in the caption (or a facet strip
  label such as `"Triglycerides\nOverall p = 0.021; pairwise ns"` via `as_labeller()`).
- **Letters** (compact letter display) only when the user asks for them:
  `lab <- cld_letters(st$pairwise, levels) %>% left_join(annotation_y(d, "value", "group", frac = 0.1), by = "group")` then
  `geom_text(data = lab, aes(group, label_y, label = letter), inherit.aes = FALSE, fontface = "bold", size = 3)`; per facet with
  `group_by(endpoint) %>% group_modify(~ cld_letters(.x, levels))` and `annotation_y(..., facet = "endpoint")`.
- **Stars**: `label = "stars"` (`p_stars()`); define them in the caption.
- **Regression / calibration**: equation and R^2 via `annotate("text", parse = TRUE)`.
- Summary-only data and single runs: no inferential marks.

## composite-plates
```r
plate <- (p_a + p_b) / (p_c + p_d) + plot_annotation(tag_levels = "A")                     # or wrap_plots(list(...), design = "AAB\nCDE")
save_pub(plate, "Figure_05_plate", width = "double", height = 170)
```
- Build every panel with the same `theme_pub(base_size)` so text matches; do not rescale panels afterwards.
- Shared legend: `plot_layout(guides = "collect")` and set `legend` inside each panel's `theme_pub()`; avoid `plot & theme()`
  (warns with patchwork 1.3.1 + ggplot2 4.x).
- Panel tags: bold capitals (`"A"`); `tag_levels = "a"` for journals that use lowercase (Nature).
- Panels with very different aspect ratios: `plot_layout(heights = , widths = )` or `design =`.
