# inspect_data.R -- profile a data file and suggest a publication chart.
#
# Usage:
#   Rscript scripts/inspect_data.R <file.csv|tsv|txt|xlsx|xls> [--sheet=NAME] [--y=COL] [--group=COL] [--x=COL]
#
# Prints column roles, design (groups, replicates, format), any statistics
# columns, and ranked chart suggestions with the open questions to ask the user.
# Heuristics only: confirm the reading of the data before plotting.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

`%||%` <- function(a, b) if (is.null(a)) b else a

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("Usage: Rscript inspect_data.R <file> [--sheet=NAME] [--y=COL] [--group=COL] [--x=COL]")
path <- args[!grepl("^--", args)][1]
opt <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[1]) else NULL
}
if (!file.exists(path)) stop("File not found: ", path)

# ---- read ---------------------------------------------------------------------
ext <- tolower(tools::file_ext(path))
sheet_note <- NULL
if (ext %in% c("xlsx", "xls")) {
  if (!requireNamespace("readxl", quietly = TRUE)) stop("Install readxl to read Excel files.")
  sheets <- readxl::excel_sheets(path)
  sheet <- opt("sheet") %||% sheets[1]
  if (length(sheets) > 1) sheet_note <- paste0("Workbook has sheets: ", paste(sheets, collapse = " | "), " -> reading '", sheet, "'")
  d <- readxl::read_excel(path, sheet = sheet)
} else {
  first <- readLines(path, n = 5, warn = FALSE)
  delim <- if (ext == "tsv" || any(grepl("\t", first))) "\t"
    else if (sum(lengths(regmatches(first, gregexpr(";", first)))) > sum(lengths(regmatches(first, gregexpr(",", first))))) ";"
    else ","
  d <- suppressWarnings(read_delim(path, delim = delim, show_col_types = FALSE, trim_ws = TRUE,
                                   locale = locale(decimal_mark = if (delim == ";") "," else ".")))
}
d <- as.data.frame(d, check.names = FALSE)
d <- d[, colSums(!is.na(d)) > 0, drop = FALSE]          # drop empty columns
d <- d[rowSums(!is.na(d)) > 0, , drop = FALSE]          # drop empty rows
n <- nrow(d)

# ---- column roles ---------------------------------------------------------------
nm <- names(d)
lnm <- tolower(nm)
re <- list(
  mean    = "^(mean|avg|average|m)$|_mean$|^mean_|\\bmean\\b",
  sd      = "^(sd|std|stdev|s\\.?d\\.?)$|_sd$|^sd_|\\bsd\\b",
  se      = "^(se|sem|s\\.?e\\.?m?\\.?)$|_se$|_sem$",
  n       = "^(n|count|n_obs|nobs)$",
  pval    = "^p$|p[._ ]?val|pvalue|p[._ ]?adj|padj|fdr|q[._ ]?val|^p\\.",
  logfc   = "log2?fc|log2?[._ ]?fold|logfoldchange|log2foldchange",
  ci      = "^(lower|upper|lcl|ucl|ci[._ ]?low|ci[._ ]?high|ll|ul)$|lower|upper",
  estimate= "^(estimate|est|or|hr|rr|smd|effect|beta)$",
  time_ev = "^(time|os|pfs|days?|months?|futime|survival[._ ]?time)$",
  status  = "^(status|event|death|dead|censor|censored|fustat)$",
  x_cont  = "time|^t$|hour|^h$|min|day|week|month|temp|conc|dose|strain|freq|shear|rate|theta|2theta|wave|wavelength|wavenumber|ppm|shift|voltage|potential|depth|distance|angle",
  subject = "^id$|_id$|^id_|subject|patient|participant|animal|^rats?$|^rat[._ ]|mouse|mice|donor|individual",
  repidx  = "replicate|^rep$|^rep[._ ]|^reps?\\d*$|^run$|^well$|^cell$|^batch$|^trial$|^sample[._ ]?(no|num|id)?$",
  facet   = "endpoint|outcome|variable|parameter|measure|analyte|marker|^gene$|biomarker|assay|response[._ ]?var"
)
has <- function(key, i) grepl(re[[key]], lnm[i], perl = TRUE)

