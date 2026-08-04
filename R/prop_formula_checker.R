# prop_formula_checker.R
# Helpers for embedding the Propositional Formula Checker into a bookdown book.
# Pairs with exercises/prop-formulas.yml (see pfc_load()).
#
# Setup chunk (index.Rmd):
#   source("R/prop_formula_checker.R")
#   pformulas <- pfc_load("exercises/prop-formulas.yml")
#
# Inline usage:
#   `r pfc_link(pformulas[["wff-1"]])`
#   `r pfc_embed(pformulas[["wff-1"]])`
#   `r pfc_embed(pformulas[["wff-1"]], height = 320)`
#
# URL hash format: #v1:<base64(JSON)>
#   JSON shape: { f: "<formula>", a?: { p: true/false, q: true/false, ... } }
#
# The easiest way to capture a hash: type the formula (and optionally set the
# truth-value assignment) in the browser, press "Copy link", and paste the
# #v1:... fragment into the YAML as formula_hash (quote it — a bare # starts
# a YAML comment).
#
# YAML entry shape:
#   - id: "wff-1"
#     label: "Well-formed formula 1"
#     formula_hash: "#v1:eyJmIjoiKHB..."   # formula pre-loaded, no assignment
#     worked_hash:  "#v1:eyJmIjoiKHAi..."  # formula + truth-value assignment set

PFC_BASE <- "https://gabriel-uzquiano.github.io/prop-formula-checker/"


# Return x unchanged — HTML rendering requires a results='asis' chunk
# or a fenced div block (:::{.example}), matching the proof checker pattern.
.as_html <- function(x) x

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

pfc_str <- function(x) {
  if (is.null(x)) return("")
  x <- as.character(x)
  if (length(x) > 1L) x <- paste(x, collapse = "\n")
  x
}

# solution = TRUE  -> worked_hash  (formula + assignment filled in)
# solution = FALSE -> formula_hash (formula only, student sets assignment)
# Falls back to extracting the hash from the 'url' field if formula_hash is absent.
pfc_url <- function(ex, solution = FALSE) {
  hash <- if (solution) pfc_str(ex$worked_hash) else pfc_str(ex$formula_hash)
  if (!nzchar(hash) && !is.null(ex$url)) {
    # extract fragment from full URL
    hash <- sub("^[^#]*", "", pfc_str(ex$url))
  }
  paste0(PFC_BASE, hash)
}

# ---------------------------------------------------------------------------
# pfc_link() — plain hyperlink (HTML and PDF)
# ---------------------------------------------------------------------------
pfc_link <- function(ex, solution = FALSE, label = NULL) {
  txt <- if (is.null(label)) pfc_str(ex$label) else label
  if (!nzchar(txt)) txt <- pfc_str(ex$id)
  sprintf("[%s](%s)", txt, pfc_url(ex, solution = solution))
}

# ---------------------------------------------------------------------------
# pfc_iframe() — raw <iframe> with Open button
# ---------------------------------------------------------------------------
pfc_iframe <- function(ex, solution = FALSE, height = 360L) {
  url <- pfc_url(ex, solution = solution)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Propositional Formula Checker" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, as.integer(height)
  )
}

# ---------------------------------------------------------------------------
# pfc_embed() — format-aware embed
# ---------------------------------------------------------------------------
# height guide:
#   300 — formula entry + parse tree only (no evaluation)
#   360 — formula + tree + evaluation row (default)
#   420 — formula + tree + full truth table
pfc_embed <- function(ex, solution = FALSE, height = 360L) {
  if (knitr::is_html_output()) {
    .as_html(pfc_iframe(ex, solution = solution, height = height))
  } else {
    pfc_link(ex, solution = solution)
  }
}

# ---------------------------------------------------------------------------
# pfc_embed_labeled() — embed with a caption above
# ---------------------------------------------------------------------------
pfc_embed_labeled <- function(ex, solution = FALSE, height = 360L, caption = NULL) {
  if (!knitr::is_html_output()) return(pfc_link(ex, solution = solution))
  cap    <- if (!is.null(caption)) caption else pfc_str(ex$label)
  iframe <- pfc_iframe(ex, solution = solution, height = height)
  if (nzchar(cap)) {
    .as_html(paste0('<p style="font-size:0.82em;color:#666;margin:0.25em 0 2px 2px">',
           cap, '</p>', iframe))
  } else {
    .as_html(iframe)
  }
}

