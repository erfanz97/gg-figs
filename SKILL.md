---
name: gg-figs
description: Publication-quality scientific figures in R/ggplot2 for articles, theses and revisions. Given a data file (CSV/Excel) or a figure request, it inspects the data, picks the chart itself (violin/box, points + mean ± SD, time-course, calibration, rheology log-log, XRD/FTIR/DSC/TGA, Kaplan-Meier, volcano, forest, heatmap, PCA, multi-panel plates) and asks only when the choice is genuinely ambiguous. Adds only supported statistics (ANOVA/Tukey, Welch/Games-Howell, Kruskal/Dunn, letters, brackets), colorblind-safe palettes, and exports vector PDF + 600-dpi TIFF/PNG at journal widths. Use whenever the user wants to plot, chart, visualize, redraw or restyle data for a paper, manuscript, thesis or poster in R, even without saying "ggplot2", e.g. "make a figure from this csv", "plot my results", "same style as my other figures", or Persian «نمودار بکش»، «رسم نمودار برای مقاله». Not for Python-only requests.
---

# gg-figs: publication figures with ggplot2

Goal: turn the user's data into a figure a journal accepts on first submission: correct chart for the data,
honest statistics, consistent style, right size and format. The user usually hands over a data file and
expects you to choose; asking about everything defeats the purpose, while guessing on a real ambiguity
produces a figure they have to redo.

## Files in this skill
- `assets/gg_pub.R`: helper library (theme, palettes, statistics, layer bundles, `save_pub()`). Copy it into the project.
- `assets/figure_template.R`: skeleton for a project figure script.
- `scripts/inspect_data.R`: profiles a data file and ranks chart suggestions plus the open questions.
- `references/chart-selection.md`: decision rules (read when the inspector's suggestion needs confirming).
- `references/recipes.md`: code for every chart type, with anchors used by the inspector.
- `references/statistics.md`: which test, how to annotate, what the caption must say.
- `references/journal-specs.md`: column widths, dpi, fonts per publisher.
- `examples/demo.R` + `examples/gallery/`: runnable versions of every recipe; `examples/test_helpers.R` tests the helpers.

## Workflow

### 1. Find the context
- Locate R: `Rscript` on PATH, otherwise on Windows `C:/Program Files/R/R-*/bin/Rscript.exe`. Check that the
  packages listed at the top of `gg_pub.R` are installed; if not, give the user the `install.packages()` line.
- Look for existing figure scripts in the project (search for `ggsave`, `theme_`, `scale_color_manual`). If the
  manuscript already has figures, **match them** (palette, font, sizes, file naming); consistency within one paper
  matters more than any default here. Reuse their palettes and level orders rather than defining new ones.
- Otherwise set up `R/gg_pub.R` (copy from assets), `data/`, `figures/`, and a script based on `figure_template.R`.

### 2. Inspect the data, then decide
Run `Rscript <skill-dir>/scripts/inspect_data.R <file> [--sheet=NAME]` and read the output: column roles,
replicates per group, facets, composite labels, statistics columns, ranked suggestions and questions.
Also open the first rows yourself; the inspector is heuristic.

Then decide. State the decision in one or two sentences before plotting, e.g.
"Long table, 5 groups x 6 animals, three endpoints -> faceted points + mean ± SD per endpoint; no statistics
supplied." Use `references/chart-selection.md` when the case is not obvious.

Ask the user (one message, all questions together, each with your recommended default) **only** when the
answer changes the figure:
- two chart types are equally defensible (most common: small n, points vs. violins);
- a column's role is unclear (y? group? subject ID?), or units for axis labels are unknown;
- annotations need statistics that were not supplied (offer `compare_groups()` and name the test);
- several responses could be one faceted figure or separate figures.
Do not ask about font, theme, colors or export formats. If the user named a chart type, use it unless it would
misrepresent the data (then say why and propose the alternative).

### 3. Build
- Tidy the data in the script (pivot, `separate()` composite labels, factor levels in a meaningful order: control
  first, doses ascending). Keep raw data files untouched.
- Start from the matching recipe in `references/recipes.md`. Use `theme_pub()`, `pub_palette()` /
  `pub_shapes()` / `pub_linetypes()` with named levels, and map color plus shape or linetype together.
- Statistics: follow `references/statistics.md`. Use supplied results first; run `compare_groups()` only with the
  user's agreement; never type a p-value you did not compute or read from their files.
- Labels: units in parentheses, math via `expression()` (`"g mL"^{-1}`, `degree * "C"`, `2 * theta`); no
  redundant titles when the figure will have a caption (titles are fine for drafts and theses if the user wants them).

### 4. Size and export
`save_pub(p, "Figure_03_short_name", width = "single" | "onehalf" | "double" | <mm>, height = <mm>, journal = ...)`
writes `figures/pdf/`, `figures/tiff/` (600 dpi LZW) and `figures/png/`. Save at the real print width with
`base_size` 7-9, so text prints at 6-9 pt. Default journal preset is `default`; use the user's journal if known.

### 5. Look at the result before reporting
Render, then open the PNG (the Read tool shows images) and check:
- nothing clipped or overlapping (labels, letters, legend, facet strips, long group names);
- letters/brackets sit above the data and match the test output;
- legend order matches the data order; colors identical to the other figures;
- axis ranges sensible (bars from 0, percentages not below 0, log axes only positive values);
- text legible at final size.
Fix and re-render until clean. Never report a figure you have not looked at.

### 6. Report
Give the file paths, the chart and statistics chosen (one line each), and a draft caption that defines the
plot elements, error bars, n and test (template in `references/statistics.md`). Update the project's figure
manifest if it has one.

## Style defaults (and why)
- `theme_pub()`: classic axes, bold axis titles, faint horizontal grid, legend on top, Times New Roman via
  `pub_font()` (falls back with a warning; call `pub_font("Arial")` for journals that want sans-serif).
- Okabe-Ito-based palette (`pub_colors`) because it survives color blindness; shapes/linetypes duplicate color
  for grayscale printing.
- Raw data are shown whenever they exist (points on top of summaries) because reviewers increasingly reject
  bar-only plots of replicates.
- Violins only with enough points (~10+ per group) or when matching an existing house style;
  `layers_violin_box()` trims violins to the data range so they never imply values that were not observed.
- One script regenerates every figure from `data/`, so revisions are a re-run, not a redraw.

## Pitfalls
- Non-ASCII paths (e.g. Persian folder names): build paths with `file.path()`, run scripts by full path, and keep
  the locale line in `gg_pub.R`. With `Rscript -e`, avoid `&` and quotes; write a script file instead.
- `ggsignif`, `ggrepel` and `theme_void()` do not inherit the theme font: pass `family = pub_family()`.
- Log scales: filter out zero/negative values first, or they silently disappear with a warning.
- patchwork 1.3.1 with ggplot2 4.x warns on `plot & theme(...)`; set theme inside each panel instead.
- `stat_ellipse()` needs >= 4 points per group; `geom_violin()` with n < 3 draws nothing.
- Group names with hyphens break `multcompView` directly; `cld_letters()` and `compare_groups()` already handle it.
- Large scatter/volcano plots make heavy PDFs; prefer TIFF/PNG for those.