info <- lapply(seq_along(nm), function(i) {
  v <- d[[i]]
  num <- is.numeric(v)
  if (!num && is.character(v)) {
    vv <- suppressWarnings(as.numeric(gsub(",", ".", v)))
    if (mean(is.na(vv[!is.na(v)])) < 0.05 && any(!is.na(v))) { d[[i]] <<- vv; v <- vv; num <- TRUE }
  }
  u <- length(unique(v[!is.na(v)]))
  integerish <- num && all(abs(v[!is.na(v)] - round(v[!is.na(v)])) < 1e-9)
  role <- if (u <= 1) "constant (ignore)"
    else if (has("pval", i) && num && all(v[!is.na(v)] >= 0 & v[!is.na(v)] <= 1)) "p-value"
    else if (has("logfc", i)) "log fold change"
    else if (has("mean", i) && num) "summary: mean"
    else if (has("sd", i) && num) "summary: SD"
    else if (has("se", i) && num) "summary: SE"
    else if (has("n", i) && integerish) "summary: n"
    else if (has("status", i) && u <= 2) "event status"
    else if (has("subject", i) && (!num || u > 2)) "subject id"
    else if (has("repidx", i) && (!num || u > 1)) "replicate index"
    else if ((!num || is.logical(v)) && has("facet", i) && u <= 12) "categorical: facet (endpoint)"
    else if ((!num || is.logical(v)) && u > 30 && u >= 0.5 * n) "label / feature id"
    else if (!num || is.logical(v)) "categorical"
    else if (u <= min(12, max(2, n / 3)) && integerish && !has("x_cont", i)) "categorical (numeric codes)"
    else if (has("x_cont", i)) "continuous (x-like)"
    else "continuous"
  ex <- paste(utils::head(unique(v[!is.na(v)]), 4), collapse = ", ")
  data.frame(column = nm[i], type = if (num) "numeric" else class(v)[1], unique = u,
             missing = sum(is.na(v)), role = role, examples = substr(ex, 1, 45), stringsAsFactors = FALSE)
})
info <- do.call(rbind, info)

cat("==== FILE ====\n", path, "\n", sep = "")
if (!is.null(sheet_note)) cat(sheet_note, "\n")
cat(sprintf("%d rows x %d columns\n\n", n, ncol(d)))
cat("==== COLUMNS ====\n")
print(info, row.names = FALSE, right = FALSE)

roles <- setNames(info$role, info$column)
cols_of <- function(pattern) info$column[grepl(pattern, info$role)]
facet_cols <- cols_of("facet")
cat_cols  <- setdiff(cols_of("^categorical"), facet_cols)
cont_cols <- cols_of("^continuous")
xlike     <- cols_of("x-like")
id_cols   <- cols_of("^subject")
pcols     <- cols_of("p-value")
summary_cols <- cols_of("^summary")

# Drop grouping columns that are 1:1 aliases of an earlier one (e.g. group / source_group)
aliases <- character()
for (a in cat_cols) for (b in setdiff(cat_cols, c(a, aliases))) {
  if (match(b, cat_cols) > match(a, cat_cols) && !(a %in% aliases)) {
    combos <- nrow(unique(d[c(a, b)]))
    if (combos == length(unique(d[[a]])) && combos == length(unique(d[[b]]))) aliases <- c(aliases, b)
  }
}
cat_cols <- setdiff(cat_cols, aliases)

# Subject IDs only imply pairing if an ID appears under more than one condition
if (length(id_cols) && length(cat_cols)) {
  id_cols <- id_cols[vapply(id_cols, function(idc) {
    any(tapply(d[[cat_cols[1]]], d[[idc]], function(z) length(unique(z))) > 1)
  }, logical(1))]
}