# ---------------------------------------------------------------------------
# pfc_tree_iframe() — tree-only iframe (?card=tree) for use in toggles
# ---------------------------------------------------------------------------
pfc_tree_iframe <- function(ex, solution = FALSE, height = 360L) {
  full_base_url <- pfc_url(ex, solution = solution)
  hash          <- sub("^[^#]*", "", full_base_url)
  full_url      <- paste0(PFC_BASE, "?card=tree", hash)
  src           <- gsub("&", "&amp;", full_url, fixed = TRUE)
  sprintf(
    '<div style="position:relative;margin:0.5em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Parse Tree" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy"></iframe>
</div>',
    full_base_url, src, as.integer(height)
  )
}

# ---------------------------------------------------------------------------
# pfc_embed_toggle() — practice app on top; reveal shows parse tree
# ---------------------------------------------------------------------------
pfc_embed_toggle <- function(ex, height = 360L, tree_height = 300L, summary = "Show parse tree") {
  if (!knitr::is_html_output()) return(pfc_link(ex, solution = FALSE))
  practice <- pfc_iframe(ex, solution = FALSE, height = height)
  worked   <- pfc_tree_iframe(ex, solution = FALSE, height = tree_height)
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
# pfc_margin_tree() — parse tree as a Tufte marginnote
# ---------------------------------------------------------------------------
# Generates Tufte <label>/<input>/<span class="marginnote"> markup so the
# iframe renders inline in a paragraph context (same pattern as mc_margin_graph).
#
# Usage (inline in a paragraph):
#   `r pfc_margin_tree(pformulas[["wff-1"]])`
#   `r pfc_margin_tree(pformulas[["wff-1"]], height = 400)`
#
# In PDF output falls back to a plain parenthetical link.
# ---------------------------------------------------------------------------
.pfc_margin_counter <- local({ n <- 0L; function() { n <<- n + 1L; n } })

pfc_margin_tree <- function(ex, solution = FALSE, height = 340L, margin_top = NULL) {
  if (!knitr::is_html_output()) {
    return(sprintf("(see [formula](%s))", pfc_url(ex, solution = solution)))
  }
  # Extract hash from the full URL returned by pfc_url (handles both
  # formula_hash field and url field gracefully)
  full_base_url <- pfc_url(ex, solution = solution)
  hash          <- sub("^[^#]*", "", full_base_url)   # everything from # onward
  full_url <- paste0(PFC_BASE, "?card=tree", hash)
  src      <- gsub("&", "&amp;", full_url, fixed = TRUE)
  id       <- paste0("pfc-mn-", .pfc_margin_counter())
  mt_style <- if (!is.null(margin_top)) sprintf("margin-top:%s;", margin_top) else ""
  html <- sprintf(
    '<label for="%s" class="margin-toggle">&#8853;</label>
<input type="checkbox" id="%s" class="margin-toggle"/>
<span class="marginnote" style="%s">
  <iframe title="Parse tree" src="%s"
          style="width:100%%;min-width:0;height:%dpx;border:1px solid #ddd;
                 border-radius:6px;display:block"
          loading="lazy"></iframe>
</span>',
    id, id, mt_style, src, as.integer(height)
  )
  htmltools::HTML(html)
}

# ---------------------------------------------------------------------------
# pfc_load() — read YAML into a named list keyed by id
# ---------------------------------------------------------------------------
pfc_load <- function(file = "exercises/prop-formulas.yml") {
  if (!file.exists(file)) return(list())
  raw <- yaml::read_yaml(file)
  if (is.null(raw) || length(raw) == 0L) return(list())
  # Unwrap top-level 'entries:' key if present
  if (is.list(raw) && !is.null(raw$entries)) raw <- raw$entries
  if (length(raw) == 0L) return(list())
  ids <- vapply(raw, function(e) pfc_str(e$id), character(1L))
  stats::setNames(raw, ids)
}
