# CLAUDE.md — Claude Code Guide for gg-figs

Guidelines for Claude Code when developing or using `gg-figs`:

## Primary Directives
- **Workflow**: Always inspect data first with `Rscript scripts/inspect_data.R <data_file>`, confirm chart selection, write reproducible R code referencing `assets/gg_pub.R`, export with `save_pub()`, and visually verify with the `Read` tool before reporting.
- **Visual Check**: Open the exported PNG in `figures/png/` with `Read` to ensure no clipped text, legible labels at print size, and proper bracket placement.
- **Reporting**: Report output paths, provide a draft caption, and use `SendUserFile` when delivering figures for user review.
- **Style & Stats**: Use Okabe-Ito colorblind palettes, show raw points for replicates ($n \ge 3$), only show adjusted p-value brackets when omnibus test is significant ($p < 0.05$), and avoid dynamite plunger bar charts.
