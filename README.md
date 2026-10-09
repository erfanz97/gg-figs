# gg-figs

A [Claude](https://claude.com) Agent Skill for **publication-quality scientific figures in R with ggplot2**.

Give Claude a data file (CSV, TSV, Excel) and ask for a figure. The skill inspects the data, chooses an
appropriate chart, adds only the statistics the analysis supports, and exports journal-ready files. It asks a
question only when two choices are equally defensible, for example violins vs. points for four observations per
group. All example figures in this repository are drawn from **simulated data**.

![Multi-panel plate](examples/gallery/24_multipanel_plate.png)

## What it does

- **Reads the data first.** `scripts/inspect_data.R` detects column roles, replicates per group, wide vs. long
  layout, facet variables, labels that encode two factors (e.g. `"Drug 5 mg"`), paired designs, summary-only tables
  and existing p-value columns, then ranks chart suggestions and lists the open questions.
- **Chooses the chart from the data.** 24 examples: raincloud and violin + box + points, points + mean ± SD,
  stacked proportions, paired lines, release/time courses, pharmacokinetics (semi-log), dose-response with 4PL
  fits, calibration with confidence and prediction bands, Bland–Altman, ROC, Kaplan–Meier with risk table, volcano,
  forest plot, correlation matrix, clustered heatmap, PCA biplot, ridgelines, response-surface contours, dumbbell,
  waterfall, rheology (log–log), XRD/FTIR/DSC/TGA curves and multi-panel plates.
- **Reports statistics carefully.** `compare_groups()` runs ANOVA + Tukey, Welch + Games–Howell or
  Kruskal–Wallis + Dunn (chosen from residual normality and variance homogeneity, reported by name).
  `pairwise_brackets()` + `geom_brackets()` draw adjusted p-value brackets for significant pairs only, and only after
  a significant omnibus test. Compact letters (`cld_letters()`) are available on request.
- **Works with all of ggplot2.** The helpers are ordinary ggplot2 objects (a complete theme, scales, layer lists,
  one geom), so any geom, stat, position, scale, coord, facet, guide or `theme()` call can be added.
  `examples/test_ggplot2_compat.R` builds and draws a plot for every geom/stat/position/scale/coord/facet/guide/
  theme exported by the installed ggplot2 (301 of 322 exports on ggplot2 4.0.1; the rest are internals or need
  extra packages), and `scripts/ggplot2_api.R` looks up arguments and aesthetics of the installed version.
- **Keeps one house style.** Text is sized for the final print size. The default palette is Okabe–Ito based
  (readable with color blindness) and every color has a matching shape or linetype for grayscale printing. The default
  font is Times New Roman (`pub_font("Arial")` switches).
- **Exports for journals.** `save_pub()` writes vector PDF plus 600-dpi LZW TIFF and PNG at column widths for
  Elsevier, Springer Nature, Nature, Cell, ACS, Wiley, PLOS, Science and MDPI.
- **Drafts the caption**: plot elements, error bars, n and the test used.

## Install

**Claude Code (all projects):**

```bash
git clone https://github.com/erfanz97/gg-figs.git ~/.claude/skills/gg-figs
```

**Claude Code (one project):** clone into `<project>/.claude/skills/gg-figs`.

**Claude.ai / Claude Desktop:** download the repository as a ZIP and upload it under *Settings → Capabilities → Skills*.

**R packages:**

```r
install.packages(c("ggplot2", "dplyr", "tidyr", "readr", "patchwork", "ragg", "scales", "systemfonts",
                   "multcompView", "readxl", "ggrepel", "ggridges", "survival", "pROC"))
```

The first ten are required by `gg_pub.R`; the rest are used by individual examples. Tested with R 4.5 and
ggplot2 4.0.1 (ggplot2 ≥ 3.5.0 is required).

## Use

Ask in plain language:

- "Make a figure for my paper from `data/ee_raw.csv`."
- "Plot the release profiles in `release.xlsx` in the same style as my other figures."
- "Compare the four groups in this table and show significant differences."

Claude runs the inspector, states the chart it picked and why (or asks a short question when the data are
ambiguous), writes an R script in your project, renders the figure, checks it visually, and reports the files and a
draft caption. You can try the inspector yourself:

```bash
Rscript scripts/inspect_data.R examples/data/raincloud_raw.csv
```

The helper library also works on its own, without Claude:

```r
source("R/gg_pub.R")                                      # copied from assets/gg_pub.R
st <- compare_groups(d, "value", "group")
b  <- pairwise_brackets(st$pairwise, d, "group", "value", omnibus_p = st$omnibus$p, vs = "Control")
p  <- ggplot(d, aes(group, value, fill = group, color = group)) +
  layers_raincloud() + geom_brackets(b) +
  scale_fill_pub() + scale_color_pub() + labs(x = NULL, y = "Response (unit)") +
  theme_pub(legend = "none")
save_pub(p, "Figure_01", width = "single", journal = "elsevier")
```

## Repository layout

| Path | Purpose |
|---|---|
| `SKILL.md` | Instructions Claude follows (workflow, decision rules, style, pitfalls) |
| `assets/gg_pub.R` | Helper library: theme, palettes, scales, statistics, brackets, raincloud, direct labels, `save_pub` |
| `assets/figure_template.R` | Skeleton for a project figure script |
| `scripts/inspect_data.R` | Data profiler and chart recommender |
| `scripts/ggplot2_api.R` | Lists what the installed ggplot2 supports |
| `references/` | Chart selection, recipes, ggplot2 reference, statistics, journal specifications |
| `examples/gallery.R` | The 24 example figures (simulated data), written to `examples/gallery/` |
| `examples/test_helpers.R` | Assertion tests (Tukey/Dunn/Games–Howell checked against `TukeyHSD()` and `rstatix`) |
| `examples/test_ggplot2_compat.R` | Compatibility test against the whole ggplot2 API |

Run the checks from the repository root:

```bash
Rscript examples/test_helpers.R
```

```bash
Rscript examples/test_ggplot2_compat.R
```

```bash
Rscript examples/gallery.R
```

## Gallery

All data are simulated.

| | | |
|---|---|---|
| ![](examples/gallery/01_raincloud_brackets.png) | ![](examples/gallery/04_release_profiles_direct_labels.png) | ![](examples/gallery/06_dose_response_4pl.png) |
| ![](examples/gallery/05_pharmacokinetics_semilog.png) | ![](examples/gallery/10_kaplan_meier_risk_table.png) | ![](examples/gallery/11_volcano_labelled.png) |
| ![](examples/gallery/13_correlation_matrix_circles.png) | ![](examples/gallery/15_pca_biplot.png) | ![](examples/gallery/17_response_surface_contour.png) |
| ![](examples/gallery/09_roc_curves.png) | ![](examples/gallery/16_ridgeline_size_distributions.png) | ![](examples/gallery/22_xrd_offset_stack.png) |

The wide examples (faceted violins with brackets, faceted points + mean ± SD, calibration with residuals, waterfall,
forest plot, clustered heatmap) are in [`examples/gallery/`](examples/gallery).
