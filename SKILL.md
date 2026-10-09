---
name: gg-figs
description: Publication-quality scientific figures in R/ggplot2 for articles, theses and revisions. Given a data file (CSV/Excel) or a figure request, it inspects the data, picks the chart itself (raincloud/violin + box + points, mean ± SD, time courses, PK, dose-response, calibration, Bland-Altman, ROC, Kaplan-Meier, volcano, forest, heatmaps, PCA, ridgelines, response surfaces, rheology, XRD/FTIR/DSC/TGA, multi-panel plates) and asks only when the choice is genuinely ambiguous. Adds only supported statistics (ANOVA/Tukey, Welch/Games-Howell, Kruskal/Dunn) as adjusted p-value brackets, uses colorblind-safe palettes, exports vector PDF + 600-dpi TIFF/PNG at journal widths. Works with every ggplot2 geom, stat, scale, coord, facet, guide and theme. Use whenever the user wants to plot, chart, visualize or restyle data for a paper, manuscript, thesis or reviewer response in R, even without saying "ggplot2", for example "make a figure from this csv" or "same style as my other figures".
---

# gg-figs: publication figures with ggplot2

Goal: turn the user's data into a figure a journal accepts on first submission: the right chart for the data,
honest statistics, one consistent style, correct size and format. Users usually hand over a data file and expect
you to choose; asking about everything defeats the purpose, while guessing on a real ambiguity produces a figure
they have to redo.

The skill is a thin layer on ggplot2, so every ggplot2 option stays available: add any geom, stat, position,
scale, coord, facet, guide or `theme()` call to the skill's plots (see `references/ggplot2-reference.md`).

## Files in this skill
- `assets/gg_pub.R`: helper library. Copy it into the project (e.g. `R/gg_pub.R`) and `source()` it, so the
  project stays reproducible without the skill. Contains `theme_pub()`, palettes, `scale_*_pub()`,
  `compare_groups()`, `pairwise_brackets()`/`geom_brackets()`, `cld_letters()`, `layers_violin_box()`,
  `layers_raincloud()`, `geom_half_violin()`, `layers_points_mean()`, `spread_labels()`, `save_pub()`.
