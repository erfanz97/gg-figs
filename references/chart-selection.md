# Chart selection

Choose the chart from what the data are, not from habit. Work through the questions in
order; the first one that applies usually decides. `scripts/inspect_data.R` automates the
first pass; this page is for confirming or overriding it.

## 1. What is the question the figure answers?

| Question | Chart family |
|---|---|
| Do groups differ? | group comparison (section 3) |
| How does y change along a continuous x (time, dose, temperature, frequency, angle)? | profiles/curves (section 4) |
| How are two continuous variables related? | scatter (+ fit) |
| What does a signal look like (spectrum, thermogram, diffractogram)? | instrument curves |
| How long until an event? | Kaplan-Meier |
| Which of thousands of features changed? | volcano / heatmap |
| How large are effects and how uncertain? | forest plot |
| How do many variables co-vary / do samples cluster? | correlation heatmap / PCA |
| What share belongs to each category? | bars (stacked or 100%) |

If the user's request and the data disagree (e.g. "bar chart" for raw replicates), follow the
user unless the requested chart would hide or misstate the data; then explain and propose the
alternative in one sentence.

## 2. What is in each row?

| Data shape | Implication |
|---|---|
| One row per observation (long, "tidy") | ready to plot |
| One column per group, values below (wide) | `pivot_longer()` first |
| Only mean / SD / SE / n | summary-only: points + error bars; no violins, boxes or jittered points |
| One value per group | bars or dots, no error bars, no inferential statistics |
| A subject/animal ID repeated across conditions | paired / repeated-measures design: connect each subject |
| Replicate index (rep 1..n) restarting in each group | independent replicates, not pairing |
| A label like "Drug 5 mg" or "1:2, 12%" | two crossed factors in one column: `separate()` |
| Columns with p, padj, letters | statistics already computed: use them, do not recompute |
| endpoint / parameter / analyte column | facets (`facet_wrap(scales = "free_y")`) |

## 3. Group comparisons: how many values per group?

| n per group | Default | Notes |
|---|---|---|
| >= 10 | raincloud or violin + box + points | distribution shape is interpretable |
| 3-9 | violin + box + points (`trim = TRUE`, so it never extends beyond the data) | with n < 6 the violin shape is weak; points + mean +/- SD is the alternative, mention it once |
| 1-2 | dots or bars, no error bars | say "single measurement" in the caption |
| summary only | mean +/- SD points | state SD vs SE; raw values are needed for violin/box |

Show every observation whenever raw data exist. Significance: adjusted p-value **brackets** for significant pairs
(after a significant omnibus test); letters only on request.

Layout: one factor -> x = group, color = group (legend off). Two factors -> x = the factor with
more levels or the natural order (dose, time), color/dodge = the other; or facet by one when
dodging would put > 4 boxes per x position. More than ~8 groups on one axis -> facet or reorder.

## 4. Continuous x

| Situation | Chart |
|---|---|
| Replicates at each x | mean +/- SD line (error bars or ribbon), optionally faint individual traces; start at the baseline (t = 0), never bars/violins over time |
| One measurement per x, many x values | line only (curve) |
| One measurement per x, few x values (calibration standards) | points + fitted model |
| x spans orders of magnitude (frequency, shear rate, dose, concentration) | log axis (`scale_x_log10`), log ticks |
| Several samples of the same signal | overlay (<= 4 samples) or vertical offset stack (> 4, or overlapping) |
| Two y quantities on different scales | two panels stacked with patchwork, never a dual y-axis |

## 5. Encoding rules

- Color is redundant with shape and/or linetype, so the figure works in grayscale and for color-blind readers.
- Keep a group's color identical across all figures in a paper (define named palettes once).
- Ordered categories (doses, concentrations) can use a sequential ramp (`pub_ordered()`); unordered use `pub_palette()`.
- Max ~8 colors in one panel; beyond that facet or highlight a subset with grey for the rest.
- Start bar axes at zero. Points/lines/boxes need not.
- Prefer direct labels (text at line ends) over legends when there are 2-4 series.
- No 3D, no shadows, no pie charts, no dual y-axes, no chart junk.

## 6. When to ask the user

Ask (one message, with a recommended default) only if the answer changes the figure:
- two chart types are equally defensible (typical: small n -> points vs. violin to match other figures);
- the role of a column is unclear (which is y, which is the group, is the ID a subject);
- statistics are required for annotations but not supplied (offer to run `compare_groups()`, name the test);
- several response columns could be facets of one figure or separate figures;
- target journal / column width is unknown and the figure is complex (otherwise default to double column).
Never ask about font, theme, palette or export formats; the skill defaults settle those.
