# Journal figure specifications

Values summarise publisher author guidelines as commonly published; they change, so confirm
the target journal's current "artwork" page before final submission. `save_pub(journal = ...)`
uses these widths.

| Preset (`journal =`) | Single column | 1.5 column | Double column | Max height |
|---|---|---|---|---|
| `elsevier` | 90 mm | 140 mm | 190 mm | ~240 mm |
| `springer` (Springer Nature journals) | 84 mm | 129 mm | 174 mm | 234 mm |
| `nature` (Nature portfolio) | 89 mm | 120-136 mm | 183 mm | 247 mm |
| `cell` (Cell Press) | 85 mm | 114 mm | 174 mm | ~225 mm |
| `acs` | 3.25 in (82.5 mm) | -- | 7 in (178 mm) | 9.5 in |
| `wiley` (varies by journal) | ~80 mm | ~125 mm | ~170 mm | ~230 mm |
| `plos` | 2.63-7.5 in wide; text column 5.2 in (132 mm) | -- | 7.5 in (190.5 mm) | 8.75 in |
| `science` | 55 mm (1 col) | 120 mm (2 col) | 183 mm (3 col) | -- |
| `mdpi` | flexible; ~85 mm | -- | ~170 mm | -- |
| `default` | 85 mm | 120 mm | 175 mm | 230 mm |

## Resolution and formats
- Line art (plots): vector PDF/EPS preferred; if raster, >= 1000 dpi (many publishers) -- 600 dpi TIFF is accepted by most.
- Halftone (photos, micrographs): >= 300 dpi. Combination (plot + image): >= 500-600 dpi.
- TIFF with LZW compression is the safest raster format; PNG is fine for drafts, theses and web.
- RGB for online journals; convert to CMYK only if the journal demands it (check colors after conversion).
- `save_pub()` default: PDF (cairo, fonts embedded) + 600-dpi LZW TIFF + 600-dpi PNG.

## Text
- Final printed size 6-9 pt (Nature: 5-7 pt; Cell: 6-8 pt; Elsevier/Springer: ~7-10 pt). Use `theme_pub(base_size = 8)`
  for single column and 8-9 for double, saved at true width; do not save large and let the journal shrink it.
- Sans-serif (Arial/Helvetica) is requested by Nature, Cell, Science, PLOS; many engineering/pharmaceutical
  journals accept Times New Roman. Use one font across all figures: `pub_font("Arial")` before plotting.
- Panel labels: bold capital letters (A, B, C) for most journals; Nature uses bold lowercase (a, b, c):
  `plot_annotation(tag_levels = "a")`.
- Units in parentheses: "Time (h)", "Concentration (ug/mL)" with proper symbols via `expression()`.

## Lines and markers at final size
- Axis lines 0.5-1 pt (theme_pub uses base_size/20 mm-ish linewidth: ~0.4 at 8 pt).
- Data lines 0.5-1 pt; minimum 0.25 pt anywhere.
- Point size 1-2 mm; hollow shapes need linewidth >= 0.4.

## Thesis figures
University templates usually have ~150-160 mm text width; use `save_pub(width = 150)` and the same base_size, so
thesis and article figures share one script.
