# truth_table.R
# Helpers for embedding the Truth Table app into a bookdown book.
# Pairs with exercises/truth-tables.yml (see tt_load()).
#
# Setup chunk (index.Rmd):
#   source("R/truth_table.R")
#   ttables <- tt_load("exercises/truth-tables.yml")
#
# Inline usage:
#   `r tt_link(ttables[["taut-1"]])`
#   `r tt_embed(ttables[["taut-1"]])`
#   `r tt_embed(ttables[["taut-1"]], height = 380)`
#   `r tt_embed_toggle(ttables[["taut-1"]])`
#
# URL hash format: #v1:<base64(JSON)>
#   JSON shape: { formulas?: string[], build?: string }
#
#   formulas — array of formula strings shown in the evaluation slots
#   build    — formula string pre-loaded in the "Build a formula" tab
#
# The easiest way to capture a hash: enter the formulas in the browser, press
# "Copy link", and paste the #v1:... fragment into the YAML.
#
# YAML entry shape:
#   - id: "taut-1"
#     label: "Tautology 1"
#     formula_hash: "#v1:eyJmb..."    # formulas loaded, no build formula
#     worked_hash:  "#v1:eyJmb..."    # same formulas, highlighting visible
#                                     # (for truth tables, formula_hash and
#                                     #  worked_hash are often identical — the
#                                     #  app shows its output immediately)

TT_BASE <- "https://gabriel-uzquiano.github.io/prop-truth-table/"


# Return x unchanged — HTML rendering requires a results='asis' chunk
# or a fenced div block (:::{.example}), matching the proof checker pattern.
.as_html <- function(x) x

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

tt_str <- function(x) {
  if (is.null(x)) return("")
  x <- as.character(x)
  if (length(x) > 1L) x <- paste(x, collapse = "\n")
  x
}

# solution = FALSE -> formula_hash (formulas pre-loaded; table shown immediately)
# solution = TRUE  -> worked_hash  (same, or a richer pre-built formula)
tt_url <- function(ex, solution = FALSE) {
  hash <- if (solution) tt_str(ex$worked_hash) else tt_str(ex$formula_hash)
  # Fall back to extracting hash from the 'url' field if no explicit hash field
  if (!nzchar(hash) && !is.null(ex$url)) {
    hash <- sub("^[^#]*", "", tt_str(ex$url))
  }
  paste0(TT_BASE, hash)
}

tt_table_url <- function(ex, solved = FALSE) {
  base_url <- tt_url(ex, solution = FALSE)
  hash     <- sub("^[^#]*", "", base_url)
  # v=2: cache-bust so browsers pick up the latest app.js
  params   <- if (solved) "?card=table&solved=1&v=2" else "?card=table&v=2"
  paste0(TT_BASE, params, hash)
}

# ---------------------------------------------------------------------------
# tt_link() — plain hyperlink (HTML and PDF)
# ---------------------------------------------------------------------------
tt_link <- function(ex, solution = FALSE, label = NULL) {
  txt <- if (is.null(label)) tt_str(ex$label) else label
  if (!nzchar(txt)) txt <- tt_str(ex$id)
  sprintf("[%s](%s)", txt, tt_url(ex, solution = solution))
}

# ---------------------------------------------------------------------------
# tt_iframe() — raw <iframe> with Open button
# ---------------------------------------------------------------------------
tt_iframe <- function(ex, solution = FALSE, height = 440L) {
  url <- tt_url(ex, solution = solution)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Truth Table" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, as.integer(height)
  )
}

# ---------------------------------------------------------------------------
# tt_embed() — format-aware embed
# ---------------------------------------------------------------------------
# height guide:
#   340 — 1 formula, 2 variables
#   440 — 1–2 formulas, 2–3 variables (default)
#   540 — 2–3 formulas, or 3–4 variables
#   640 — multiple formulas or 4+ variables
tt_embed <- function(ex, solution = FALSE, height = 440L) {
  if (knitr::is_html_output()) {
    .as_html(tt_iframe(ex, solution = solution, height = height))
  } else {
    tt_link(ex, solution = solution)
  }
}

# ---------------------------------------------------------------------------
# tt_embed_table() — Build card only (?card=table); no Formulas or Check cards
# Use for in-text practice where students fill in the truth table.
# ---------------------------------------------------------------------------
tt_embed_table <- function(ex, height = 440L) {
  if (!knitr::is_html_output()) return(tt_link(ex))
  url <- tt_table_url(ex)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  .as_html(sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Truth Table" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, as.integer(height)
  ))
}

# ---------------------------------------------------------------------------
# tt_embed_solved() — worked table only (all cells pre-filled, read-only)
# ---------------------------------------------------------------------------
tt_embed_solved <- function(ex, height = 440L) {
  if (!knitr::is_html_output()) return(tt_link(ex))
  url <- tt_table_url(ex, solved = TRUE)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  .as_html(sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Truth Table" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, as.integer(height)
  ))
}