# Composite labels such as "Drug 5 mg" or "1:2_12%" that encode two crossed factors
composite <- NULL
for (g in cat_cols) {
  lv <- unique(as.character(d[[g]]))
  for (sep in c(", ", " ", "_", "-", "/")) {
    parts <- strsplit(lv, sep, fixed = TRUE)
    if (length(lv) >= 4 && all(lengths(parts) == 2)) {
      f1 <- unique(vapply(parts, `[`, "", 1)); f2 <- unique(vapply(parts, `[`, "", 2))
      if (length(f1) >= 2 && length(f2) >= 2 && length(lv) >= 0.75 * length(f1) * length(f2)) {
        composite <- list(column = g, f1 = f1, f2 = f2, sep = sep)
        break
      }
    }
  }
  if (!is.null(composite)) break
}

suggest <- list()
ask <- character()
add <- function(chart, why, recipe) suggest[[length(suggest) + 1]] <<- list(chart = chart, why = why, recipe = recipe)

# ---- wide-format check ----------------------------------------------------------
wide <- FALSE
if (length(cont_cols) >= 3 && length(cat_cols) <= 1 && length(xlike) == 0 && !length(summary_cols)) {
  rng <- sapply(d[cont_cols], function(v) stats::median(v, na.rm = TRUE))
  similar <- max(abs(rng), na.rm = TRUE) / max(min(abs(rng), na.rm = TRUE), 1e-9) < 20
  if (similar && n <= 60) {
    wide <- TRUE
    cat("\n==== FORMAT ====\nLooks WIDE: columns", paste(cont_cols, collapse = ", "),
        "may be groups/conditions with one value per row.\n",
        "Reshape: pivot_longer(c(", paste0("`", cont_cols, "`", collapse = ", "), "), names_to = \"group\", values_to = \"value\")\n")
    ask <- c(ask, "Are the numeric columns separate groups/conditions (wide format), or different measured variables?")
  }
}

# ---- design -----------------------------------------------------------------------
cat("\n==== DESIGN ====\n")
y_col <- opt("y") %||% { cand <- setdiff(cont_cols, xlike); if (length(cand)) cand[length(cand)] else if (length(cont_cols)) cont_cols[length(cont_cols)] else NA }
g_cols <- if (!is.null(opt("group"))) strsplit(opt("group"), ",")[[1]] else cat_cols
x_col <- opt("x") %||% if (length(xlike)) xlike[1] else NA
reps <- NULL
if (length(g_cols)) {
  for (g in utils::head(g_cols, 3)) {
    tab <- table(d[[g]])
    cat(sprintf("Group column '%s': %d levels (%s)\n  rows per level: min %d, median %g, max %d\n",
                g, length(tab), paste(utils::head(names(tab), 8), collapse = ", "),
                min(tab), stats::median(tab), max(tab)))
  }
  key <- c(utils::head(g_cols, 2), facet_cols)
  if (!is.na(x_col)) key <- c(key, x_col)
  reps <- d %>% count(across(all_of(key))) %>% pull(n)
  cat(sprintf("Rows per %s cell: min %d, median %g, max %d\n", paste(key, collapse = " x "), min(reps), stats::median(reps), max(reps)))
  if (length(g_cols) >= 2) cat("Two or more grouping factors: ", paste(utils::head(g_cols, 2), collapse = " and "), "\n")
}
if (length(aliases)) cat("Ignored as duplicates of another grouping column:", paste(aliases, collapse = ", "), "\n")
if (length(facet_cols)) {
  for (fc in facet_cols) cat(sprintf("Facet column '%s': %d panels (%s) -> facet_wrap(scales = \"free_y\"), compare groups within each panel\n",
                                     fc, length(unique(d[[fc]])), paste(utils::head(unique(d[[fc]]), 6), collapse = ", ")))
}
if (!is.null(composite)) {
  cat(sprintf("Column '%s' encodes two crossed factors: {%s} x {%s}\n  -> separate(%s, into = c(\"factor1\", \"factor2\"), sep = \"%s\", remove = FALSE); dodge/color by one, x or facet by the other\n",
              composite$column, paste(composite$f1, collapse = ", "), paste(composite$f2, collapse = ", "),
              composite$column, composite$sep))
}
if (length(id_cols)) cat("Subject ID columns spanning conditions:", paste(id_cols, collapse = ", "), "-> paired / repeated measures\n")
if (length(pcols)) cat("p-value columns present:", paste(pcols, collapse = ", "), "-> statistics already computed\n")
if (!is.na(x_col)) cat("x-like continuous column:", x_col, "\n")
if (!is.na(y_col)) cat("Likely response (y):", y_col, "\n")