- `assets/figure_template.R`: skeleton for a project figure script.
- `scripts/inspect_data.R`: profiles a data file and ranks chart suggestions plus the open questions.
- `scripts/ggplot2_api.R`: lists what the installed ggplot2 supports (functions, arguments, aesthetics, theme elements).
- `references/chart-selection.md`: how to pick the chart (read when the inspector's suggestion needs confirming).
- `references/recipes.md`: code for 24 chart types (matching `examples/gallery.R`).
- `references/ggplot2-reference.md`: the whole ggplot2 API in one page, version differences, extension packages.
- `references/statistics.md`: which test, how to annotate, what the caption must say.
- `references/journal-specs.md`: column widths, dpi, fonts per publisher.
- `examples/gallery.R` + `examples/gallery/`: 24 runnable, simulated-data examples; `examples/test_helpers.R` and
  `examples/test_ggplot2_compat.R` test the helpers and the compatibility with the ggplot2 API.

## Workflow

### 1. Find the context
- Locate R: `Rscript` on PATH, otherwise on Windows `C:/Program Files/R/R-*/bin/Rscript.exe`. Check the packages
  listed at the top of `gg_pub.R`; if any are missing, give the user the `install.packages()` line.
- Look for existing figure scripts in the project (`ggsave`, `theme_`, `scale_color_manual`). If the manuscript
  already has figures, **match them** (palette, font, sizes, file names, group order); consistency within one
  paper matters more than any default here. Reuse their palettes and level orders.
- Otherwise set up `R/gg_pub.R` (copy), `data/`, `figures/`, and a script from `assets/figure_template.R`.

### 2. Inspect the data, then decide
Run `Rscript <skill-dir>/scripts/inspect_data.R <file> [--sheet=NAME]` and read the output: column roles,
replicates per group, facets, composite labels, statistics columns, ranked suggestions and questions. Also look at
the first rows yourself; the inspector is heuristic.

State the decision in one or two sentences before plotting, e.g. "Long table, 5 groups x 6 animals, three
endpoints -> faceted violin + box + points per endpoint; no statistics supplied." Use
`references/chart-selection.md` for unclear cases.

Ask the user (one message, all questions together, each with your recommended default) **only** when the answer
changes the figure:
- two chart types are equally defensible;
- a column's role is unclear (y? group? subject ID?), or axis units are unknown;
- annotations need statistics that were not supplied (offer `compare_groups()`, name the test);
- several responses could be one faceted figure or separate figures.

Do not ask about font, theme, colors or export formats. If the user named a chart type, use it unless it would
misrepresent the data (then say why and propose the alternative).

### 3. Build
- Tidy the data in the script (pivot, `separate()` composite labels, factor levels in a meaningful order: control
  first, doses ascending). Never edit raw data files.
- Start from the matching recipe in `references/recipes.md`. Use `theme_pub()`, named palettes (`pub_palette()`,
  `pub_shapes()`, `pub_linetypes()`), color plus shape/linetype together. Any other ggplot2 feature can be added
  with `+`; if unsure about an argument, check `scripts/ggplot2_api.R <function>` instead of guessing.
- Defaults that apply unless the user or the project says otherwise:
  - **Raw replicates (3+ per group):** show every observation: violin + box + points (raincloud for n >= 10),
    never bars with error bars.
  - **Significance:** adjusted p-value **brackets for significant pairs only**, and only when the omnibus test is
    significant (`compare_groups()` -> `pairwise_brackets()` -> `geom_brackets()`). **No compact letters** unless
    the user asks for them. No "ANOVA ..." sentences inside panels; put the test in the caption.
  - **Time series** (release, permeation, PK, growth, body weight over time): lines + points starting at the true
    baseline (t = 0), never bars or violins over time.
  - **Summary-only data** (mean, SD, n): points with error bars; say that violin/box needs the raw values and
    ask for them instead of inventing replicates.
- Statistics: follow `references/statistics.md`. Use supplied results first; run `compare_groups()` only with the
  user's agreement; never type a p-value you did not compute or read from their files.
- Labels: units in parentheses, math via `expression()`; no redundant titles when the figure will have a caption.

### 4. Size and export
`save_pub(p, "Figure_03_short_name", width = "single" | "onehalf" | "double" | <mm>, height = <mm>, journal = ...)`
writes PDF (vector), 600-dpi LZW TIFF and PNG into `figures/pdf`, `figures/tiff`, `figures/png`. Save at the real
print width with `base_size` 7-9 so text prints at 6-9 pt. Default journal preset is `default`; use the user's
journal if known (`references/journal-specs.md`).

### 5. Look at the result before reporting
Render, then open the PNG (the Read tool shows images) and check:
- nothing clipped or overlapping (labels, brackets, legend, strips, long group names);
- brackets sit above the data and match the test output;
- legend order matches the data order; colors identical to the other figures;
- axis ranges sensible (bars from 0, percentages not below 0, log axes only positive values, no stray tick marks
  on inner facets);
- text legible at final size.
Fix and re-render until clean. Never report a figure you have not looked at.

### 6. Report and get approval
Give the file paths, the chart and statistics chosen (one line each) and a draft caption (what each element is,
error-bar type, n, test; template in `references/statistics.md`). When the user is reviewing figures one by one
(revisions, theses), send each new or redrawn figure (`SendUserFile` if available, otherwise the path) and wait for
approval before inserting it anywhere or writing dependent text. Update the project's figure manifest if it has one.

## Style defaults (and why)
- `theme_pub()`: classic axes, bold axis titles, faint horizontal grid, legend on top, Times New Roman via
  `pub_font()` (falls back with a warning; `pub_font("Arial")` for journals that want sans-serif).
- Okabe-Ito-based palette because it survives color blindness; shapes and linetypes duplicate color for grayscale.
- `layers_violin_box()` trims violins to the data range so they never imply values that were not observed.
- Direct labels at line ends (`spread_labels()`) instead of legends when there are 2-5 series.
- One script regenerates every figure from `data/`, so a revision is a re-run, not a redraw.

## Pitfalls
- Non-ASCII paths (e.g. Persian or other non-Latin folder names): build paths with `file.path()`, run scripts by
  full path, write script files rather than long `Rscript -e` one-liners, and keep the locale line in `gg_pub.R`.
  Use `\u` escapes for special characters in R code (`"\u00b5"`, `"\u2212"`).
- `ggrepel` and `theme_void()` do not inherit the theme font: pass `family = pub_family()`.
- Log scales: filter out zero/negative values first. `annotation_logticks()` draws on every facet; use it only on
  single-panel plots.
- `scale_*_continuous(limits = )` drops data outside the range; zoom with `coord_cartesian()` instead.
- patchwork 1.3.1 with ggplot2 4.x warns on `plot & theme(...)`; set the theme inside each panel.
- `stat_ellipse()` needs >= 4 points per group; `geom_violin()` with fewer than 3 points per group draws nothing.
- Group names with hyphens break `multcompView` directly; `cld_letters()` and `compare_groups()` handle them.
- Large scatter/volcano plots make heavy PDFs; also export TIFF/PNG.
- Paired t-test: `t.test(x, y, paired = TRUE)`; the formula method no longer accepts `paired` (R >= 4.4).
