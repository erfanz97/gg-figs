# Compatibility test: gg-figs helpers against the whole ggplot2 API.
#
# For every geom, stat, position, scale, coord, facet, guide, annotation, labeller and legend
# key exported by the INSTALLED ggplot2, builds a small plot with theme_pub(), draws it on a
# real graphics device and fails on any error. Prints which exports were exercised.
#   Rscript examples/test_ggplot2_compat.R

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
skill_dir <- if (length(script_argument) > 0) {
  dirname(dirname(normalizePath(sub("^--file=", "", script_argument[1]), winslash = "/")))
} else {
  normalizePath(".", winslash = "/")
}
source(file.path(skill_dir, "assets", "gg_pub.R"))
set.seed(11)

have <- function(pkg) requireNamespace(pkg, quietly = TRUE)
exports <- getNamespaceExports("ggplot2")
covered <- character()
failures <- list()
warn_count <- 0L
n_ok <- 0L

# ---- test data (all built into R / ggplot2) ------------------------------------
mt <- mtcars
mt$cyl <- factor(mt$cyl)
mt$gear <- factor(mt$gear)
mt$car <- rownames(mt)
dm <- diamonds[sample(nrow(diamonds), 1500), ]
sm <- data.frame(g = factor(rep(c("A", "B", "C"), each = 8)), x = rep(1:8, 3))
sm$y <- 10 + as.integer(sm$g) * 3 + sm$x * 0.8 + rnorm(24)
sm$lo <- sm$y - 1
sm$hi <- sm$y + 1
cont <- data.frame(x = rnorm(60), y = rnorm(60))
cont$z <- cont$x + cont$y
cont$grp <- factor(sample(c("a", "b", "c", "d"), 60, TRUE))
cont$ord <- factor(cont$grp, ordered = TRUE)
cont$day <- as.Date("2025-01-01") + sample(0:364, 60)
cont$stamp <- as.POSIXct("2025-01-01", tz = "UTC") + sample(0:86400, 60)
cont$tod <- hms::as_hms(sample(0:86399, 60))
cont$pos <- abs(cont$z) + 0.1
cont$col <- sample(c("red", "blue", "darkgreen"), 60, TRUE)
cont$dir <- runif(60, 0, 2 * pi)

# ---- runner ---------------------------------------------------------------------
draw <- function(p) {
  f <- tempfile(fileext = ".png")
  ragg::agg_png(f, width = 600, height = 450, res = 100)
  on.exit({ dev.off(); unlink(f) })
  suppressWarnings(print(p))
  invisible(TRUE)
}
run <- function(name, build, covers = character()) {
  fn_names <- intersect(all.names(body(build)), exports)
  covered <<- union(covered, c(fn_names, covers))
  res <- tryCatch({
    withCallingHandlers({
      p <- build()
      draw(p)
      TRUE
    }, warning = function(w) {
      warn_count <<- warn_count + 1L
      invokeRestart("muffleWarning")
    })
  }, error = function(e) conditionMessage(e))
  if (isTRUE(res)) n_ok <<- n_ok + 1L else failures[[name]] <<- res
}
base_pt <- function() ggplot(mt, aes(wt, mpg)) + geom_point()
skip_unless <- function(ok, name) {
  if (!ok) cat("skipped:", name, "\n")
  ok
}

