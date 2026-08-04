# prop_translation.R
# Helpers for embedding the Propositional Translation app into a bookdown book.
# Pairs with exercises/prop-translations.yml (see ptr_load()).
#
# Setup chunk (index.Rmd):
#   source("R/prop_translation.R")
#   ptrans <- ptr_load("exercises/prop-translations.yml")
#
# Inline usage:
#   `r ptr_link(ptrans[["burglar-1"]])`
#   `r ptr_embed(ptrans[["burglar-1"]])`
#   `r ptr_embed_toggle(ptrans[["burglar-1"]])`
#   `r ptr_embed_toggle_cards(ptrans[["ch4-ex1a"]])`
#
# URL hash format: #v1:<base64(JSON)>
#   JSON shape:
#   {
#     sentences: [{ text, refFormula, refAtoms: [{letter, clause}] }],
#     wsAtoms:   [{letter, clause}],
#     trans:     [{formula}]
#   }
#
# YAML entry shape:
#   - id: "ch4-ex1a"
#     label: "Ch4 Exercise 1a"
#     student_hash: "#v1:eyJz..."   # sentences loaded, worksheet + translation blank
#     worked_hash:  "#v1:eyJz..."   # sentences + key + worked translation filled in
#
# instructor mode: append ?key=show to the URL before the hash

PTR_BASE <- "https://gabriel-uzquiano.github.io/prop-translation/"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

ptr_str <- function(x) {
  if (is.null(x)) return("")
  x <- as.character(x)
  if (length(x) > 1L) x <- paste(x, collapse = "\n")
  x
}

# solution = FALSE -> student_hash  (sentences loaded, worksheet + translation blank)
# solution = TRUE  -> worked_hash   (sentences + key + worked translation)
ptr_url <- function(ex, solution = FALSE, instructor = FALSE) {
  hash  <- if (solution) ptr_str(ex$worked_hash) else ptr_str(ex$student_hash)
  query <- if (instructor) "?key=show" else ""
  paste0(PTR_BASE, query, hash)
}

# ---------------------------------------------------------------------------
# ptr_link() — plain hyperlink (HTML and PDF)
# ---------------------------------------------------------------------------
ptr_link <- function(ex, solution = FALSE, instructor = FALSE, label = NULL) {
  txt <- if (is.null(label)) ptr_str(ex$label) else label
  if (!nzchar(txt)) txt <- ptr_str(ex$id)
  sprintf("[%s](%s)", txt, ptr_url(ex, solution = solution, instructor = instructor))
}

# ---------------------------------------------------------------------------
# ptr_iframe() — raw <iframe> with Open button
# ---------------------------------------------------------------------------
ptr_iframe <- function(ex, solution = FALSE, instructor = FALSE, height = 520L) {
  url <- ptr_url(ex, solution = solution, instructor = instructor)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  sprintf(
    '<div style="margin:0.5em 0 1em 0">
  <div style="text-align:right;margin-bottom:2px">
    <a href="%s" target="_blank"
       style="font-size:0.72em;background:#fff;padding:2px 7px;
              border:1px solid #ccc;border-radius:4px;
              text-decoration:none;color:#444">Open &#x2197;</a>
  </div>
  <iframe title="Propositional Translation" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, as.integer(height)
  )
}

# ---------------------------------------------------------------------------
# ptr_iframe_card() — embed showing only specific cards via ?card=
# ---------------------------------------------------------------------------
# card: comma-separated subset of "sentences", "worksheet", "translation"
# e.g. card = "worksheet,translation" hides the Sentences card
ptr_iframe_card <- function(ex, card = "worksheet,translation",
                             solution = FALSE, instructor = FALSE, height = 420L) {
  if (!knitr::is_html_output()) return(ptr_link(ex, solution = solution, instructor = instructor))
  base_url <- ptr_url(ex, solution = solution, instructor = instructor)
  # Insert ?card= before the # hash
  hash_pos <- regexpr("#", base_url, fixed = TRUE)
  if (hash_pos > 0) {
    full_url <- paste0(substr(base_url, 1, hash_pos - 1),
                       "?card=", URLencode(card, reserved = FALSE),
                       substr(base_url, hash_pos, nchar(base_url)))
  } else {
    full_url <- paste0(base_url, "?card=", URLencode(card, reserved = FALSE))
  }
  src <- gsub("&", "&amp;", full_url, fixed = TRUE)
  sprintf(
    '<div style="margin:0.5em 0 1em 0">
  <div style="text-align:right;margin-bottom:2px">
    <a href="%s" target="_blank"
       style="font-size:0.72em;background:#fff;padding:2px 7px;
              border:1px solid #ccc;border-radius:4px;
              text-decoration:none;color:#444">Open &#x2197;</a>
  </div>
  <iframe title="Propositional Translation" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy"></iframe>
</div>',
    base_url, src, as.integer(height)
  )
}

