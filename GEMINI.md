# gg-figs — Gemini & Google Antigravity Developer Guide

This repository provides an agent skill and helper toolkit for generating **publication-quality scientific figures in R using ggplot2**.

## Agent Instructions for Gemini / Antigravity

When a user requests figures, plots, or charts from data files (CSV, TSV, Excel):

### 1. Locate R Runtime
- On Windows: Check `Get-Command Rscript` or find `Rscript.exe` under `C:\Program Files\R\R-*\bin\Rscript.exe`.
- On Linux/macOS: Run `which Rscript` or use standard `Rscript` on PATH.
- Run shell commands using `run_command` (PowerShell on Windows, Bash on Unix).

### 2. Inspect the Data First
Before writing a plotting script, always run the inspector script:
```bash
Rscript scripts/inspect_data.R <path/to/data_file>
```
The inspector outputs:
- Column roles (response variable, grouping factor, covariates, time points, etc.)
- Replicate structure (number of samples per group)
- Ranked chart suggestions
- Open questions (if any design ambiguity exists)

### 3. Build Reproducible Figure Scripts
- Always source `assets/gg_pub.R` in the project script (`R/make_figures.R` or `figure.R`).
- Follow the publication design principles:
  - **Raw replicates (n >= 3)**: Raincloud (`layers_raincloud()`) or violin + box + points (`layers_violin_box()`). Never bar charts with error bars for continuous raw data.
  - **Time series**: Connected points/lines starting at true baseline ($t = 0$).
  - **Colorblind safety**: Use Okabe-Ito palettes (`pub_palette()`, `scale_color_pub()`, `scale_fill_pub()`).
  - **Statistical brackets**: Compute comparisons using `compare_groups()`. Only display brackets for significant pairs (`pairwise_brackets()` -> `geom_brackets()`) if the omnibus test is significant ($p < 0.05$). Never print ANOVA text inside plot panels.
  - **Exporting**: Use `save_pub(p, "Figure_name", width = "single"|"onehalf"|"double", journal = "default"|...)` which outputs vector PDF, 600-dpi LZW TIFF, and PNG at journal dimensions.

### 4. Visual Verification
- After generating the figure, **always inspect the rendered PNG** using `read_file` on the image path. Antigravity will display the rendered image in your context.
- Verify that text is legible, axis labels include units in parentheses, brackets do not collide, and group legends are clear.

### 5. Report & Presentation
- Provide clickable links to the exported files using the `file:///` scheme: e.g. `[Figure_01.png](file:///path/to/figures/png/Figure_01.png)`.
- Draft a complete publication caption describing:
  - The graphical elements (lines, symbols, ribbons).
  - The statistical summary (mean ± SD or median + IQR).
  - Sample sizes ($n$ per group).
  - The exact statistical test applied with adjusted $p$-value threshold.