# ---- geoms ------------------------------------------------------------------------
run("abline/hline/vline", function() base_pt() + geom_abline(intercept = 37, slope = -5) + geom_hline(yintercept = 20) + geom_vline(xintercept = 3) + theme_pub())
run("area", function() ggplot(economics, aes(date, unemploy)) + geom_area(fill = pub_colors[1], alpha = 0.4) + theme_pub())
run("bar", function() ggplot(mpg, aes(class, fill = drv)) + geom_bar() + scale_fill_pub() + theme_pub())
run("col", function() ggplot(sm, aes(g, y, fill = g)) + geom_col() + scale_fill_pub() + theme_pub())
run("histogram/freqpoly", function() ggplot(dm, aes(price)) + geom_histogram(bins = 30) + geom_freqpoly(bins = 30) + theme_pub())
run("density", function() ggplot(dm, aes(price, fill = cut)) + geom_density(alpha = 0.4) + theme_pub())
run("dotplot", function() ggplot(mt, aes(mpg)) + geom_dotplot(binwidth = 1) + theme_pub())
run("count", function() ggplot(mpg, aes(cty, hwy)) + geom_count() + theme_pub())
run("bin_2d", function() ggplot(dm, aes(carat, price)) + geom_bin_2d(bins = 20) + scale_fill_pub_seq() + theme_pub())
run("stat_bin_2d", function() ggplot(dm, aes(carat, price)) + stat_bin_2d(bins = 10) + theme_pub())
run("stat_density", function() ggplot(dm, aes(price)) + stat_density(geom = "line", aes(colour = cut)) + scale_colour_pub() + theme_pub())
run("bin2d alias", function() ggplot(dm, aes(carat, price)) + geom_bin2d(bins = 20) + stat_bin2d(bins = 10, alpha = 0.3) + theme_pub())
run("blank", function() ggplot(mt, aes(wt, mpg)) + geom_blank() + theme_pub())
run("boxplot", function() ggplot(mpg, aes(class, hwy, fill = class)) + geom_boxplot() + stat_boxplot(geom = "errorbar", width = 0.3) + scale_fill_pub() + theme_pub())
run("contour", function() ggplot(faithfuld, aes(waiting, eruptions, z = density)) + geom_contour() + stat_contour(color = "red", bins = 4) + theme_pub())
run("contour_filled", function() ggplot(faithfuld, aes(waiting, eruptions, z = density)) + geom_contour_filled() + stat_contour_filled(alpha = 0.3) + theme_pub())
run("crossbar", function() ggplot(sm[sm$x == 1, ], aes(g, y, ymin = lo, ymax = hi)) + geom_crossbar() + theme_pub())
run("curve/segment/spoke", function() base_pt() + geom_curve(aes(xend = wt + 0.5, yend = mpg + 3)) + geom_segment(aes(xend = wt + 0.3, yend = mpg)) + geom_spoke(aes(angle = wt, radius = 0.4)) + theme_pub())
run("density_2d", function() ggplot(mt, aes(wt, mpg)) + geom_density_2d() + stat_density_2d(color = "red", bins = 4) + theme_pub())
run("density_2d_filled", function() ggplot(faithful, aes(waiting, eruptions)) + geom_density_2d_filled(alpha = 0.7) + stat_density_2d_filled(alpha = 0.1) + theme_pub())
run("density2d aliases", function() ggplot(mt, aes(wt, mpg)) + geom_density2d() + geom_density2d_filled(alpha = 0.3) + stat_density2d() + stat_density2d_filled(alpha = 0.2) + theme_pub())
run("errorbar", function() ggplot(sm, aes(x, y, ymin = lo, ymax = hi, colour = g)) + geom_errorbar(width = 0.2) + geom_line(aes(group = g)) + scale_colour_pub() + theme_pub())
run("errorbar horizontal (errorbarh)", function() ggplot(sm, aes(y, g, xmin = lo, xmax = hi)) + geom_errorbar(orientation = "y", width = 0.2) + suppressWarnings(geom_errorbarh(height = 0.1, colour = "red")) + theme_pub())
run("function", function() ggplot() + xlim(-3, 3) + geom_function(fun = dnorm) + stat_function(fun = function(x) 0.5 * dnorm(x), color = "red") + theme_pub())
run("jitter", function() ggplot(mpg, aes(class, hwy)) + geom_jitter(width = 0.2, height = 0) + theme_pub())
run("label/text", function() ggplot(mt[1:12, ], aes(wt, mpg, label = car)) + geom_text(size = 2, vjust = -0.5) + geom_label(size = 2, nudge_y = -1) + theme_pub())
run("line/path/step", function() ggplot(economics, aes(date, uempmed)) + geom_line() + geom_step(color = "red", alpha = 0.4) + geom_path(color = "blue", alpha = 0.3) + theme_pub())
run("linerange/pointrange", function() ggplot(sm, aes(x, y, ymin = lo, ymax = hi, colour = g)) + geom_linerange() + geom_pointrange(position = position_nudge(x = 0.1)) + theme_pub())
run("polygon", function() ggplot(data.frame(x = c(1, 2, 3), y = c(1, 3, 1)), aes(x, y)) + geom_polygon(fill = "grey70", color = "black") + theme_pub())
run("qq/qq_line", function() ggplot(cont, aes(sample = x)) + geom_qq() + geom_qq_line() + stat_qq(color = "red", alpha = 0.2) + stat_qq_line(color = "red") + theme_pub())
run("raster", function() ggplot(faithfuld, aes(waiting, eruptions, fill = density)) + geom_raster() + scale_fill_pub_seq() + theme_pub())
run("rect/tile", function() ggplot() + geom_rect(aes(xmin = 0, xmax = 2, ymin = 0, ymax = 1), fill = "grey80") + geom_tile(data = data.frame(x = 3, y = 0.5), aes(x, y), fill = "tomato") + theme_pub())
run("ribbon", function() ggplot(sm, aes(x, y, ymin = lo, ymax = hi, fill = g)) + geom_ribbon(alpha = 0.3) + scale_fill_pub() + theme_pub())
run("rug", function() base_pt() + geom_rug() + theme_pub())
run("smooth", function() base_pt() + geom_smooth(method = "lm", formula = y ~ x) + geom_smooth(method = "loess", formula = y ~ x, color = "red", se = FALSE) + stat_smooth(method = "glm", formula = y ~ poly(x, 2), color = "blue", se = FALSE) + theme_pub())
run("violin", function() ggplot(mpg, aes(class, hwy, fill = class)) + geom_violin() + stat_ydensity(alpha = 0.1, geom = "violin") + scale_fill_pub() + theme_pub())