# ---------------------------------------------------------------------------
# ptr_embed() — format-aware embed
# ---------------------------------------------------------------------------
# height guide:
#   420 — 1–2 sentences, compact
#   520 — 2–3 sentences (default)
#   640 — 3–5 sentences / argument
ptr_embed <- function(ex, solution = FALSE, instructor = FALSE, height = 520L) {
  if (knitr::is_html_output()) {
    ptr_iframe(ex, solution = solution, instructor = instructor, height = height)
  } else {
    ptr_link(ex, solution = solution, instructor = instructor)
  }
}

# ---------------------------------------------------------------------------
# ptr_embed_labeled() — embed with a caption above
# ---------------------------------------------------------------------------
ptr_embed_labeled <- function(ex, solution = FALSE, instructor = FALSE,
                               height = 520L, caption = NULL) {
  if (!knitr::is_html_output()) return(ptr_link(ex, solution = solution, instructor = instructor))
  cap    <- if (!is.null(caption)) caption else ptr_str(ex$label)
  iframe <- ptr_iframe(ex, solution = solution, instructor = instructor, height = height)
  if (nzchar(cap)) {
    paste0('<p style="font-size:0.82em;color:#666;margin:0.25em 0 2px 2px">',
           cap, '</p>', iframe)
  } else {
    iframe
  }
}

# ---------------------------------------------------------------------------
# ptr_embed_toggle() — full app: blank on top, worked translation on click
# ---------------------------------------------------------------------------
ptr_embed_toggle <- function(ex, height = 520L, summary = "Show translation") {
  if (!knitr::is_html_output()) return(ptr_link(ex, solution = FALSE))
  practice <- ptr_iframe(ex, solution = FALSE, height = height)
  worked   <- ptr_iframe(ex, solution = TRUE,  height = height)
  sprintf(
    '%s
<details style="margin-top:0.25em">
  <summary style="display:flex;align-items:center;gap:0.3em;list-style:none;
                  cursor:pointer;color:#7a003c;font-size:0.88em;
                  padding:3px 0;user-select:none">
    <span style="display:inline-block">&#9654;</span>
    <span>%s</span>
  </summary>
  %s
</details>',
    practice, summary, worked
  )
}

# ---------------------------------------------------------------------------
# ptr_embed_toggle_cards() — worksheet+translation cards on top;
#                            full worked app on click
# ---------------------------------------------------------------------------
# Standard pattern for exercises inside a numbered/lettered list:
#   practice: card="worksheet,translation" — student fills key + formula
#   solution: full app with all cards + worked answer
#
# `r ptr_embed_toggle_cards(ptrans[["ch4-ex1a"]])`
ptr_embed_toggle_cards <- function(ex,
                                    practice_height = 420L,
                                    worked_height   = 520L,
                                    summary         = "Show translation") {
  if (!knitr::is_html_output()) return(ptr_link(ex, solution = FALSE))
  practice <- ptr_iframe_card(ex, card = "worksheet,translation",
                               solution = FALSE, height = practice_height)
  worked   <- ptr_iframe(ex, solution = TRUE, height = worked_height)
  sprintf(
    '%s
<details style="margin-top:0.25em">
  <summary style="display:flex;align-items:center;gap:0.3em;list-style:none;
                  cursor:pointer;color:#7a003c;font-size:0.88em;
                  padding:3px 0;user-select:none">
    <span style="display:inline-block">&#9654;</span>
    <span>%s</span>
  </summary>
  %s
</details>',
    practice, summary, worked
  )
}

# ---------------------------------------------------------------------------
# ptr_load() — read YAML into a named list keyed by id
# ---------------------------------------------------------------------------
ptr_load <- function(file = "exercises/prop-translations.yml") {
  if (!file.exists(file)) return(list())
  raw <- yaml::read_yaml(file)
  if (is.null(raw) || length(raw) == 0L) return(list())
  # Unwrap top-level 'entries:' key if present
  if (is.list(raw) && !is.null(raw$entries)) raw <- raw$entries
  if (length(raw) == 0L) return(list())
  ids <- vapply(raw, function(e) ptr_str(e$id), character(1L))
  stats::setNames(raw, ids)
}