# ---- suggestions --------------------------------------------------------------------
lc <- tolower(names(roles))
if (any(roles == "log fold change") && length(pcols)) {
  add("Volcano plot", "log fold change + p-values per feature", "recipes.md#volcano")
}
if (any(roles == "event status") && any(grepl(re$time_ev, lc, perl = TRUE))) {
  add("Kaplan-Meier curves + number-at-risk table", "time-to-event column with event status", "recipes.md#kaplan-meier")
}
if (any(grepl(re$estimate, lc, perl = TRUE)) && sum(grepl("lower|upper|lcl|ucl|ci", lc)) >= 2) {
  add("Forest plot", "estimates with lower/upper confidence limits", "recipes.md#forest-plot")
}
if (any(roles == "summary: mean") && any(grepl("summary: (SD|SE)", roles))) {
  add(if (!is.na(x_col)) "Mean +/- error line plot (profile)" else "Mean +/- error point plot (dodged if 2 factors)",
      "only summary statistics (mean, SD/SE) are available -- raw-data plots are impossible",
      "recipes.md#summary-only-data")
  ask <- c(ask, "Is the error column SD or SE? (state it in the caption)")
}
if (!length(suggest) && !wide) {
  if (!is.na(x_col) && !is.na(y_col) && x_col != y_col) {
    y_candidates <- setdiff(cont_cols, xlike)
    series_cols <- c(utils::head(g_cols, 2), facet_cols)
    ux_per_series <- if (length(series_cols)) {
      stats::median(d %>% group_by(across(all_of(series_cols))) %>% summarise(k = n_distinct(.data[[x_col]]), .groups = "drop") %>% pull(k))
    } else length(unique(d[[x_col]]))
    rep_med <- if (!is.null(reps)) stats::median(reps) else {
      stats::median(table(d[[x_col]]))
    }
    xl <- tolower(x_col)
    if (!length(g_cols) && length(y_candidates) >= 2) {
      add("Several y columns share one x: pivot_longer() them into series, then plot one series per color",
          sprintf("x = '%s'; series columns: %s", x_col, paste(utils::head(y_candidates, 6), collapse = ", ")), "recipes.md#scatter-regression")
      ask <- c(ask, sprintf("Are %s parallel series of the same measurement (overlay them), or different variables (facets/separate figures)?",
                            paste(utils::head(y_candidates, 4), collapse = ", ")))
    }
    if (rep_med >= 2) {
      add("Mean +/- SD line plot over x (one line per group)", sprintf("'%s' is ordered/continuous with ~%g replicates per point", x_col, rep_med), "recipes.md#time-course")
    } else if (ux_per_series >= 8) {
      if (grepl("freq|shear|strain|rate|stress", xl)) {
        add("Log-log curve overlay (one color per formulation; G'/G'' by linetype)", "rheology-like x variable with one value per point", "recipes.md#rheology")
      } else if (grepl("theta|wave|ppm|shift|nm$|cm", xl) && length(unique(d[[g_cols[1] %||% x_col]])) >= 2) {
        add("Offset (stacked) curves with peak labels", sprintf("spectrum-like x '%s', several samples", x_col), "recipes.md#spectra-and-instrument-curves")
      } else {
        add("Line curve(s) -- one per group/sample", sprintf("'%s' has ~%g values per series, one observation each", x_col, ux_per_series), "recipes.md#spectra-and-instrument-curves")
      }
    } else {
      add("Scatter + fitted line (calibration/regression)", "numeric x and y with single observations at few x levels", "recipes.md#scatter-regression")
      ask <- c(ask, "Fit a model to the points (linear / 4-parameter / kinetic), or show points joined by lines?")
    }
    if (length(g_cols) && length(y_candidates) >= 3) {
      ask <- c(ask, sprintf("Which response(s) to plot? Candidates: %s", paste(utils::head(y_candidates, 8), collapse = ", ")))
    }
  } else if (length(g_cols) && !is.na(y_col)) {
    m <- if (!is.null(reps)) stats::median(reps) else 0
    two <- length(g_cols) >= 2 || !is.null(composite)
    if (length(id_cols)) {
      add("Paired / repeated-measures plot (lines join each subject)", "an ID column links observations across conditions", "recipes.md#paired-data")
      ask <- c(ask, sprintf("Is '%s' a subject/animal ID so observations are paired?", id_cols[1]))
    }
    if (m >= 3) {
      add(paste0("Violin + box + points (raincloud for >= 10 per group)", if (two) ", dodged or faceted by the 2nd factor" else ""),
          sprintf("raw replicates, ~%g per group: show every observation", m), "recipes.md#violin-box-points")
      add(paste0("Points + mean +/- SD", if (two) " (dodged by 2nd factor)" else ""),
          if (m < 6) sprintf("alternative for very small n (~%g per group), where density shapes are weak", m) else "alternative when the distribution shape is not of interest",
          "recipes.md#points-mean-error")
    } else if (m >= 1) {
      add("Dot or bar chart (no error bars)", "one or two values per group", "recipes.md#bars")
    }
    if (!length(pcols) && m >= 2) ask <- c(ask, "No statistics found. Run a group comparison (ANOVA/Tukey, Welch/Games-Howell or Kruskal/Dunn via compare_groups()) and show adjusted p-value brackets for significant pairs, or plot without inferential marks?")
  } else if (length(cont_cols) >= 4 && !length(g_cols)) {
    add("Correlation heatmap", sprintf("%d numeric variables, no grouping", length(cont_cols)), "recipes.md#correlation-heatmap")
  } else if (length(cont_cols) >= 4 && length(g_cols)) {
    add("PCA scores plot with 95% ellipses by group", sprintf("%d numeric variables + group", length(cont_cols)), "recipes.md#pca")
  } else if (length(cont_cols) == 2) {
    add("Scatter + fitted line", "two numeric variables", "recipes.md#scatter-regression")
  } else if (length(cat_cols) && !length(cont_cols)) {
    add("Bar chart of counts / 100% stacked proportions", "only categorical columns", "recipes.md#bars")
  }
}
if (wide) add("Re-run after pivot_longer(); likely group comparison", "wide layout", "recipes.md")
if (!length(suggest)) {
  add("Unclear -- ask the user", "no recognisable structure", "chart-selection.md")
  ask <- c(ask, "Which column is the response (y), which defines groups, and which (if any) is the x axis?")
}
if (is.na(x_col) && length(cont_cols) > 3 && length(g_cols) && !length(summary_cols)) {
  ask <- c(ask, sprintf("Several numeric columns (%s): plot them as facets of one figure, or separate figures?", paste(utils::head(setdiff(cont_cols, x_col), 6), collapse = ", ")))
}

cat("\n==== SUGGESTED CHARTS (best first) ====\n")
for (i in seq_along(suggest)) cat(sprintf("%d. %s\n   why: %s\n   recipe: references/%s\n", i, suggest[[i]]$chart, suggest[[i]]$why, suggest[[i]]$recipe))
cat("\n==== QUESTIONS (ask only if the answer changes the figure) ====\n")
if (length(ask)) cat(paste0("- ", unique(ask)), sep = "\n") else cat("- none: the structure is unambiguous\n")