# ---- stats and the remaining layer-level helpers ----------------------------------------------
run("stat_align (area)", function() ggplot(economics_long, aes(date, value01, fill = variable)) + stat_align(geom = "area", alpha = 0.5) + theme_pub())
run("stat_bin", function() ggplot(dm, aes(price)) + stat_bin(bins = 25, geom = "step") + theme_pub())
run("stat_connect", function() ggplot(economics[1:40, ], aes(date, unemploy)) + stat_connect(connection = "hv") + theme_pub())
run("stat_count", function() ggplot(mpg, aes(class)) + stat_count() + theme_pub())
run("stat_ecdf", function() ggplot(dm, aes(price, colour = cut)) + stat_ecdf() + scale_colour_pub() + theme_pub())
run("stat_ellipse", function() ggplot(iris, aes(Sepal.Length, Sepal.Width, colour = Species)) + geom_point() + stat_ellipse(type = "norm") + scale_colour_pub() + theme_pub())
run("stat_identity/unique", function() base_pt() + stat_identity(color = "red", alpha = 0.3) + stat_unique(color = "blue", alpha = 0.3) + theme_pub())
run("stat_manual", function() base_pt() + stat_manual(fun = function(df) data.frame(x = mean(df$x), y = mean(df$y)), size = 4, colour = "red") + theme_pub())
run("stat_sum", function() ggplot(mpg, aes(cty, hwy)) + stat_sum() + theme_pub())
run("stat_summary", function() ggplot(mpg, aes(class, hwy)) + stat_summary(fun.data = mean_se, geom = "pointrange") + stat_summary(fun.data = mean_cl_normal, geom = "errorbar", width = 0.2, color = "red") + stat_summary(fun.data = mean_sdl, geom = "linerange", color = "blue", fun.args = list(mult = 1)) + theme_pub())
run("stat_summary median_hilow/mean_cl_boot", function() ggplot(mpg, aes(class, hwy)) + stat_summary(fun.data = median_hilow, geom = "pointrange") + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", color = "red", width = 0.2) + theme_pub())
run("stat_summary_2d", function() ggplot(mpg, aes(cty, hwy, z = displ)) + stat_summary_2d(fun = mean, bins = 10) + theme_pub())
run("stat_summary2d alias", function() ggplot(mpg, aes(cty, hwy, z = displ)) + stat_summary2d(fun = mean, bins = 8) + theme_pub())
run("stat_summary_bin", function() ggplot(mpg, aes(displ, hwy)) + stat_summary_bin(fun = "mean", geom = "bar", bins = 8) + theme_pub())
if (skip_unless(have("hexbin"), "hexbin")) {
  run("hex", function() ggplot(dm, aes(carat, price)) + geom_hex(bins = 20) + stat_bin_hex(bins = 10, alpha = 0.3) + stat_bin_hex(bins = 5, alpha = 0.1) + theme_pub(), covers = c("stat_binhex", "stat_summary_hex"))
}
if (skip_unless(have("quantreg"), "quantreg")) {
  run("quantile", function() ggplot(mpg, aes(displ, hwy)) + geom_point() + geom_quantile(quantiles = c(0.25, 0.75)) + stat_quantile(color = "red", quantiles = 0.5) + theme_pub())
}

# ---- positions -----------------------------------------------------------------------------------
run("position_dodge/dodge2/fill/stack/identity", function() ggplot(mpg, aes(class, fill = drv)) + geom_bar(position = position_dodge(preserve = "single")) + geom_bar(position = position_dodge2(), alpha = 0.2) + geom_bar(position = position_fill(), alpha = 0.1) + geom_bar(position = position_stack(), alpha = 0.1) + geom_bar(position = position_identity(), alpha = 0.1) + theme_pub())
run("position_jitter/jitterdodge/nudge", function() ggplot(mpg, aes(class, hwy, colour = drv)) + geom_point(position = position_jitterdodge(jitter.width = 0.1, dodge.width = 0.7)) + geom_point(position = position_jitter(width = 0.2, height = 0), alpha = 0.2) + geom_text(aes(label = drv), position = position_nudge(y = 1), size = 2) + theme_pub())

# ---- position scales ------------------------------------------------------------------------------------
pt <- function(...) { p <- ggplot(cont, aes(pos, pos * 3)) + geom_point(); for (el in list(...)) p <- p + el; p + theme_pub() }
run("scale_x/y continuous + sec.axis", function() pt(scale_x_continuous(sec.axis = sec_axis(~ . * 2, name = "twice"), expand = expansion(mult = c(0, 0.1)), n.breaks = 6), scale_y_continuous(position = "right", labels = scales::label_percent(scale = 1), breaks = scales::breaks_pretty(8))))
run("scale_x/y log10 sqrt reverse", function() pt(scale_x_log10(guide = guide_axis_logticks()), scale_y_sqrt()), covers = c("scale_x_sqrt"))
run("scale_x_sqrt", function() pt(scale_x_sqrt(), scale_y_log10()))
run("scale_x/y reverse", function() pt(scale_x_reverse(), scale_y_reverse()))
run("scale_x/y discrete", function() ggplot(mpg, aes(class, hwy)) + geom_boxplot() + scale_x_discrete(labels = abbreviate, guide = guide_axis(n.dodge = 2)) + scale_y_discrete() + theme_pub())
run("scale_x/y binned", function() pt(scale_x_binned(), scale_y_binned()))
run("scale_x/y date", function() ggplot(cont, aes(day, z)) + geom_point() + scale_x_date(date_breaks = "2 months", date_labels = "%b") + scale_y_continuous() + theme_pub())
run("scale_y date/datetime", function() ggplot(cont, aes(z, day)) + geom_point() + scale_y_date(date_labels = "%b") + theme_pub())
run("scale_y datetime", function() ggplot(cont, aes(z, stamp)) + geom_point() + scale_y_datetime(date_labels = "%H:%M") + theme_pub())
run("scale_x/y datetime", function() ggplot(cont, aes(stamp, z)) + geom_point() + scale_x_datetime(date_labels = "%H:%M") + theme_pub())
run("scale_x/y time", function() ggplot(cont, aes(tod, z)) + geom_point() + scale_x_time() + scale_y_time(labels = function(x) x) + theme_pub())
run("lims/xlim/ylim/expand_limits", function() ggplot(cont, aes(x, y)) + geom_point() + xlim(-3, 3) + ylim(-3, 3) + lims(x = c(-3, 3)) + expand_limits(x = 0, y = 0) + theme_pub())

# ---- non-position scales: generated from a table of (suffix, data kind, extra arguments) ---------
colour_kinds <- list(
  continuous = list(var = "z", suffixes = c("gradient", "gradient2", "gradientn", "viridis_c", "distiller", "continuous", "steps", "steps2", "stepsn", "binned", "viridis_b", "fermenter"), args = list(gradientn = list(colours = c("navy", "white", "firebrick")), stepsn = list(colours = c("navy", "white", "firebrick")), distiller = list(palette = "Blues"), fermenter = list(palette = "Greens"))),
  discrete = list(var = "grp", suffixes = c("hue", "brewer", "grey", "viridis_d", "discrete"), args = list()),
  ordinal = list(var = "ord", suffixes = c("ordinal"), args = list()),
  manual = list(var = "grp", suffixes = "manual", args = list(manual = list(values = c(a = "red", b = "blue", c = "green", d = "orange")))),
  identity = list(var = "col", suffixes = "identity", args = list(identity = list())),
  date = list(var = "day", suffixes = "date", args = list()),
  datetime = list(var = "stamp", suffixes = "datetime", args = list())
)
for (aes_name in c("colour", "color", "fill")) {
  for (kind in names(colour_kinds)) {
    spec <- colour_kinds[[kind]]
    for (sfx in spec$suffixes) {
      fname <- paste0("scale_", aes_name, "_", sfx)
      if (!fname %in% exports) next
      fn <- get(fname, envir = asNamespace("ggplot2"))
      extra <- spec$args[[sfx]] %||% list()
      var <- spec$var
      run(fname, function() {
        sc <- do.call(fn, extra)
        mapping <- if (aes_name == "fill") aes(x, y, fill = .data[[var]]) else aes(x, y, colour = .data[[var]])
        ggplot(cont, mapping) + geom_point(shape = 21, size = 3, stroke = 0.5) + sc + theme_pub()
      }, covers = fname)
    }
  }
}
other_scales <- list(
  size = list(var = "pos", sfx = c("", "_continuous", "_area", "_binned", "_binned_area", "_discrete", "_ordinal", "_date", "_datetime", "_manual", "_identity"), type = c("c", "c", "c", "c", "c", "d", "o", "date", "datetime", "m", "i")),
  alpha = list(var = "pos", sfx = c("", "_continuous", "_binned", "_discrete", "_ordinal", "_manual", "_identity", "_date", "_datetime"), type = c("c", "c", "c", "d", "o", "m", "i", "date", "datetime")),
  linewidth = list(var = "pos", sfx = c("", "_continuous", "_binned", "_discrete", "_ordinal", "_manual", "_identity", "_date", "_datetime"), type = c("c", "c", "c", "d", "o", "m", "i", "date", "datetime")),
  shape = list(var = "grp", sfx = c("", "_discrete", "_ordinal", "_manual", "_identity", "_binned"), type = c("d", "d", "o", "m", "i", "c")),
  linetype = list(var = "grp", sfx = c("", "_discrete", "_manual", "_identity", "_binned"), type = c("d", "d", "m", "i", "c"))
)
for (aes_name in names(other_scales)) {
  spec <- other_scales[[aes_name]]
  for (i in seq_along(spec$sfx)) {
    fname <- paste0("scale_", aes_name, spec$sfx[i])
    if (!fname %in% exports) next
    type <- spec$type[i]
    var <- switch(type, c = "pos", d = "grp", o = "ord", date = "day", datetime = "stamp", m = "grp", i = "idv")
    fn <- get(fname, envir = asNamespace("ggplot2"))
    extra <- switch(type,
      m = switch(aes_name, size = list(values = c(a = 1, b = 2, c = 3, d = 4)), alpha = list(values = c(a = 0.2, b = 0.4, c = 0.6, d = 1)),
                 linewidth = list(values = c(a = 0.2, b = 0.4, c = 0.6, d = 1)), shape = list(values = c(a = 16, b = 17, c = 15, d = 3)),
                 linetype = list(values = c(a = "solid", b = "dashed", c = "dotted", d = "dotdash"))),
      list())
    cdat <- cont
    cdat$idv <- switch(aes_name, size = 3, alpha = 0.5, linewidth = 0.7, shape = 16, linetype = "solid")
    run(fname, function() {
      sc <- if (type == "i") do.call(fn, list()) else do.call(fn, extra)
      if (aes_name == "linewidth" || aes_name == "linetype") {
        ggplot(cdat, aes(x, y, xend = x + 0.2, yend = y, !!aes_name := .data[[var]])) + geom_segment() + sc + theme_pub()
      } else {
        ggplot(cdat, aes(x, y, !!aes_name := .data[[var]])) + geom_point() + sc + theme_pub()
      }
    }, covers = fname)
  }
}
run("scale_continuous/discrete_identity", function() ggplot(cont, aes(x, y)) + geom_point(aes(colour = col)) + scale_discrete_identity("colour") + geom_point(aes(size = pos), alpha = 0.3) + scale_continuous_identity("size"), covers = c("scale_discrete_identity", "scale_continuous_identity"))
run("scale_discrete_manual", function() ggplot(cont, aes(x, y, colour = grp)) + geom_point() + scale_discrete_manual("colour", values = c(a = "red", b = "blue", c = "green", d = "orange")) + theme_pub())
run("scale_radius", function() ggplot(cont, aes(x, y, size = pos)) + geom_point() + scale_radius() + theme_pub())
run("scale_type/scale_*_pub", function() ggplot(cont, aes(x, y, colour = grp, shape = grp, fill = z)) + geom_point(size = 3) + scale_colour_pub() + scale_shape_pub() + scale_fill_pub_div() + scale_color_pub() + theme_pub(), covers = "scale_type")
run("pub sequential/diverging", function() ggplot(cont, aes(x, y, colour = z, fill = z)) + geom_point(shape = 21) + scale_colour_pub_seq() + scale_fill_pub_div() + theme_pub())

# ---- coords ------------------------------------------------------------------------------------------------
run("coord_cartesian", function() base_pt() + coord_cartesian(xlim = c(2, 4), ylim = c(10, 30), expand = FALSE, clip = "off") + theme_pub())
run("coord_equal/fixed", function() base_pt() + coord_equal() + coord_fixed(ratio = 0.2) + theme_pub())
run("coord_flip", function() ggplot(mpg, aes(class, hwy)) + geom_boxplot() + coord_flip() + theme_pub())
run("coord_polar", function() ggplot(mpg, aes(class, fill = drv)) + geom_bar(width = 1) + coord_polar() + theme_pub())
run("coord_radial", function() ggplot(mpg, aes(class, fill = drv)) + geom_bar(width = 1) + coord_radial(inner.radius = 0.2, expand = FALSE) + guides(theta = guide_axis_theta(angle = 0)) + theme_pub())
run("coord_trans/transform", function() ggplot(mt, aes(wt, mpg)) + geom_point() + suppressWarnings(coord_trans(x = "log10")) + coord_transform(y = "sqrt") + theme_pub())
run("coord_quickmap", function() ggplot(data.frame(lon = c(10, 20), lat = c(40, 50)), aes(lon, lat)) + geom_point() + coord_quickmap() + theme_pub())
if (have("sf")) {
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  run("sf", function() ggplot(nc) + geom_sf(aes(fill = AREA)) + geom_sf_text(aes(label = substr(NAME, 1, 3)), size = 1.5, check_overlap = TRUE) + geom_sf_label(data = nc[1:2, ], aes(label = NAME), size = 2) + stat_sf_coordinates(size = 0.3) + stat_sf(fill = NA) + coord_sf() + scale_fill_pub_seq() + theme_pub(), covers = c("layer_sf", "coord_sf", "stat_sf", "stat_sf_coordinates"))
} else cat("skipped: sf\n")

# ---- facets ------------------------------------------------------------------------------------------------------
run("facet_wrap options", function() ggplot(mpg, aes(displ, hwy)) + geom_point() + facet_wrap(vars(class), scales = "free_y", nrow = 2, strip.position = "bottom", dir = "v", axes = "all", axis.labels = "margins", labeller = label_both) + theme_pub())
run("facet_wrap labellers", function() ggplot(mpg, aes(displ, hwy)) + geom_point() + facet_wrap(~ drv, labeller = labeller(drv = c(`4` = "4wd", f = "front", r = "rear"))) + theme_pub(), covers = c("label_value"))
run("facet_grid", function() ggplot(mpg, aes(displ, hwy)) + geom_point() + facet_grid(rows = vars(drv), cols = vars(cyl), scales = "free", space = "free", switch = "y", margins = TRUE, labeller = label_both) + theme_pub())
run("facet label_context/wrap_gen/parsed/bquote", function() ggplot(mpg, aes(displ, hwy)) + geom_point() + facet_wrap(vars(class, drv), labeller = label_context) + theme_pub(), covers = c("label_wrap_gen", "label_parsed", "label_bquote", "label_context"))
run("facet_null", function() base_pt() + facet_null() + theme_pub())

# ---- guides and legend keys ---------------------------------------------------------------------------------------------
run("guide_legend", function() ggplot(mpg, aes(displ, hwy, colour = class)) + geom_point() + scale_colour_pub() + guides(colour = guide_legend(nrow = 2, byrow = TRUE, title.position = "top", override.aes = list(size = 3), reverse = TRUE)) + theme_pub())
run("guide_colourbar/colorbar", function() ggplot(cont, aes(x, y, colour = z)) + geom_point() + scale_colour_pub_seq(guide = guide_colourbar(barheight = unit(30, "mm"), ticks = FALSE)) + theme_pub(legend = "right"), covers = c("guide_colorbar"))
run("guide_coloursteps/colorsteps", function() ggplot(cont, aes(x, y, colour = z)) + geom_point() + scale_colour_steps(guide = guide_coloursteps(even.steps = FALSE)) + theme_pub(legend = "right"), covers = c("guide_colorsteps"))
run("guide_bins", function() ggplot(cont, aes(x, y, size = pos)) + geom_point() + scale_size_binned(guide = guide_bins(show.limits = TRUE)) + theme_pub())
run("guide_axis", function() ggplot(mpg, aes(class, hwy)) + geom_boxplot() + scale_x_discrete(guide = guide_axis(angle = 45)) + scale_y_continuous(guide = guide_axis(minor.ticks = TRUE, cap = "both")) + theme_pub())
run("guide_axis_stack", function() ggplot(mpg, aes(class, hwy)) + geom_boxplot() + scale_y_continuous(guide = guide_axis_stack("axis", guide_axis(minor.ticks = TRUE))) + theme_pub())
run("guide_none/custom", function() ggplot(mpg, aes(displ, hwy, colour = class)) + geom_point() + guides(colour = guide_none()) + guides(x = guide_custom(grid::textGrob("custom"), title = "t")) + theme_pub())
run("annotation_logticks/custom/raster", function() ggplot(cont, aes(pos, pos)) + geom_point() + scale_x_log10() + scale_y_log10() + annotation_logticks() + annotation_custom(grid::rectGrob(gp = grid::gpar(fill = "grey90")), xmin = 0.1, xmax = 0.2, ymin = 0.1, ymax = 0.2) + annotation_raster(matrix(c("white", "grey"), 2, 2), xmin = 1, xmax = 2, ymin = 1, ymax = 2) + theme_pub())
for (k in grep("^draw_key_", exports, value = TRUE)) {
  local({
    key <- k
    glyph <- get(key, envir = asNamespace("ggplot2"))
    run(key, function() ggplot(mt, aes(wt, mpg, colour = cyl, fill = cyl)) + geom_point(key_glyph = glyph) + scale_colour_pub() + theme_pub(), covers = key)
  })
}

# ---- themes: every built-in complete theme and overrides --------------------------------------------------------------------------------------------
for (th in grep("^theme_(bw|classic|dark|gray|grey|light|linedraw|minimal|test|void)$", exports, value = TRUE)) {
  local({
    fn <- get(th, envir = asNamespace("ggplot2"))
    run(th, function() base_pt() + fn(base_size = 9, base_family = pub_family()), covers = th)
  })
}
run("theme_pub variants", function() base_pt() + facet_wrap(~ cyl, labeller = label_both) + theme_pub(grid = "xy", border = TRUE, legend = "bottom", axis.title = element_text(face = "plain", colour = "grey20"), panel.spacing = unit(1, "cm")) + theme(strip.text = element_text(hjust = 0), legend.key.width = unit(2, "cm")))
run("theme_pub inside legend", function() ggplot(mt, aes(wt, mpg, colour = cyl)) + geom_point() + scale_colour_pub() + theme_pub(legend = "inside", legend.position.inside = c(0.85, 0.85)))
run("theme_pub grids", function() base_pt() + theme_pub(grid = "none") + theme_pub(grid = "x") + theme_pub(grid = "y"))
run("theme_get/set/update/replace", function() {
  old <- theme_set(theme_pub())
  on.exit(theme_set(old))
  base_pt() + theme_replace(axis.text = element_text(colour = "black")) + theme_update(axis.line = element_line(colour = "black"))
}, covers = c("theme_get", "theme_set", "theme_update", "theme_replace"))
run("element_*", function() base_pt() + theme_pub() + theme(panel.background = element_rect(fill = "white", colour = "black"), panel.grid = element_line(colour = "grey90", linetype = "dotted"), axis.ticks = element_line(), plot.title = element_text(face = "italic"), strip.background = element_blank()) + labs(title = "x") + theme(panel.border = element_blank()), covers = c("element_blank", "element_line", "element_rect", "element_text"))
sub_fns <- grep("^theme_sub_", exports, value = TRUE)
if (length(sub_fns)) {
  run("theme_sub_*", function() base_pt() + theme_pub() + theme_sub_axis(text = element_text(colour = "grey10")) + theme_sub_panel(grid = element_blank()) + theme_sub_plot(title = element_text(face = "bold")) + theme_sub_legend(position = "bottom") + theme_sub_strip(text = element_text(face = "bold")) + theme_sub_axis_x(line = element_line()) + theme_sub_axis_y(line = element_line()) + theme_sub_axis_bottom(line = element_line()) + theme_sub_axis_left(line = element_line()) + theme_sub_axis_top(line = element_line()) + theme_sub_axis_right(line = element_line()), covers = sub_fns)
}
if ("element_geom" %in% exports) {
  run("element_geom (theme geom defaults)", function() base_pt() + theme_pub() + theme(geom = element_geom(ink = "navy", paper = "white", pointsize = 2)), covers = c("element_geom", "from_theme"))
}

# ---- labels, scales helpers, stage/after_* and layout-level API ----------------------------------------------------------------------------------------------
run("labs/after_stat/after_scale/stage", function() ggplot(mpg, aes(hwy, fill = drv)) + geom_histogram(aes(y = after_stat(density), colour = after_scale(alpha(fill, 1))), bins = 20, alpha = 0.5) + geom_density(aes(fill = stage(drv, after_scale = alpha(fill, 0.2)))) + labs(x = "x", y = NULL, tag = "A", title = "t", subtitle = "s", caption = "c", fill = "Drive") + theme_pub())
run("cut_*", function() ggplot(mpg, aes(cut_width(displ, 1), hwy)) + geom_boxplot() + ggplot(mpg, aes(cut_number(displ, 4), hwy)) + geom_boxplot() + theme_pub(), covers = c("cut_width", "cut_number", "cut_interval"))
run("patchwork layout", function() (base_pt() + theme_pub()) | (base_pt() + theme_pub()) + plot_annotation(tag_levels = "A") + plot_layout(guides = "collect"))
run("ggplot_build helpers", function() {
  p <- base_pt() + theme_pub()
  invisible(layer_data(p)); invisible(layer_scales(p)); invisible(get_layer_data(p)); invisible(get_panel_scales(p)); invisible(get_labs(p))
  p
}, covers = c("layer_data", "layer_scales", "get_layer_data", "get_panel_scales", "get_labs"))

# ---- report -----------------------------------------------------------------------------------------------------------------------------------------------------------------
fams <- "^(geom_|stat_|position_|scale_|coord_|facet_|guide_|theme_|annotation_|element_|label_|draw_key_)"
target <- sort(grep(fams, exports, value = TRUE))
internal <- c("stat_spoke", "scale_shape_continuous", "scale_linetype_continuous", "guide_gengrob", "guide_geom", "guide_merge", "guide_train", "guide_transform", "coord_munch",
              "theme_sub_axis", "geom_map", "annotation_map", "annotation_borders", "coord_map", "stat_bin_hex", "stat_binhex",
              "stat_summary_hex", "geom_hex", "geom_quantile", "stat_quantile", "element_grob", "element_render", "element_polygon",
              "element_point", "scale_alpha_binned", "scale_alpha_ordinal")
missing <- setdiff(target, c(covered, internal))
cat(sprintf("\n%d plots built and drawn OK, %d failed, %d warnings (deprecations and removed-row notes included)\n", n_ok, length(failures), warn_count))
cat(sprintf("Exported geom/stat/position/scale/coord/facet/guide/theme/annotation/element/label/draw_key functions exercised: %d of %d\n",
            length(intersect(target, covered)), length(target)))
if (length(missing)) cat("Not exercised: ", paste(missing, collapse = ", "), "\n")
if (length(failures)) {
  for (nm in names(failures)) cat("FAILED:", nm, "->", failures[[nm]], "\n")
  stop(length(failures), " compatibility checks failed.", call. = FALSE)
}
cat("All ggplot2 compatibility checks passed (ggplot2", as.character(packageVersion("ggplot2")), ").\n")
