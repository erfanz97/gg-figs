# Statistics on figures

A figure may only claim what an analysis supports. Reviewers compare letters and stars against
the methods section, so every annotation must trace back to a named test.

## Source of truth
1. Statistics supplied by the user (result tables, `*_pairwise.csv`, `*_omnibus.csv`, SPSS/GraphPad output): use them as is.
2. None supplied and the figure is a comparison: ask whether to run tests. If yes, use `compare_groups()` and report
   the test it chose. Never invent, round toward significance or hard-code a p-value you did not compute or read.
3. Summary-only data, single instrumental runs, n = 1: no inferential marks.

## Choosing the test (one factor)

| Design | Assumptions OK | Unequal variances | Non-normal / ordinal |
|---|---|---|---|
| 2 independent groups | Student's t | Welch's t (sensible default) | Mann-Whitney U |
| 2 paired groups | paired t | -- | Wilcoxon signed-rank |
| > 2 independent groups | one-way ANOVA + Tukey HSD | Welch's ANOVA + Games-Howell | Kruskal-Wallis + Dunn (Holm) |
| > 2 repeated conditions | RM-ANOVA / linear mixed model | mixed model | Friedman + Nemenyi/Conover |

`compare_groups(data, "value", "group", method = "auto")` checks residual normality (Shapiro-Wilk) and variance
homogeneity (Fligner-Killeen) and picks ANOVA/Tukey, Welch/Games-Howell or Kruskal/Dunn. With n = 3 per group these
diagnostics have almost no power; say so, or let the user choose `method =` explicitly. Its Tukey, Dunn and
Games-Howell p-values are tested against `TukeyHSD()` and `rstatix` in `examples/test_helpers.R`.

Two crossed factors (e.g. drug x dose): two-way ANOVA `aov(value ~ A * B)`; if the interaction is
significant compare cells (one-way on the combined factor, Tukey), otherwise main effects. With `emmeans`:
`emmeans(fit, pairwise ~ A | B, adjust = "tukey")`.

Time courses with replicates: do not run a t-test at every time point. Use a mixed model
(`lme4::lmer(value ~ group * factor(time) + (1 | replicate))`) or compare a summary per replicate (AUC, t50, plateau)
with a one-way test and plot that summary as its own panel.

Multiple endpoints in one figure: test each endpoint separately; mention whether p-values are adjusted across endpoints.

## Annotation formats

Default: **adjusted p-value brackets for significant pairs only, drawn only when the omnibus test is significant**
(`compare_groups()` -> `pairwise_brackets()` -> `geom_brackets()`; `vs = "Control"` keeps comparisons against one group).
Compact letters are available (`cld_letters()`) but only used when the user asks for them.

| Situation | Show |
|---|---|
| Omnibus significant and some adjusted pairs significant | brackets for those pairs with exact p(adj) (or stars); post-hoc method in the caption |
| Treatment vs control only | `pairwise_brackets(..., vs = "Control")` |
| Letters requested | `cld_letters()`; "groups sharing a letter do not differ (Tukey HSD, p < 0.05)" |
| Omnibus significant, no adjusted pair significant | no brackets; "Overall p = 0.043; pairwise ns" in the caption or facet strip |
| Nothing significant | omnibus p in the caption; no marks |
| Regression / calibration | equation and R^2 on the plot or in the caption |
| Survival | log-rank p on the plot; HR (95% CI) in caption if a Cox model was fitted |

p-value style: exact to 3 decimals, "p < 0.001" below that (`format_p()`). Stars only with a key in the caption
(`p_stars()`: * < 0.05, ** < 0.01, *** < 0.001, **** < 0.0001).

## What the caption must state
- What each element is: "Violins show kernel density; boxes show median and IQR; whiskers 1.5 x IQR; points are individual replicates."
- Error bars: SD, SE or 95% CI (they mean very different things) and n per group.
- Test name, post-hoc method, adjustment, alpha.
- Any data transformation (log, normalisation, baseline correction, added 0 h point).

Caption template:
> **Figure N.** <What is compared> in <system>. <Plot element definitions>. Data are mean +/- SD (n = 3 independent
> preparations per group). Different letters indicate significant differences (one-way ANOVA with Tukey's HSD, p < 0.05).