# ---------------------------------------------------------------------------
# tt_embed_toggle() — practice table + "Show worked table" reveal
# ---------------------------------------------------------------------------
tt_embed_toggle <- function(ex, height = 440L, worked_height = NULL,
                            summary = "Show worked table") {
  if (!knitr::is_html_output()) return(tt_link(ex))
  worked_height <- worked_height %||% height

  practice_url <- tt_table_url(ex, solved = FALSE)
  worked_url   <- tt_table_url(ex, solved = TRUE)

  practice_src <- gsub("&", "&amp;", practice_url, fixed = TRUE)
  worked_src   <- gsub("&", "&amp;", worked_url,   fixed = TRUE)

  practice_iframe <- sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Truth Table" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>', practice_url, practice_src, as.integer(height))

  worked_iframe <- sprintf(
    '<div style="position:relative;margin:0.5em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Worked Truth Table" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>', worked_url, worked_src, as.integer(worked_height))

  .as_html(sprintf(
    '%s
<details style="margin-top:0.25em">
  <summary style="cursor:pointer;color:#7a003c;font-size:0.88em;
                  padding:3px 0;user-select:none">%s</summary>
  %s
</details>',
    practice_iframe, summary, worked_iframe
  ))
}

`%||%` <- function(a, b) if (!is.null(a)) a else b

# ---------------------------------------------------------------------------
# tt_embed_labeled() — embed with a caption above
# ---------------------------------------------------------------------------
tt_embed_labeled <- function(ex, solution = FALSE, height = 440L, caption = NULL) {
  if (!knitr::is_html_output()) return(tt_link(ex, solution = solution))
  cap    <- if (!is.null(caption)) caption else tt_str(ex$label)
  iframe <- tt_iframe(ex, solution = solution, height = height)
  if (nzchar(cap)) {
    .as_html(paste0('<p style="font-size:0.82em;color:#666;margin:0.25em 0 2px 2px">',
           cap, '</p>', iframe))
  } else {
    .as_html(iframe)
  }
}

# (duplicate tt_embed_toggle removed — see definition above)

# ---------------------------------------------------------------------------
# tt_load() — read YAML into a named list keyed by id
# ---------------------------------------------------------------------------
tt_load <- function(file = "exercises/truth-tables.yml") {
  if (!file.exists(file)) return(list())
  raw <- yaml::read_yaml(file)
  if (is.null(raw) || length(raw) == 0L) return(list())
  # Unwrap top-level 'entries:' key if present
  if (is.list(raw) && !is.null(raw$entries)) raw <- raw$entries
  if (length(raw) == 0L) return(list())
  ids <- vapply(raw, function(e) tt_str(e$id), character(1L))
  stats::setNames(raw, ids)
}

# ---------------------------------------------------------------------------
# tt_embed_check() — shows only the check result (no formulas card, no build
# card, no Evaluate button). Requires a ?mode= entry (tautology/equivalence/
# validity). Use for illustration where you just want the verdict + table.
# ---------------------------------------------------------------------------
tt_check_url <- function(ex) {
  base_url <- tt_url(ex, solution = FALSE)
  hash     <- sub("^[^#]*", "", base_url)
  existing_mode <- regmatches(base_url, regexpr("(?<=mode=)[^&]+", base_url, perl=TRUE))
  mode <- if (length(existing_mode) && nzchar(existing_mode)) existing_mode else tt_str(ex$mode)
  if (!nzchar(mode)) mode <- "tautology"
  type <- tt_str(ex$type)
  type_param <- if (nzchar(type)) paste0("&type=", type) else ""
  paste0(TT_BASE, "?mode=", mode, "&autorun=1", type_param, hash)
}

tt_embed_check <- function(ex, height = 380L) {
  if (!knitr::is_html_output()) return(tt_link(ex))
  url <- tt_check_url(ex)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  .as_html(sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Truth Table Check" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, as.integer(height)
  ))
}

# ---------------------------------------------------------------------------
# tt_embed_search() — counterexample search mode (?search=1).
# Shows only rows where the conclusion is false; highlights any row
# where all premises are also true (genuine counterexample).
# Last formula = conclusion; all others = premises.
# ---------------------------------------------------------------------------
tt_search_url <- function(ex) {
  base_url <- tt_url(ex, solution = FALSE)
  hash     <- sub("^[^#]*", "", base_url)
  paste0(TT_BASE, "?search=1", hash)
}

# ---------------------------------------------------------------------------
# tt_embed_blank() — embeds the full app with no formulas pre-loaded.
# Students enter their own formulas and interact freely.
# ---------------------------------------------------------------------------
tt_embed_blank <- function(height = 500L, mode = NULL) {
  if (!knitr::is_html_output()) return(invisible(NULL))
  url <- if (!is.null(mode)) paste0(TT_BASE, "?v=2&mode=", mode) else paste0(TT_BASE, "?v=2")
  .as_html(sprintf(
    '<div style="margin:1em 0">
  <iframe title="Truth Table App" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, as.integer(height)
  ))
}

# Convenience wrappers for each mode
tt_embed_blank_tautology    <- function(height = 500L) tt_embed_blank(height, mode = "tautology")
tt_embed_blank_equivalence  <- function(height = 500L) tt_embed_blank(height, mode = "equivalence")
tt_embed_blank_consistency  <- function(height = 500L) tt_embed_blank(height, mode = "consistency")
tt_embed_blank_validity     <- function(height = 500L) tt_embed_blank(height, mode = "validity")

tt_embed_search <- function(ex, height = 380L) {
  if (!knitr::is_html_output()) return(tt_link(ex))
  url <- tt_search_url(ex)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  .as_html(sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Counterexample Search" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, as.integer(height)
  ))
}