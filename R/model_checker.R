# model_checker.R
# Helpers for embedding the Model Checker into a bookdown book.
# Pairs with exercises/models-scaffold.yml (see mc_load()).
#
# The model checker is already self-hosted on GitHub Pages at
# https://gabriel-uzquiano.github.io/model-checker/ and does NOT block framing,
# so mc_iframe() / mc_embed() work against that URL with no extra hosting step.
#
# Setup chunk (e.g. in index.Rmd):
#   source("R/model_checker.R")
#   models <- mc_load("exercises/models.yml")
#
# Inline usage in any chapter:
#   `r mc_link(models[["validity"]], solution = TRUE)`          -> hyperlink
#   `r mc_embed(models[["validity"]], solution = TRUE)`         -> worked embed
#   `r mc_embed(models[["validity"]])`                          -> blank practice embed
#   `r mc_embed(models[["validity"]], height = 380)`            -> compact embed
#   `r mc_embed_toggle(models[["validity"]])`                   -> practice + hidden solution
#   `r mc_embed_labeled(models[["validity"]], solution = TRUE)` -> embed with caption
#   `r mc_embed(models[["inv-5"]], solution = TRUE, mode = "validity")`
#                                                     -> verdict worded as a
#                                                        counterexample to
#                                                        validity rather than
#                                                        as (in)consistency
#
# Suggested heights by context:
#   380  — closed sentences, no variable assignment needed
#   460  — open formulas with variable assignment
#   520  — student practice (blank model to build)
#   560  — full worked model with graph (default)
#
# The model checker encodes its full state (formulas + domain + interpretation
# + variable assignment) as a base64-JSON blob in the URL hash, e.g.
#   #v2:eyJmIjpb...
# The easiest way to capture a hash: configure the model in the browser, press
# "Copy link", and paste the #v2:... portion into worked_hash / practice_hash
# in the YAML file. (Quote it in YAML — a leading # would otherwise start a comment.)

MC_BASE <- "https://gabriel-uzquiano.github.io/model-checker/"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Safely coerce a field to a single string.
mc_str <- function(x) {
  if (is.null(x)) return("")
  x <- as.character(x)
  if (length(x) > 1L) x <- paste(x, collapse = "\n")
  x
}

# ---------------------------------------------------------------------------
# Verdict mode (?mode=) — how the app words its summary line
# ---------------------------------------------------------------------------
#   "consistency" (app default) -> "Consistent / Inconsistent — all formulas..."
#   "validity"                  -> "Counterexample found — all premises are
#                                   true and the conclusion is false..."
#   "equivalence"               -> "...the sentences differ in truth value..."
#
# Validity and equivalence mode need at least two formulas.  In validity mode
# the LAST formula is read as the conclusion and all earlier ones as premises,
# matching the convention used by tt_embed_search() for truth tables.
#
# Set it per entry in the YAML with a `mode:` field, or override at the call
# site with mode = "validity".  An explicit argument wins over the field.
mc_mode <- function(ex, mode = NULL) {
  m <- if (!is.null(mode)) mode else mc_str(ex$mode)
  if (is.null(m) || !nzchar(m)) "" else gsub(" ", "", m)
}

# Assemble MC_BASE + query string + hash.  `params` is a named character
# vector of query parameters; empty ones are dropped.  The query string must
# precede the hash, since the app reads location.search and location.hash
# separately.
.mc_build <- function(hash, params = character(0)) {
  params <- params[nzchar(params)]
  q <- if (length(params)) {
    paste0("?", paste0(names(params), "=", params, collapse = "&"))
  } else ""
  paste0(MC_BASE, q, hash)
}

# Build the URL: append the stored hash to MC_BASE.
#   solution = TRUE  -> worked_hash  (formulas + a worked interpretation)
#   solution = FALSE -> practice_hash (formulas loaded, model blank for the student)
# If the requested hash is empty, the bare checker URL is returned.
mc_url <- function(ex, solution = FALSE, mode = NULL) {
  hash <- if (solution) mc_str(ex$worked_hash) else mc_str(ex$practice_hash)
  .mc_build(hash, c(mode = mc_mode(ex, mode)))
}

# ---------------------------------------------------------------------------
# mc_link() — plain hyperlink (works in both HTML and PDF)
# ---------------------------------------------------------------------------
# Pass label = NULL to use the entry's label field.
mc_link <- function(ex, solution = FALSE, label = NULL, mode = NULL) {
  txt <- if (is.null(label)) mc_str(ex$label) else label
  if (!nzchar(txt)) txt <- mc_str(ex$id)
  sprintf("[%s](%s)", txt, mc_url(ex, solution = solution, mode = mode))
}

# ---------------------------------------------------------------------------
# mc_iframe() — raw <iframe> with an "Open" button in the top-right corner
# ---------------------------------------------------------------------------
mc_iframe <- function(ex, solution = FALSE, height = 560L, mode = NULL) {
  url <- mc_url(ex, solution = solution, mode = mode)
  src <- gsub("&", "&amp;", url, fixed = TRUE)
  sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:8px;right:8px;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Model Checker" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, height
  )
}

