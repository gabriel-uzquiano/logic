# ql_formula_checker.R
# Helpers for embedding the QL Formula Checker into a bookdown book.
# Pairs with exercises/ql-formulas.yml (see qfc_load()).
#
# Setup chunk (index.Rmd):
#   source("R/ql_formula_checker.R")
#   qformulas <- qfc_load("exercises/ql-formulas.yml")
#
# Inline usage:
#   `r qfc_link(qformulas[["ql-1"]])`
#   `r qfc_embed(qformulas[["ql-1"]])`
#
# URL hash format: #v1:<base64(JSON)>
#   JSON shape: { f: "<formula>" }
#
# The QL checker takes a single formula field; there is no assignment panel
# (truth evaluation happens via the model checker instead).
#
# The easiest way to capture a hash: type the formula in the browser, press
# "Copy link", and paste the #v1:... fragment into the YAML as formula_hash.
#
# YAML entry shape:
#   - id: "ql-1"
#     label: "QL formula 1"
#     formula_hash: "#v1:eyJmIjoiQXgoU..."   # formula pre-loaded

QFC_BASE <- "https://gabriel-uzquiano.github.io/ql-formula-checker/"


# Return x unchanged — HTML rendering requires a results='asis' chunk
# or a fenced div block (:::{.example}), matching the proof checker pattern.
.as_html <- function(x) x

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

qfc_str <- function(x) {
  if (is.null(x)) return("")
  x <- as.character(x)
  if (length(x) > 1L) x <- paste(x, collapse = "\n")
  x
}

qfc_url <- function(ex) {
  paste0(QFC_BASE, qfc_str(ex$formula_hash))
}

# ---------------------------------------------------------------------------
# qfc_link() — plain hyperlink (HTML and PDF)
# ---------------------------------------------------------------------------
qfc_link <- function(ex, label = NULL) {
  txt <- if (is.null(label)) qfc_str(ex$label) else label
  if (!nzchar(txt)) txt <- qfc_str(ex$id)
  sprintf("[%s](%s)", txt, qfc_url(ex))
}

# ---------------------------------------------------------------------------
# qfc_iframe() — raw <iframe> with Open button
# ---------------------------------------------------------------------------
qfc_iframe <- function(ex, height = 360L) {
  url <- qfc_url(ex)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="QL Formula Checker" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, as.integer(height)
  )
}

# ---------------------------------------------------------------------------
# qfc_embed() — format-aware embed
# ---------------------------------------------------------------------------
# height guide:
#   300 — compact: formula input + parse tree only
#   360 — standard (default)
#   420 — extra room for deeply nested formulas
qfc_embed <- function(ex, height = 360L) {
  if (knitr::is_html_output()) {
    .as_html(qfc_iframe(ex, height = height))
  } else {
    qfc_link(ex)
  }
}

# ---------------------------------------------------------------------------
# qfc_embed_labeled() — embed with a caption above
# ---------------------------------------------------------------------------
qfc_embed_labeled <- function(ex, height = 360L, caption = NULL) {
  if (!knitr::is_html_output()) return(qfc_link(ex))
  cap    <- if (!is.null(caption)) caption else qfc_str(ex$label)
  iframe <- qfc_iframe(ex, height = height)
  if (nzchar(cap)) {
    .as_html(paste0('<p style="font-size:0.82em;color:#666;margin:0.25em 0 2px 2px">',
           cap, '</p>', iframe))
  } else {
    .as_html(iframe)
  }
}

# ---------------------------------------------------------------------------
# qfc_margin_tree() — parse tree as a Tufte marginnote
# ---------------------------------------------------------------------------
# Usage (inline in a paragraph):
#   `r qfc_margin_tree(qformulas[["wff-1"]])`
#
# In PDF output falls back to a plain parenthetical link.
# ---------------------------------------------------------------------------
.qfc_margin_counter <- local({ n <- 0L; function() { n <<- n + 1L; n } })

qfc_margin_tree <- function(ex, height = 340L) {
  if (!knitr::is_html_output()) {
    return(sprintf("(see [formula](%s))", qfc_url(ex)))
  }
  full_base_url <- qfc_url(ex)
  hash          <- sub("^[^#]*", "", full_base_url)
  full_url <- paste0(QFC_BASE, "?card=tree", hash)
  src      <- gsub("&", "&amp;", full_url, fixed = TRUE)
  id       <- paste0("qfc-mn-", .qfc_margin_counter())
  html <- sprintf(
    '<label for="%s" class="margin-toggle">&#8853;</label>
<input type="checkbox" id="%s" class="margin-toggle"/>
<span class="marginnote">
  <iframe title="Parse tree" src="%s"
          style="width:100%%;min-width:0;height:%dpx;border:1px solid #ddd;
                 border-radius:6px;display:block"
          loading="lazy"></iframe>
</div>',
    id, id, src, as.integer(height)
  )
  htmltools::HTML(html)
}

# ---------------------------------------------------------------------------
# qfc_load() — read YAML into a named list keyed by id
# ---------------------------------------------------------------------------
qfc_load <- function(file = "exercises/ql-formulas.yml") {
  if (!file.exists(file)) return(list())
  raw <- yaml::read_yaml(file)
  if (is.null(raw) || length(raw) == 0L) return(list())
  # Unwrap top-level 'entries:' key if present
  if (is.list(raw) && !is.null(raw$entries)) raw <- raw$entries
  if (length(raw) == 0L) return(list())
  ids <- vapply(raw, function(e) qfc_str(e$id), character(1L))
  stats::setNames(raw, ids)
}
