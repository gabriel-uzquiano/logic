# ql_translation.R
# Helpers for embedding the QL Translation app into a bookdown book.
# Pairs with exercises/ql-translations.yml (see qtr_load()).
#
# Setup chunk (index.Rmd):
#   source("R/ql_translation.R")
#   qtrans <- qtr_load("exercises/ql-translations.yml")
#
# Inline usage:
#   `r qtr_link(qtrans[["trojans-1"]])`
#   `r qtr_embed(qtrans[["trojans-1"]])`
#   `r qtr_embed_toggle(qtrans[["trojans-1"]])`
#
# URL hash format: #v1:<base64(UTF-8 JSON)>
#   JSON shape:
#   {
#     sentences:   [{ text, refFormula, refPredicates: [{letter,arity,clause}],
#                                        refConstants:  [{letter,name}] }],
#     wsPredicates: [{letter, arity, clause}],
#     wsConstants:  [{letter, name}],
#     trans:        [{formula, revealed}]
#   }
#
#   sentences    — English sentences with reference formula and key
#   wsPredicates — student's predicate letter assignments (worksheet card)
#   wsConstants  — student's constant letter assignments (worksheet card)
#   trans        — student's formula entries in the Translation card
#
# How to capture hashes:
#   student_hash  — in instructor mode (?key=show), enter sentence(s) + ref
#                   key; leave wsPredicates, wsConstants, and trans blank;
#                   press "Copy link"
#   worked_hash   — same, but also fill in a correct key and translation
#
# instructor mode: append ?key=show before the hash fragment
#
# YAML entry shape:
#   - id: "trojans-1"
#     label: "Trojans & Achilles 1"
#     student_hash: "#v1:eyJz..."   # sentence loaded, worksheet + translation blank
#     worked_hash:  "#v1:eyJz..."   # sentence + key + worked translation

QTR_BASE <- "https://ql-translation.pplx.app/"


# Return x unchanged — HTML rendering requires a results='asis' chunk
# or a fenced div block (:::{.example}), matching the proof checker pattern.
.as_html <- function(x) x

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

qtr_str <- function(x) {
  if (is.null(x)) return("")
  x <- as.character(x)
  if (length(x) > 1L) x <- paste(x, collapse = "\n")
  x
}

# solution = FALSE -> student_hash  (sentence loaded, worksheet + translation blank)
# solution = TRUE  -> worked_hash   (sentence + key + worked translation)
qtr_url <- function(ex, solution = FALSE, instructor = FALSE) {
  hash  <- if (solution) qtr_str(ex$worked_hash) else qtr_str(ex$student_hash)
  query <- if (instructor) "?key=show" else ""
  paste0(QTR_BASE, query, hash)
}

# ---------------------------------------------------------------------------
# qtr_link() — plain hyperlink (HTML and PDF)
# ---------------------------------------------------------------------------
qtr_link <- function(ex, solution = FALSE, instructor = FALSE, label = NULL) {
  txt <- if (is.null(label)) qtr_str(ex$label) else label
  if (!nzchar(txt)) txt <- qtr_str(ex$id)
  sprintf("[%s](%s)", txt, qtr_url(ex, solution = solution, instructor = instructor))
}

# ---------------------------------------------------------------------------
# qtr_iframe() — raw <iframe> with Open button
# ---------------------------------------------------------------------------
qtr_iframe <- function(ex, solution = FALSE, instructor = FALSE, height = 580L) {
  url <- qtr_url(ex, solution = solution, instructor = instructor)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="QL Translation" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, as.integer(height)
  )
}

# ---------------------------------------------------------------------------
# qtr_embed() — format-aware embed
# ---------------------------------------------------------------------------
# height guide:
#   480 — 1 sentence
#   580 — 1–2 sentences (default)
#   700 — 3+ sentences with full key
qtr_embed <- function(ex, solution = FALSE, instructor = FALSE, height = 580L) {
  if (knitr::is_html_output()) {
    .as_html(qtr_iframe(ex, solution = solution, instructor = instructor, height = height))
  } else {
    qtr_link(ex, solution = solution, instructor = instructor)
  }
}

# ---------------------------------------------------------------------------
# qtr_embed_labeled() — embed with a caption above
# ---------------------------------------------------------------------------
qtr_embed_labeled <- function(ex, solution = FALSE, instructor = FALSE,
                               height = 580L, caption = NULL) {
  if (!knitr::is_html_output()) return(qtr_link(ex, solution = solution, instructor = instructor))
  cap    <- if (!is.null(caption)) caption else qtr_str(ex$label)
  iframe <- qtr_iframe(ex, solution = solution, instructor = instructor, height = height)
  if (nzchar(cap)) {
    .as_html(paste0('<p style="font-size:0.82em;color:#666;margin:0.25em 0 2px 2px">',
           cap, '</p>', iframe))
  } else {
    .as_html(iframe)
  }
}

# ---------------------------------------------------------------------------
# qtr_embed_toggle() — blank worksheet on top; worked translation on click
# ---------------------------------------------------------------------------
qtr_embed_toggle <- function(ex, height = 580L, summary = "Show translation") {
  if (!knitr::is_html_output()) return(qtr_link(ex, solution = FALSE))
  practice <- qtr_iframe(ex, solution = FALSE, height = height)
  worked   <- qtr_iframe(ex, solution = TRUE,  height = height)
  .as_html(sprintf(
    '%s
<details style="margin-top:0.25em">
  <summary style="cursor:pointer;color:#7a003c;font-size:0.88em;
                  padding:3px 0;user-select:none">%s</summary>
  %s
</details>',
    practice, summary, worked
  ))
}

# ---------------------------------------------------------------------------
# qtr_load() — read YAML into a named list keyed by id
# ---------------------------------------------------------------------------
qtr_load <- function(file = "exercises/ql-translations.yml") {
  if (!file.exists(file)) return(list())
  raw <- yaml::read_yaml(file)
  if (is.null(raw) || length(raw) == 0L) return(list())
  # Unwrap top-level 'entries:' key if present
  if (is.list(raw) && !is.null(raw$entries)) raw <- raw$entries
  if (length(raw) == 0L) return(list())
  ids <- vapply(raw, function(e) qtr_str(e$id), character(1L))
  stats::setNames(raw, ids)
}
