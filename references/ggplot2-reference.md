# ggplot2 reference: every option, and how it works with gg-figs

The skill is a thin layer on top of ggplot2. Nothing here replaces ggplot2: `theme_pub()` is a complete theme,
`scale_*_pub()` are ordinary scales, `layers_*()` return plain lists of layers, and `save_pub()` saves any
ggplot or patchwork object. Anything ggplot2 can do can be added with `+`.

To check what the **installed** version supports, never guess:

```bash
Rscript scripts/ggplot2_api.R                  # all exported functions by family
Rscript scripts/ggplot2_api.R geom_boxplot     # arguments, aesthetics, defaults, stat, position
Rscript scripts/ggplot2_api.R theme            # every theme() element
Rscript scripts/ggplot2_api.R "scale_*_viridis*"
```

`examples/test_ggplot2_compat.R` builds and draws a plot for every geom, stat, position, scale, coord, facet,
guide, annotation, labeller, legend key and theme exported by the installed ggplot2 (with `theme_pub()` applied)
and fails if any breaks. It currently covers 301 of 322 exports on ggplot2 4.0.1 (the rest are internals or need
extra packages such as maps/hexbin/quantreg).

## Contents
1. [Anatomy of a plot](#anatomy-of-a-plot)
2. [Geoms](#geoms) and [stats](#stats)
3. [Positions](#positions)
4. [Scales](#scales)
5. [Coordinates](#coordinates)
6. [Facets](#facets)
7. [Guides and legends](#guides-and-legends)
8. [Themes](#themes)
9. [Labels, annotations, computed variables](#labels-annotations-computed-variables)
10. [ggplot2 3.5 vs 4.x](#ggplot2-35-vs-4x)
11. [Extension packages that work with the skill](#extension-packages)
12. [Mapping gg-figs helpers onto ggplot2](#mapping-gg-figs-helpers-onto-ggplot2)

---

## Anatomy of a plot
`ggplot(data, aes(...))` + layers (`geom_*` / `stat_*`) + scales + coord + facet + theme.
- `aes()` maps columns to aesthetics (x, y, colour/color, fill, shape, linetype, linewidth, size, alpha, group, label, ...).
  Constants go **outside** `aes()`: `geom_point(colour = "red")`.
- Each layer has a **stat** (computes), a **geom** (draws), a **position** (adjusts overlap). `geom_bar()` = `stat_count()`;
  `stat_summary(geom = "pointrange")` = a summary drawn as pointrange. Either name works.
- Use `group =` to define which observations connect (lines, boxes, violins). `interaction(a, b)` for two factors.
- Order of `+` matters for drawing: later layers are on top.

## Geoms
| Purpose | Geoms | Notes for publication figures |
|---|---|---|
| Points / scatter | `geom_point`, `geom_jitter`, `geom_count`, `geom_rug` | `shape = 21:25` take `fill` and `colour` (hollow markers) |
| Lines / paths | `geom_line` (sorted by x), `geom_path` (data order), `geom_step`, `geom_segment`, `geom_curve`, `geom_spoke`, `geom_abline/hline/vline` | `linewidth` (not `size`) since 3.4 |
| Areas / bands | `geom_area`, `geom_ribbon`, `geom_rect`, `geom_polygon`, `geom_tile`, `geom_raster` | `geom_raster` is fastest for regular grids; `geom_tile` for irregular |
| Bars / counts | `geom_bar` (counts), `geom_col` (values), `geom_histogram`, `geom_freqpoly`, `geom_dotplot` | bars start at zero, keep them for counts/proportions |
| Distributions | `geom_boxplot`, `geom_violin`, `geom_density`, `geom_density_2d(_filled)`, `geom_qq`, `geom_qq_line` | `geom_boxplot(staplewidth =)`, `outlier.shape = NA` when points are shown |
| Intervals | `geom_errorbar` (`orientation = "y"` for horizontal), `geom_linerange`, `geom_pointrange`, `geom_crossbar` | `geom_errorbarh` is deprecated in 4.x |
| Smooths / fits | `geom_smooth(method = "lm"/"loess"/"glm", formula =, se =, level =)`, `geom_quantile` | always give `formula =` to silence the message |
| Surfaces | `geom_contour`, `geom_contour_filled`, `geom_density_2d_filled`, `geom_bin_2d`, `geom_hex` | needs `z` for contours; `bins =` or `breaks =` |
| Text | `geom_text`, `geom_label` | pass `family = pub_family()` or use the default patched by `pub_font()`; `parse = TRUE` for plotmath |
| Functions | `geom_function`, `stat_function` | `fun = dnorm, args = list(...)` |
| Maps | `geom_sf`, `geom_sf_text`, `geom_sf_label`, `coord_sf`, `geom_map` | sf data needs `coord_sf()`; `geom_map` needs the maps package |
| Utility | `geom_blank` | extends scale ranges without drawing (used by `geom_brackets()`) |

## Stats
`stat_summary(fun.data = mean_se | mean_sdl | mean_cl_normal | mean_cl_boot | median_hilow, ...)`,
`stat_summary_bin`, `stat_summary_2d`, `stat_summary_hex`, `stat_bin`, `stat_bin_2d`, `stat_bin_hex`, `stat_count`,
`stat_density`, `stat_density_2d(_filled)`, `stat_ecdf`, `stat_ellipse(type = "t"/"norm"/"euclid", level =)`,
`stat_smooth`, `stat_quantile`, `stat_function`, `stat_qq`, `stat_qq_line`, `stat_contour(_filled)`, `stat_boxplot`,
`stat_ydensity` (violins), `stat_sum`, `stat_unique`, `stat_identity`, `stat_align` (aligns areas),
`stat_connect(connection = "hv"/"vh"/...)` and `stat_manual(fun =)` (new in 4.0), `stat_sf`, `stat_sf_coordinates`.
Custom summaries: `stat_summary(fun = mean, fun.min = function(x) mean(x) - sd(x), fun.max = ..., geom = "errorbar")`
or the helper `mean_error_fun("sd" | "se" | "ci95")` from gg_pub.R.

## Positions
`position_dodge(width, preserve)`, `position_dodge2` (boxplots, bars with varying width), `position_jitter(width, height, seed)`,
`position_jitterdodge(jitter.width, dodge.width)` (points over dodged boxes), `position_nudge(x, y)`, `position_stack(vjust, reverse)`,
`position_fill`, `position_identity`. Use the **same dodge width** for every layer that must line up.

## Scales
Pattern: `scale_<aesthetic>_<type>()`. All accept `name`, `breaks`, `labels`, `limits`, `expand`, `na.value`,
`guide`, `position`, `transform` (called `trans` before 3.5), `oob`, `sec.axis` (position scales).

| Aesthetic | Types |
|---|---|
| x, y (position) | `_continuous`, `_discrete`, `_binned`, `_log10`, `_sqrt`, `_reverse`, `_date`, `_datetime`, `_time`; helpers `xlim()`, `ylim()`, `lims()`, `expand_limits()`, `expansion(mult =, add =)`, `sec_axis()`, `dup_axis()` |
| colour / color / fill | discrete: `_hue`, `_brewer`, `_grey`, `_viridis_d`, `_manual`, `_discrete`, `_ordinal`, `_identity` ; continuous: `_gradient`, `_gradient2`, `_gradientn`, `_viridis_c`, `_distiller`, `_continuous`, `_date`, `_datetime` ; binned: `_steps`, `_steps2`, `_stepsn`, `_binned`, `_viridis_b`, `_fermenter` |
| size, radius | `scale_size`, `scale_size_area`, `scale_size_binned(_area)`, `scale_radius`, `_manual`, `_identity`, `_discrete`, `_ordinal`, `_date(time)` |
| alpha, linewidth | `_continuous`, `_binned`, `_discrete`, `_ordinal`, `_manual`, `_identity`, `_date(time)` |
| shape, linetype | `_discrete`, `_ordinal`, `_manual`, `_identity`, `_binned` (continuous variables cannot map to shape/linetype) |
| generic | `continuous_scale()`, `discrete_scale()`, `binned_scale()`, `scale_discrete_manual(aesthetics, values)`, `scale_continuous_identity()`, `scale_discrete_identity()` |

House scales (work with any geom): `scale_colour_pub()`, `scale_color_pub()`, `scale_fill_pub()`, `scale_shape_pub()`,
`scale_linetype_pub()` (discrete, recycle the palette in level order) and `scale_{fill,colour}_pub_seq()` /
`scale_{fill,colour}_pub_div()` (sequential, diverging; all gradient arguments pass through). For fixed group-colour
mapping across a paper use `pub_palette(levels)` with `scale_*_manual(values = ...)`.

Label formatters from `scales`: `label_number(big.mark = ",", accuracy =)`, `label_percent()`, `label_comma()`, `label_log()`,
`label_scientific()`, `label_math()`, `label_pvalue()`, `label_date()`; break helpers `breaks_pretty()`, `breaks_width()`,
`breaks_log()`, `breaks_extended()`; out-of-bounds `oob_squish`, `oob_censor`, `oob_keep`.

## Coordinates
`coord_cartesian(xlim, ylim, expand, clip)` zooms without dropping data (prefer over `xlim()` for zooming; scale
limits remove data), `coord_flip()`, `coord_fixed(ratio)` / `coord_equal()`, `coord_polar()`, `coord_radial()` (4.x: inner radius,
`guide_axis_theta()` via `guides(theta = ...)`), `coord_transform()` (`coord_trans()` before 4.0), `coord_sf()`, `coord_map()`,
`coord_quickmap()`. `clip = "off"` lets annotations and direct labels sit outside the panel (add plot margin).

## Facets
- `facet_wrap(vars(a, b), nrow, ncol, scales = "fixed"/"free"/"free_x"/"free_y", dir, strip.position, axes = "margins"/"all"/"all_x"/"all_y", axis.labels, labeller, space = "free_x" (grid only))`.
- `facet_grid(rows = vars(a), cols = vars(b), scales, space = "free", switch = "x"/"y"/"both", margins, labeller)`.
- Labellers: `label_value`, `label_both`, `label_context`, `label_parsed`, `label_bquote`, `label_wrap_gen(width)`, or
  `labeller(var = c(old = "New label"))`; labels with `\n` for a second line (e.g. "Overall p = 0.04").
- Free scales + per-panel annotations: compute positions per panel (`annotation_y(..., facet = )`, `pairwise_brackets(..., facet = )`).
- Different geoms per panel are better done with patchwork.

## Guides and legends
`guides(colour = guide_legend(nrow, ncol, byrow, reverse, override.aes = list(size = 3), title.position, order), fill = guide_colourbar(barheight, barwidth, ticks.colour, reverse), size = guide_bins(), colour = guide_coloursteps(even.steps), x = guide_axis(angle, n.dodge, minor.ticks, cap), x = guide_axis_logticks(), theta = guide_axis_theta(), x = guide_axis_stack(), colour = guide_none(), guide_custom())`.
`theme(legend.position = "top"/"bottom"/"left"/"right"/"inside", legend.position.inside = c(x, y), legend.direction, legend.justification, legend.key.size, legend.key.width, legend.title, legend.text, legend.box = "vertical")`.
Key glyphs: `geom_point(key_glyph = draw_key_rect)` and all `draw_key_*` functions. Prefer direct labels (text at line ends) over
a legend when there are 2-5 series (`spread_labels()` prevents overlap). Merge legends by giving mapped aesthetics the same `name`.

## Themes
- Complete themes: `theme_gray/grey`, `theme_bw`, `theme_linedraw`, `theme_light`, `theme_dark`, `theme_minimal`, `theme_classic`,
  `theme_void`, `theme_test`, and the house `theme_pub(base_size, grid, legend, border, ...)`.
- `theme(...)` elements: `text`, `line`, `rect`, `title`, `axis.title(.x/.y)`, `axis.text(.x/.y)`, `axis.line`, `axis.ticks`,
  `axis.ticks.length`, `axis.minor.ticks.*`, `panel.background`, `panel.border`, `panel.grid(.major/.minor)(.x/.y)`, `panel.spacing(.x/.y)`,
  `plot.title`, `plot.subtitle`, `plot.caption`, `plot.tag`, `plot.margin`, `plot.background`, `plot.title.position`, `strip.background`,
  `strip.text`, `strip.placement`, `legend.*` (above). Element constructors: `element_text()`, `element_line()`, `element_rect()`,
  `element_blank()`, `element_point()`, `element_polygon()`, `element_geom()` (4.x). `rel()` for relative sizes, `margin()`, `unit()`.
- 4.x extras: `theme_sub_*()` (sub-theme helpers), `theme(geom = element_geom(ink, paper, pointsize, linewidth, ...))`.
- `theme_set()`, `theme_update()`, `theme_replace()`, `theme_get()` change the session default.
- Adding another complete theme after `theme_pub()` replaces it; add `theme(...)` calls **after** it to tweak.
- Text sizes are in points at final print size when you save with `save_pub()` at the real width.

## Labels, annotations, computed variables
- `labs(title, subtitle, caption, tag, x, y, colour, fill, shape, ...)`, `xlab()`, `ylab()`, `ggtitle()`. Math: `expression()`, `bquote()`,
  `label_parsed`; `parse = TRUE` in text geoms; Unicode via `µ` (micro), `°` (degree), `−` (minus) in R strings.
- `annotate("text"/"label"/"segment"/"rect"/"curve"/"pointrange", ...)`, `annotation_custom(grob)`, `annotation_raster()`,
  `annotation_logticks(sides = "bl")`, `annotation_map()`, `annotation_borders()`. Avoid `annotation_logticks()` on faceted plots
  (ticks appear on every panel, including linear ones).
- Computed variables: `after_stat(count)`, `after_scale(alpha(fill, 0.3))`, `stage(start, after_stat, after_scale)`
  (e.g. histogram heights as density: `aes(y = after_stat(density))`).
- Inspect: `layer_data(p)`, `layer_scales(p)`, `ggplot_build(p)`, `get_labs(p)`, `ggplot_gtable()`.

## ggplot2 3.5 vs 4.x
The helpers require ggplot2 >= 3.5.0 and are tested on 4.0.1. Differences that matter:
| Change | Do this |
|---|---|
| `coord_trans()` renamed `coord_transform()` (4.0) | use `coord_transform()` |
| `geom_errorbarh()` deprecated | `geom_errorbar(orientation = "y")` |
| `stat_spoke()` removed | `geom_spoke()` |
| `trans =` argument renamed `transform =` (3.5) | use `transform =` |
| `size =` for lines replaced by `linewidth =` (3.4) | use `linewidth` |
| `label.size` in `geom_label()` became `linewidth`/`border.colour` (4.0) | leave the default border or build the box with `annotate("rect")` |
| objects are S7 (4.0): `p$labels` etc. changed | use `get_labs(p)`, `layer_data()` accessors |
| `facet_wrap(axes =, axis.labels =)`, `stat_connect`, `stat_manual`, `theme(geom =)`, `theme_sub_*` new in 4.0 | only use when `packageVersion("ggplot2") >= "4.0.0"` |
| `patchwork 1.3.1` + 4.0: `plot & theme()` warns "annotation$theme is not a valid theme" | set the theme inside each panel instead |

## Extension packages
All were tested with the house theme; `requireNamespace()` before use and tell the user what to install.
| Package | Use |
|---|---|
| patchwork | multi-panel plates (`|`, `/`, `wrap_plots(design=)`, `plot_annotation(tag_levels)`, `plot_layout(guides = "collect")`) |
| ggrepel | non-overlapping labels (`geom_text_repel`, `geom_label_repel`); pass `family = pub_family()` |
| ggridges | ridgeline plots (`geom_density_ridges`, quantile lines) |
| ggsignif | alternative significance brackets (the skill's own `geom_brackets()` needs no extra package) |
| ggbeeswarm, ggforce | beeswarm points; ellipses, zoom facets, arcs, `geom_mark_*` |
| ggtext, gridtext | markdown/HTML in labels (`element_markdown()`), italic species names |
| ggnewscale | a second colour/fill scale in one plot |
| ggh4x | nested facets, individual panel scales, facet sizing |
| ggdist, gghalves | densities with intervals, half geoms (the skill has its own `geom_half_violin()`) |
| survival, survminer | survival models; the skill draws KM curves with plain ggplot2 |
| pROC | ROC curves and AUC confidence intervals |
| scales | label/break helpers (loaded by gg_pub.R) |
| cowplot, gridExtra | older layout tools; prefer patchwork |
| ComplexHeatmap, pheatmap | clustered heatmaps with dendrograms (grid-based, not ggplot2); use a ggplot2 heatmap when the figure must match other panels |

## Mapping gg-figs helpers onto ggplot2
| Helper | What it is |
|---|---|
| `theme_pub()` | complete theme; `...` goes to `theme()`; `legend` accepts any `legend.position` |
| `scale_*_pub()`, `pub_palette()`, `pub_shapes()`, `pub_linetypes()`, `pub_ordered()` | scales / named vectors for `scale_*_manual()` |
| `layers_violin_box()`, `layers_raincloud()`, `layers_points_mean()` | lists of ordinary layers; combine with any other layer, facet, scale or coord |
| `geom_half_violin()` | a real geom (ggproto) with the stat arguments of `geom_violin()` |
| `pairwise_brackets()` + `geom_brackets()` | data + `geom_segment`/`geom_text`/`geom_blank` layers; work with `facet_wrap(scales = "free_y")` |
| `compare_groups()`, `cld_letters()`, `summarise_mean_error()`, `annotation_y()`, `spread_labels()` | data helpers, no plotting |
| `save_pub()` | wrapper of `ggsave()`; extra arguments pass through (`scale`, `limitsize`, ...) |