# ---------------------------------------------------------------------------
# mc_embed() — format-aware embed: iframe in HTML, link in PDF
# ---------------------------------------------------------------------------
#   `r mc_embed(models[["validity"]], solution = TRUE)`
#   `r mc_embed(models[["validity"]], height = 380)`   # compact
mc_embed <- function(ex, solution = FALSE, height = 560L, mode = NULL) {
  if (knitr::is_html_output()) {
    mc_iframe(ex, solution = solution, height = height, mode = mode)
  } else {
    mc_link(ex, solution = solution, mode = mode)
  }
}

# ---------------------------------------------------------------------------
# mc_embed_labeled() — embed with a small caption line above
# ---------------------------------------------------------------------------
#   `r mc_embed_labeled(models[["validity"]], solution = TRUE)`
#   `r mc_embed_labeled(models[["validity"]], caption = "Try building your own model")`
mc_embed_labeled <- function(ex, solution = FALSE, height = 560L, caption = NULL,
                             mode = NULL) {
  if (!knitr::is_html_output()) return(mc_link(ex, solution = solution, mode = mode))
  cap <- if (!is.null(caption)) caption else mc_str(ex$label)
  iframe <- mc_iframe(ex, solution = solution, height = height, mode = mode)
  if (nzchar(cap)) {
    paste0(
      '<p style="font-size:0.82em;color:#666;margin:0.25em 0 2px 2px">',
      cap, '</p>',
      iframe
    )
  } else {
    iframe
  }
}

# ---------------------------------------------------------------------------
# mc_embed_toggle() — practice embed + hidden solution revealed on click
# ---------------------------------------------------------------------------
# Students work in the top (blank) embed, then click "Show solution" to
# reveal a second iframe pre-loaded with the worked model.
#
#   `r mc_embed_toggle(models[["validity"]])`
#   `r mc_embed_toggle(models[["validity"]], summary = "Reveal countermodel", height = 460)`
mc_embed_toggle <- function(ex, height = 560L,
                             summary = "Show solution", mode = NULL) {
  if (!knitr::is_html_output()) return(mc_link(ex, solution = FALSE, mode = mode))
  practice <- mc_iframe(ex, solution = FALSE, height = height, mode = mode)
  worked   <- mc_iframe(ex, solution = TRUE,  height = height, mode = mode)
  sprintf(
    '%s
<details style="margin-top:0.25em">
  <summary style="cursor:pointer;color:#7a003c;font-size:0.88em;
                  padding:3px 0;user-select:none">%s</summary>
  %s
</details>',
    practice, summary, worked
  )
}

# ---------------------------------------------------------------------------
# mc_load() — read models YAML into a named list keyed by id
# ---------------------------------------------------------------------------
# e.g. models <- mc_load("exercises/models.yml"); models[["validity"]]
mc_load <- function(file = "exercises/models.yml") {
  raw <- yaml::read_yaml(file)
  ids <- vapply(raw, function(e) mc_str(e$id), character(1L))
  stats::setNames(raw, ids)
}

# ---------------------------------------------------------------------------
# mc_iframe_card() — embed a single card from the model checker
# ---------------------------------------------------------------------------
# card: one or more of "formula", "model", "graph" (comma-separated)
#
# Most useful combinations:
#   card = "model"        — just the model inputs (domain, predicates, etc.)
#   card = "graph"        — just the model graph visualisation
#   card = "model,graph"  — model + graph, no formula inputs (most common)
#   card = "formula"      — just the formula entry card
#
# Examples:
#   Show a fixed model with just the graph:
#     `r mc_iframe_card(models[["ex-model-1"]], card = "graph", height = 260L)`
#
#   Show model inputs + graph together:
#     `r mc_iframe_card(models[["ex-model-1"]], card = "model,graph", height = 380L)`
mc_iframe_card <- function(ex, card = "graph", solution = FALSE, height = 300L,
                           mode = NULL) {
  if (!knitr::is_html_output()) return(mc_link(ex, solution = solution, mode = mode))
  hash     <- if (solution) mc_str(ex$worked_hash) else mc_str(ex$practice_hash)
  m        <- mc_mode(ex, mode)
  open_url <- .mc_build(hash, c(mode = m))                               # full app
  full_url <- .mc_build(hash, c(card = gsub(" ", "", card), mode = m))
  src      <- gsub("&", "&amp;", full_url, fixed = TRUE)
  sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:6px;right:6px;font-size:0.7em;
            background:#fff;padding:1px 6px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#666">
    Open &#x2197;</a>
  <iframe title="Model Checker" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:6px;display:block"
          loading="lazy"></iframe>
</div>',
    open_url, src, height
  )
}


