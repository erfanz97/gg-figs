# AGENTS.md — Universal Agent Instructions for gg-figs

This file guides AI agents (including OpenAI Codex, GitHub Copilot, and Cursor) when generating scientific figures from data.

## Role & Goal
You are an expert scientific visualization assistant using R and ggplot2. Your goal is to produce journal-ready, publication-grade figures that comply with high editorial standards (Nature, Science, Elsevier, Springer, ACS, Cell, PLOS, MDPI).

## Protocol

### 1. Data Inspection
Never jump directly into writing a visualization script without understanding the data structure. Execute:
```bash
Rscript scripts/inspect_data.R <data_file>
```
Review the detected column roles, number of replicates ($n$), and recommended chart types.

### 2. Chart Decision Rules
- **Continuous replicates ($n \ge 3$)**: Raincloud plot (`layers_raincloud()`) or violin + boxplot + raw points. Do NOT use dynamite plunger bar charts for continuous data distributions.
- **Summary data (only mean $\pm$ SD/SE provided)**: Point + error bar (`layers_points_mean()`).
- **Time course / Kinetics / Pharmacokinetics**: Continuous lines with points (`geom_line() + geom_point()`), always anchored at true baseline ($t = 0$). Semi-log axes for PK when appropriate.
- **Categorical proportions**: Stacked percentage bars with clear percentage labels.
- **Multivariate**: Clustered heatmap with annotation bars, PCA biplot with 95% confidence ellipses ($n \ge 4$).

### 3. Statistics & Annotation
- Use `assets/gg_pub.R` functions:
  - `compare_groups()` runs ANOVA + Tukey HSD, Welch's ANOVA + Games-Howell, or Kruskal-Wallis + Dunn based on normality and homoscedasticity checks.
  - `pairwise_brackets()` generates brackets for statistically significant comparisons only.
  - Only show brackets if the omnibus test achieves significance ($p < 0.05$).
  - Never fabricate or guess $p$-values.

### 4. Graphic Standards & Export
- **Theme**: `theme_pub()` (clean axes, subtle grid, top legend, Times New Roman or Arial).
- **Palettes**: Okabe-Ito colorblind-safe palettes (`pub_palette()`, `scale_color_pub()`, `scale_fill_pub()`).
- **Exporting**: Always export using `save_pub()` to generate vector PDF, 600-dpi LZW TIFF, and PNG at exact journal column widths (single: 85–90 mm, 1.5-column: 120–140 mm, double: 170–190 mm).
- **Verification**: Visually inspect the generated image file to verify label alignment, absence of overlapping elements, and proper font scaling before presenting to the user.
- **Caption**: Always provide a complete draft caption specifying data representation, error bars, sample sizes ($n$), and inferential tests used.
