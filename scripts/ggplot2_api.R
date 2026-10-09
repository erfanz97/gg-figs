# ggplot2_api.R -- look up what the INSTALLED ggplot2 supports, so code never relies on
# memory of an older or newer version.
#
# Usage:
#   Rscript scripts/ggplot2_api.R                 list every exported function by family
#   Rscript scripts/ggplot2_api.R geom_boxplot    arguments, aesthetics, default aesthetics, stat/position
#   Rscript scripts/ggplot2_api.R theme           every theme() element argument
#   Rscript scripts/ggplot2_api.R "scale_*_viridis*"   wildcard search (glob)

suppressMessages(library(ggplot2))
args <- commandArgs(trailingOnly = TRUE)
ns <- asNamespace("ggplot2")
exports <- sort(getNamespaceExports("ggplot2"))

families <- list(
  "Geoms" = "^geom_", "Stats" = "^stat_", "Positions" = "^position_",
  "Scales (position)" = "^scale_[xy]_", "Scales (non-position)" = "^scale_(?![xy]_)",
  "Coords" = "^coord_", "Facets" = "^facet_", "Guides" = "^guide_",
  "Themes" = "^theme_", "Annotations" = "^annotation_", "Theme elements" = "^element_",
  "Labellers" = "^label_", "Legend keys" = "^draw_key_",
  "Other helpers" = "^(aes|after_|alpha|cut_|dup_axis|sec_axis|expansion|expand_|labs|lims|xlim|ylim|vars|rel|margin|unit|ggsave|ggplot|stage|from_theme|mean_|median_|get_|set_|update_|layer|ggproto|qplot|waiver|binned_scale|discrete_scale|continuous_scale)"
)

show_layer <- function(name) {
  fn <- get(name, envir = ns)
  cat("== ", name, " ==\n", sep = "")
  print(args(fn))
  ly <- tryCatch(suppressWarnings(suppressMessages(fn())), error = function(e) NULL)
  if (inherits(ly, "LayerInstance") || (is.list(ly) && length(ly) && inherits(ly[[1]], "LayerInstance"))) {
    ly <- if (inherits(ly, "LayerInstance")) ly else ly[[1]]
    cat("\nGeom:", class(ly$geom)[1], "  Stat:", class(ly$stat)[1], "  Position:", class(ly$position)[1], "\n")
    cat("Required aesthetics:", paste(unique(c(ly$geom$required_aes, ly$stat$required_aes)), collapse = ", "), "\n")
    cat("Understood aesthetics:", paste(ly$geom$aesthetics(), collapse = ", "), "\n")
    da <- tryCatch(ly$geom$default_aes, error = function(e) NULL)
    if (length(da)) {
      cat("Geom defaults:", paste(names(da), vapply(da, function(v) paste(format(v), collapse = ""), ""), sep = " = ", collapse = "; "), "\n")
    }
    cat("Stat parameters:", paste(ly$stat$parameters(), collapse = ", "), "\n")
    cat("Geom parameters:", paste(ly$geom$parameters(TRUE), collapse = ", "), "\n")
  }
  invisible()
}

if (length(args) == 0) {
  cat("ggplot2", as.character(packageVersion("ggplot2")), "\n")
  seen <- character()
  for (nm in names(families)) {
    hit <- setdiff(grep(families[[nm]], exports, value = TRUE, perl = TRUE), seen)
    seen <- c(seen, hit)
    cat(sprintf("\n## %s (%d)\n", nm, length(hit)))
    cat(strwrap(paste(hit, collapse = " "), 110), sep = "\n")
  }
} else if (identical(args[1], "theme")) {
  cat("theme() arguments (ggplot2", as.character(packageVersion("ggplot2")), ")\n")
  cat(strwrap(paste(names(formals(theme)), collapse = " "), 110), sep = "\n")
} else if (grepl("[*?]", args[1])) {
  rx <- glob2rx(args[1])
  cat(grep(rx, exports, value = TRUE), sep = "\n")
} else if (args[1] %in% exports) {
  show_layer(args[1])
} else {
  cat("Not exported by ggplot2:", args[1], "\nClosest:", paste(utils::head(agrep(args[1], exports, value = TRUE), 8), collapse = ", "), "\n")
}