# ---------------------------------------------------------------------------
# mc_margin_graph() — graph-only embed as a Tufte marginnote
# ---------------------------------------------------------------------------
# Generates the full Tufte <label>/<input>/<span class="marginnote"> markup
# so that the iframe survives knitr processing (inline spans strip raw HTML;
# this function emits a self-contained raw HTML block instead).
#
# The marginnote is ~50% of body width in Tufte CSS (~600px on a desktop),
# so a standard height of 260px works well for 2–4 node graphs.
#
# Usage (place the inline R call where the note should anchor):
#
#   `r mc_margin_graph(models[["nlt-1"]])`
#
# Must be used in a paragraph context (not inside a fenced div).
# In PDF output it falls back to a plain parenthetical link.
# ---------------------------------------------------------------------------
.mc_margin_counter <- local({ n <- 0L; function() { n <<- n + 1L; n } })

mc_margin_graph <- function(ex, solution = TRUE, height = 560L, zoom = 0.75,
                            mode = NULL) {
  if (!knitr::is_html_output()) {
    link <- mc_link(ex, solution = solution, mode = mode)
    return(sprintf("(see [model](%s))", link))
  }
  hash     <- if (solution) mc_str(ex$worked_hash) else mc_str(ex$practice_hash)
  m        <- mc_mode(ex, mode)
  open_url <- .mc_build(hash, c(mode = m))
  full_url <- .mc_build(hash, c(card = "graph", zoom = as.character(zoom), mode = m))
  src      <- gsub("&", "&amp;", full_url, fixed = TRUE)
  id       <- paste0("mc-mn-", .mc_margin_counter())
  html <- sprintf(
    '<label for="%s" class="margin-toggle">&#8853;</label>
<input type="checkbox" id="%s" class="margin-toggle"/>
<span class="marginnote">
  <iframe title="Model graph" src="%s"
          style="width:100%%;min-width:0;height:%dpx;border:1px solid #ddd;
                 border-radius:6px;display:block"
          loading="lazy"></iframe>
</span>',
    id, id, src, height
  )
  htmltools::HTML(html)
}

# ---------------------------------------------------------------------------
# mc_embed_toggle_cards() — model card + collapsible graph, or graph-only toggle
# ---------------------------------------------------------------------------
# The standard pattern for in-text model examples:
#   top:    card="model,graph"  — student sees the full model + graph
#   bottom: card="graph"        — just the graph, revealed on click
#
# For a standalone model display with collapsible graph:
#   `r mc_embed_toggle_cards(models[["ex-model-1"]])`
#
# Heights:
#   main_height  — for the always-visible embed (default 380)
#   graph_height — for the collapsible graph-only panel (default 260)
mc_embed_toggle_cards <- function(ex,
                                   main_card    = "model,graph",
                                   graph_height = 260L,
                                   main_height  = 380L,
                                   summary      = "Show graph only",
                                   mode         = NULL) {
  if (!knitr::is_html_output()) return(mc_link(ex, mode = mode))
  main  <- mc_iframe_card(ex, card = main_card, height = main_height, mode = mode)
  graph <- mc_iframe_card(ex, card = "graph",   height = graph_height, mode = mode)
  sprintf(
    '%s
<details style="margin-top:0.25em">
  <summary style="cursor:pointer;color:#7a003c;font-size:0.88em;
                  padding:3px 0;user-select:none">%s</summary>
  %s
</details>',
    main, summary, graph
  )
}

# ---------------------------------------------------------------------------
# mc_embed_counter() — blank model on top, worked countermodel revealed on click
# ---------------------------------------------------------------------------
# The standard pattern for countermodel examples:
#   top:    card="model,graph", solution=FALSE  — formulas loaded, model blank
#   bottom: card="model,graph", solution=TRUE   — worked countermodel on click
#
#   `r mc_embed_counter(models[["countermodel"]])`
#   `r mc_embed_counter(models[["countermodel"]], summary = "Show a countermodel", height = 420L)`
# For an invalid argument, set mode = "validity" (or a `mode: "validity"` field
# on the entry) so the verdict reads "Counterexample found — all premises are
# true and the conclusion is false in this model" instead of "Inconsistent".
mc_embed_counter <- function(ex,
                              height  = 420L,
                              summary = "Show a countermodel",
                              mode    = NULL) {
  if (!knitr::is_html_output()) return(mc_link(ex, solution = FALSE, mode = mode))
  practice <- mc_iframe_card(ex, card = "model,graph", solution = FALSE,
                             height = height, mode = mode)
  worked   <- mc_iframe_card(ex, card = "model,graph", solution = TRUE,
                             height = height, mode = mode)
  sprintf(
    '%s
<details style="margin-top:0.25em">
  <summary style="cursor:pointer;color:#7a003c;font-size:0.88em;
                  padding:3px 0;user-select:none">%s</summary>
  %s
</details>',
    practice, summary, worked
  )
}