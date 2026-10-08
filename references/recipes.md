# Recipes

Copy-ready ggplot2 code for each chart type. Every recipe assumes `source("R/gg_pub.R")`
(the skill's `assets/gg_pub.R`). Fully runnable versions with simulated data are in
`examples/demo.R`; previews are in `examples/gallery/`.

Sizes below are for figures saved at final print size with `save_pub()`; keep
`theme_pub(base_size = 7-9)` so printed text is 6-9 pt.

## Contents
- [violin-box-points](#violin-box-points) - raw replicates, n >= ~10 per group
- [points-mean-error](#points-mean-error) - raw replicates, small n
- [summary-only-data](#summary-only-data) - only mean/SD/n available
- [bars](#bars) - one value per group, counts, proportions
- [paired-data](#paired-data) - before/after, repeated measures
- [time-course](#time-course) - release, kinetics, growth with replicates
- [scatter-regression](#scatter-regression) - calibration, correlation, dose-response
- [rheology](#rheology) - log-log moduli/viscosity overlays
- [spectra-and-instrument-curves](#spectra-and-instrument-curves) - XRD, FTIR, Raman, UV-Vis, DSC, TGA
- [kaplan-meier](#kaplan-meier) - survival with number-at-risk table
- [volcano](#volcano) - differential expression
- [forest-plot](#forest-plot) - effect sizes with CIs
- [correlation-heatmap](#correlation-heatmap)
- [pca](#pca) - scores with ellipses
- [annotations](#annotations) - letters, brackets, p-values in subtitles/strips
- [composite-plates](#composite-plates) - patchwork multi-panel figures

---

## violin-box-points
```r
lv <- c("Control", "Vehicle", "Drug 5 mg/kg", "Drug 10 mg/kg")
d <- d %>% mutate(group = factor(group, levels = lv))
st <- compare_groups(d, "value", "group")                       # only if the user agreed to run tests
lab <- cld_letters(st$pairwise, lv) %>%
  left_join(annotation_y(d, "value", "group", frac = 0.1), by = "group")
cols <- pub_palette(lv)
p <- ggplot(d, aes(group, value, fill = group, color = group)) +
  layers_violin_box() +
  geom_text(data = lab, aes(group, label_y, label = letter), inherit.aes = FALSE, fontface = "bold", size = 3) +
  scale_fill_manual(values = cols) + scale_color_manual(values = cols) +
  scale_y_continuous(expand = expansion(mult = c(0.04, 0.12))) +
  labs(x = NULL, y = "Serum glucose (mg/dL)",
       subtitle = paste0(st$omnibus$test, ": ", format_p(st$omnibus$p), "; ", st$posthoc, " letters")) +
  theme_pub(legend = "none")
save_pub(p, "Figure_02_glucose", width = "single", height = 75)
```
Two crossed factors: `aes(conc, value, fill = terpene, color = terpene, group = interaction(conc, terpene))`,
`layers_violin_box(dodge = 0.8)`, and letters with `position = position_dodge(0.8)` plus `group = terpene` in their aes.
Box-only variant: `layers_violin_box(violin = FALSE, box_width = 0.5)`.
Long x labels: `scale_x_discrete(labels = c("Bigel+Nano+Drug" = "Bigel +\nNano + Drug"))` instead of rotating text.

## points-mean-error
For n < ~10 per group a violin is a guess at a density from a handful of points; show the points.
```r
p <- ggplot(d, aes(conc, value, color = terpene, shape = terpene)) +
  layers_points_mean(error = "sd", dodge = 0.6) +     # "se" or "ci95" also available
  scale_color_manual(values = pub_palette(d$terpene)) +
  scale_shape_manual(values = pub_shapes(d$terpene)) +
  labs(x = "Terpene concentration", y = "Entrapment efficiency (%)", color = "Terpene", shape = "Terpene") +
  theme_pub()
```
One factor: drop `dodge`. State "mean +/- SD, n = 4" in the caption.

## summary-only-data
Raw data unavailable -> points with error bars; never fake points or violins.
```r
pd <- position_dodge(width = 0.6)
p <- ggplot(s, aes(ratio, mean, color = carrier, shape = carrier)) +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.15, linewidth = 0.4, position = pd) +
  geom_point(size = 2, position = pd) +
  facet_wrap(~ endpoint, scales = "free_y", labeller = as_labeller(c(Size = "Size (nm)", PDI = "PDI", Zeta = "Zeta potential (mV)"))) +
  scale_color_manual(values = pub_palette(s$carrier)) + scale_shape_manual(values = pub_shapes(s$carrier)) +
  labs(x = "Span 20:Tween 80 ratio", y = NULL) +
  theme_pub()
```
Letters from a supplied pairwise table: `annotation_y(s %>% mutate(upper = mean + sd), "upper", "ratio", facet = "endpoint")`.
Bars with error bars ("dynamite plots") hide the distribution; use them only when the user or journal asks.

## bars
For quantities that start at zero and have one value per group, counts, or proportions.
```r
p <- ggplot(d, aes(formulation, hardness, fill = formulation)) +
  geom_col(width = 0.7, color = "black", linewidth = 0.3) +
  scale_fill_manual(values = pub_palette(d$formulation)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(x = NULL, y = "Hardness (g)") + theme_pub(legend = "none")
```
Proportions: `geom_col(position = "fill")` + `scale_y_continuous(labels = label_percent())`.
Several metrics for the same groups: a small function returning one panel per metric, combined with patchwork
(`(f("hardness", "Hardness (g)") | f("cohesiveness", "Cohesiveness")) / ...`).
Avoid pie charts; a sorted bar chart is easier to compare.

## paired-data
```r
p <- ggplot(d, aes(time, value)) +
  geom_line(aes(group = subject), color = "grey65", linewidth = 0.3) +
  geom_point(aes(color = time), size = 1.5, show.legend = FALSE) +
  stat_summary(fun.data = mean_error_fun("sd"), geom = "errorbar", width = 0.12, linewidth = 0.5,
               position = position_nudge(x = c(-0.18, 0.18))) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 2.6, position = position_nudge(x = c(-0.18, 0.18))) +
  labs(x = NULL, y = "Total cholesterol (mg/dL)", subtitle = paste("Paired t-test:", format_p(tt$p.value))) +
  theme_pub()
```
More than two time points: same idea with `x = week` (numeric) and a bold mean line on top of thin subject lines.

## time-course
```r
s <- summarise_mean_error(d, "value", c("formulation", "time"), error = "sd")
p <- ggplot(s, aes(time, mean, color = formulation, shape = formulation, linetype = formulation)) +
  geom_errorbar(aes(ymin = pmax(0, lower), ymax = upper), width = 0.4, linewidth = 0.35, linetype = "solid") +
  geom_line(linewidth = 0.5) + geom_point(size = 1.6) +
  scale_color_manual(values = pub_palette(s$formulation)) +
  scale_shape_manual(values = pub_shapes(s$formulation)) +
  scale_linetype_manual(values = pub_linetypes(s$formulation)) +
  scale_x_continuous(breaks = c(0, 2, 4, 6, 8, 12, 24)) +       # breaks at the actual sampling times
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(x = "Time (h)", y = "Cumulative release (%)", color = NULL, shape = NULL, linetype = NULL) +
  theme_pub()
```
- Clamp lower error bars at 0 for percentages; error bar width ~2% of the x range.
- Many groups: `facet_wrap(~ factor1)` with color = factor2 instead of 8 overlapping lines.
- If the protocol starts at 0 but no 0 h value was recorded, add the baseline explicitly in data prep and say so.
- Kinetic model fits (zero-order, first-order, Higuchi, Korsmeyer-Peppas): fit with `nls()` per group and draw
  `geom_line(data = predictions)`; report the model and R^2 in the caption, not on the plot.

## scatter-regression
```r
fit <- lm(abs ~ conc, data = d)
eq <- sprintf("italic(y) == %.4f*italic(x) + %.4f*';'~italic(R)^2 == %.4f",
              coef(fit)[2], coef(fit)[1], summary(fit)$r.squared)
p <- ggplot(d, aes(conc, abs)) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = pub_colors[1], fill = pub_colors[1], alpha = 0.15, linewidth = 0.6) +
  geom_point(size = 1.6) +
  annotate("text", x = min(d$conc), y = max(d$abs), label = eq, parse = TRUE, hjust = 0, vjust = 1, size = 2.8) +
  labs(x = expression("Concentration (" * mu * "g mL"^{-1} * ")"), y = "Absorbance") +
  theme_pub(grid = "xy")
```
- Several series sharing x (wide table): `pivot_longer(-conc, names_to = "medium", values_to = "abs")`, then
  color + shape = medium and `geom_smooth(aes(group = medium), method = "lm")`; put equations in a table/caption.
- Correlation: report Pearson/Spearman r and p in the subtitle; no fitted line unless a model is claimed.
- Dose-response: `scale_x_log10()` and a 4-parameter logistic fit with `nls(y ~ SSfpl(log10(dose), A, B, xmid, scal))`.

## rheology
```r
long <- d %>%
  pivot_longer(c(storage_modulus, loss_modulus), names_to = "modulus", values_to = "value") %>%
  mutate(modulus = factor(modulus, c("storage_modulus", "loss_modulus"), c("G'", "G''"))) %>%
  filter(is.finite(frequency), is.finite(value), frequency > 0, value > 0)   # log scales need > 0
p <- ggplot(long, aes(frequency, value, color = formulation, linetype = modulus, shape = modulus,
                      group = interaction(formulation, modulus))) +
  geom_line(linewidth = 0.5) + geom_point(size = 1) +
  scale_x_log10(labels = label_number(big.mark = ",", drop0trailing = TRUE)) +
  scale_y_log10(labels = label_number(big.mark = ",", drop0trailing = TRUE)) +
  annotation_logticks(sides = "bl", linewidth = 0.25, short = grid::unit(0.05, "cm"),
                      mid = grid::unit(0.1, "cm"), long = grid::unit(0.15, "cm")) +
  scale_color_manual(values = pub_palette(long$formulation)) +
  scale_linetype_manual(values = c("G'" = "solid", "G''" = "dashed")) +
  scale_shape_manual(values = c("G'" = 16, "G''" = 1)) +               # filled = G', open = G''
  labs(x = "Angular frequency (rad/s)", y = "G', G'' (Pa)", color = "Formulation", linetype = "Modulus", shape = "Modulus") +
  theme_pub(grid = "none") + theme(legend.box = "vertical")
```
Flow curves: `aes(shear_rate, viscosity, color = formulation, shape = formulation)`.
Temperature sweeps: linear x, log y. Amplitude sweeps: mark the LVR end / crossover with `geom_vline` + label if computed.
`label_log()` gives 10^n tick labels if the journal prefers them.

## spectra-and-instrument-curves
Single instrumental runs: lines only, no error bars, no statistics.
```r
offset <- 1.1 * max(d$y)                      # vertical offset between samples
d <- d %>% mutate(y_off = y + (as.integer(sample) - 1) * offset)
peaks <- d %>% group_by(sample) %>% slice_max(y, n = 1, with_ties = FALSE) %>% ungroup()
p <- ggplot(d, aes(x, y_off, color = sample)) +
  geom_line(linewidth = 0.35) +
  geom_text(data = peaks, aes(label = sprintf("%.1f°", x)), vjust = -0.6, size = 2.5, color = "black") +
  geom_text(data = d %>% group_by(sample) %>% summarise(y = min(y_off) + 0.2 * offset),
            aes(x = max(d$x), y = y, label = sample), hjust = 1, size = 2.7, fontface = "bold") +
  scale_color_manual(values = pub_palette(d$sample)) +
  labs(x = expression(2 * theta * " (degree)"), y = "Intensity (a.u.)") +
  theme_pub(grid = "none", legend = "none") +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())   # a.u. offsets have no meaningful ticks
```
- FTIR: `scale_x_reverse()` (wavenumber decreasing), x = "Wavenumber (cm^-1)" via `expression("Wavenumber (cm"^{-1} * ")")`,
  y = Transmittance (%) or Absorbance; label characteristic bands with `ggrepel::geom_text_repel`.
- DSC: one panel per sample or overlay; mark peak temperatures with arrow + `"italic(T)[peak] == 123.4*degree*C"` (`parse = TRUE`);
  state "endo up/down" in the axis label.
- TGA + DTG: two panels side by side with patchwork (`p_tg | p_dtg`), `geom_hline(yintercept = 0)` on DTG,
  label the DTG minimum (`slice_min`).
- Keep raw intensities when comparing peak heights; normalise (`y / max(y)`) only if shape matters, and say so.

## kaplan-meier
```r
fit <- survival::survfit(survival::Surv(time, status) ~ arm, data = d)
km <- tibble(time = fit$time, surv = fit$surv, n.censor = fit$n.censor,
             arm = rep(sub("arm=", "", names(fit$strata)), fit$strata))
km <- bind_rows(distinct(km, arm) %>% mutate(time = 0, surv = 1), km) %>% arrange(arm, time)
lr <- survival::survdiff(survival::Surv(time, status) ~ arm, data = d)
lr_p <- pchisq(lr$chisq, length(lr$n) - 1, lower.tail = FALSE)
brk <- seq(0, 36, 6)
p_curve <- ggplot(km, aes(time, surv, color = arm)) +
  geom_step(linewidth = 0.55) +
  geom_point(data = filter(km, n.censor > 0), shape = 3, size = 1.2, show.legend = FALSE) +   # censor marks
  annotate("text", x = 1, y = 0.08, label = paste("Log-rank", format_p(lr_p)), hjust = 0, size = 2.8) +
  scale_x_continuous(breaks = brk, limits = range(brk)) +
  scale_y_continuous(labels = label_percent(), limits = c(0, 1)) +
  labs(x = NULL, y = "Survival probability", color = NULL) +
  theme_pub(legend = "inside") + theme(legend.position.inside = c(0.85, 0.9))
r <- summary(fit, times = brk, extend = TRUE)
risk <- tibble(time = r$time, n = r$n.risk, arm = sub("arm=", "", as.character(r$strata)))
p_risk <- ggplot(risk, aes(time, arm, label = n, color = arm)) + geom_text(size = 2.6, show.legend = FALSE) +
  scale_x_continuous(breaks = brk, limits = range(brk)) +
  labs(x = "Time (months)", y = NULL, title = "Number at risk") + theme_pub(grid = "none") +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(), plot.title = element_text(size = 7))
p <- p_curve / p_risk + plot_layout(heights = c(4, 1))
```
Use the same palette object for curve and table so colors match.

## volcano
```r
d <- d %>% mutate(class = case_when(padj < 0.05 & log2fc > 1 ~ "Up", padj < 0.05 & log2fc < -1 ~ "Down", TRUE ~ "NS"))
top <- d %>% filter(class != "NS") %>% slice_min(padj, n = 10)
p <- ggplot(d, aes(log2fc, -log10(padj), color = class)) +
  geom_point(size = 0.6, alpha = 0.7) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.3, color = "grey40") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", linewidth = 0.3, color = "grey40") +
  ggrepel::geom_text_repel(data = top, aes(label = gene), size = 2.3, family = pub_family(), color = "black",
                           min.segment.length = 0, segment.size = 0.25, max.overlaps = Inf) +
  scale_color_manual(values = c(Up = "#D55E00", Down = "#0072B2", NS = "grey75")) +
  labs(x = expression(log[2] * " fold change"), y = expression(-log[10] * " adjusted p"), color = NULL) +
  theme_pub(grid = "none")
```
State thresholds (|log2FC| > 1, FDR < 0.05) in the caption. Many points: save PNG/TIFF; PDFs with 20k points get heavy.

## forest-plot
Put the estimate column in its own patchwork panel so it never clips:
```r
d <- d %>% mutate(study = factor(study, rev(study)), label = sprintf("%.2f (%.2f–%.2f)", est, lower, upper))
p_plot <- ggplot(d, aes(est, study)) +
  geom_vline(xintercept = 1, linetype = "dashed", linewidth = 0.3) +
  geom_errorbar(aes(xmin = lower, xmax = upper), width = 0.2, linewidth = 0.4, orientation = "y") +
  geom_point(aes(shape = pooled, size = pooled)) +
  scale_shape_manual(values = c(`FALSE` = 15, `TRUE` = 18), guide = "none") +
  scale_size_manual(values = c(`FALSE` = 1.8, `TRUE` = 3.2), guide = "none") +
  scale_x_log10() + labs(x = "Hazard ratio (95% CI, log scale)", y = NULL) + theme_pub(grid = "none")
p_text <- ggplot(d, aes(0, study, label = label)) + geom_text(hjust = 0, size = 2.6) +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) + labs(title = "HR (95% CI)") +
  theme_void(base_family = pub_family()) + theme(plot.title = element_text(size = 7, face = "bold", hjust = 0))
p <- p_plot + p_text + plot_layout(widths = c(3, 1.3))
```
Ratios (OR, HR, RR) on a log axis with the null line at 1; differences (MD, SMD) on a linear axis with the null at 0.

## correlation-heatmap
```r
cm <- cor(select(d, where(is.numeric)), use = "pairwise.complete.obs", method = "spearman")
long <- as_tibble(cm, rownames = "a") %>% pivot_longer(-a, names_to = "b", values_to = "r") %>%
  mutate(a = factor(a, colnames(cm)), b = factor(b, rev(colnames(cm))))
p <- ggplot(long, aes(a, b, fill = r)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%.2f", r), color = abs(r) > 0.6), size = 2.4, show.legend = FALSE) +
  scale_color_manual(values = c(`TRUE` = "white", `FALSE` = "black")) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", limits = c(-1, 1), name = "r") +
  coord_equal() + labs(x = NULL, y = NULL) +
  theme_pub(grid = "none", legend = "right") + theme(axis.line = element_blank(), axis.ticks = element_blank())
```
Lower triangle only: `filter(as.integer(a) < as.integer(factor(b, colnames(cm))))` before plotting.
Diverging data needs a diverging scale centred on 0; one-sided data (expression z-scores aside) uses
`scale_fill_viridis_c()`.

## pca
```r
pca <- prcomp(select(d, all_of(vars)), scale. = TRUE)
ve <- summary(pca)$importance[2, 1:2] * 100
sc <- bind_cols(d, as_tibble(pca$x[, 1:2]))
p <- ggplot(sc, aes(PC1, PC2, color = group, fill = group, shape = group)) +
  stat_ellipse(geom = "polygon", alpha = 0.12, level = 0.95, linewidth = 0.3) +   # needs >= 4 points per group
  geom_point(size = 1.6) +
  scale_color_manual(values = pub_palette(sc$group)) + scale_fill_manual(values = pub_palette(sc$group)) +
  scale_shape_manual(values = pub_shapes(sc$group)) +
  labs(x = sprintf("PC1 (%.1f%%)", ve[1]), y = sprintf("PC2 (%.1f%%)", ve[2]), color = NULL, fill = NULL, shape = NULL) +
  theme_pub(grid = "xy")
```

## annotations
- Compact letters: `cld_letters(pairwise, levels)` + `annotation_y()`; bold, black, size ~3 (8.5 pt).
  Letters are only meaningful with an adjusted all-pairs test; `cld_letters()` blanks them when all groups share one.
- Few comparisons (e.g. treatment vs control): brackets
  `ggsignif::geom_signif(comparisons = list(c("A", "B")), annotations = "p(adj) = 0.049", y_position = y,
  tip_length = 0.015, textsize = 2.8, family = pub_family())`, and increase the top expansion (`mult = c(0.03, 0.25)`).
- Stars: `p_stars(p)`; define them in the caption.
- Omnibus significant but no adjusted pair significant: no letters; write "Overall p = 0.043; pairwise ns" in the
  subtitle or facet strip (`labeller = as_labeller(c(TG = "Triglycerides\nOverall p = 0.021; pairwise ns"))`).
- Per-facet letters: `group_by(endpoint) %>% group_modify(~ cld_letters(.x, levels))` and
  `annotation_y(..., facet = "endpoint")`, since each panel has its own y range.

## composite-plates
```r
plate <- (p_a | p_b) / (p_c | p_d) + plot_annotation(tag_levels = "A")
plate <- wrap_plots(list(p1, p2, p3, p4, p5), design = "AAB\nCDE") + plot_annotation(tag_levels = "A")
save_pub(plate, "Figure_05_plate", width = "double", height = 150)
```
- Build panels with the same `theme_pub(base_size)` so text matches across panels.
- Shared legend: `+ plot_layout(guides = "collect") & theme(legend.position = "bottom")` -- with patchwork 1.3.1 and
  ggplot2 4.x the `& theme()` form prints a harmless "annotation$theme is not a valid theme" warning; to avoid it,
  set the legend position inside each panel's theme instead.
- Align panels with different axis-label widths automatically (patchwork does this); do not pad labels with spaces.
