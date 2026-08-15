# proof_checker.R
# Helpers for embedding the Propositional Proof Checker into a bookdown book.
# Pairs with exercises/proofs-scaffold.yml (see pc_load()).
#
# Setup chunk (e.g. in index.Rmd):
#   source("R/proof_checker.R")
#   proofs <- pc_load("exercises/proofs-scaffold.yml")
#
# Inline usage in any chapter:
#   `r pc_link(proofs[["andI-worked"]], solution = TRUE)`            -> hyperlink to worked proof
#   `r pc_link(proofs[["andI-worked"]])`                             -> hyperlink (blank)
#   `r pc_embed(proofs[["mp-worked"]], solution = TRUE)`             -> worked embed
#   `r pc_embed(proofs[["andI-practice"]])`                          -> blank practice embed
#   `r pc_embed_toggle(proofs[["andI-worked"]])`                     -> practice + collapsible solution
#   `r pc_embed_toggle_pair(proofs[["andI-practice"]], proofs[["andI-worked"]])` -> same, separate entries
#   `r pc_embed_labeled(proofs[["mp-worked"]], solution = TRUE)`     -> embed with caption

PC_BASE <- "https://gabriel-uzquiano.github.io/proof-checker/"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

pc_str <- function(x) {
  if (is.null(x)) return("")
  x <- as.character(x)
  if (length(x) > 1L) x <- paste(x, collapse = "\n")
  x
}

pc_q <- function(x) {
  x <- enc2utf8(pc_str(x))
  if (requireNamespace("curl", quietly = TRUE)) {
    curl::curl_escape(x)
  } else {
    URLencode(x, reserved = TRUE)
  }
}

# Build the URL hash fragment.
#   solution = TRUE  -> include the worked proof lines
#   solution = FALSE -> premises + conclusion only
pc_hash <- function(ex, solution = FALSE) {
  parts <- c(
    p = pc_q(ex$premises),
    c = pc_q(ex$conclusion)
  )
  pr <- pc_str(ex$proof)
  if (solution && nzchar(pr)) {
    parts <- c(parts, pr = pc_q(pr))
  }
  paste0("#", paste(names(parts), parts, sep = "=", collapse = "&"))
}

pc_url <- function(ex, solution = FALSE) {
  paste0(PC_BASE, pc_hash(ex, solution = solution))
}

# ---------------------------------------------------------------------------
# pc_link() — plain hyperlink (works in both HTML and PDF)
# ---------------------------------------------------------------------------
pc_link <- function(ex, solution = FALSE, label = NULL) {
  txt <- if (is.null(label)) pc_str(ex$label) else label
  if (!nzchar(txt)) txt <- pc_str(ex$id)
  sprintf("[%s](%s)", txt, pc_url(ex, solution = solution))
}

# ---------------------------------------------------------------------------
# pc_iframe() — raw <iframe> with an "Open ↗" button
# ---------------------------------------------------------------------------
# GitHub Pages does NOT set X-Frame-Options, so iframes work fine here.
pc_iframe <- function(ex, solution = FALSE, height = 480L) {
  src <- gsub("&", "&amp;", pc_url(ex, solution = solution), fixed = TRUE)
  url <- pc_url(ex, solution = solution)
  .as_html(sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:0;right:0;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Propositional Proof Checker" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:8px;display:block"
          loading="lazy" allow="fullscreen"></iframe>
</div>',
    url, src, height
  ))
}

# ---------------------------------------------------------------------------
# pc_embed() — format-aware: iframe in HTML, link in PDF
# ---------------------------------------------------------------------------
pc_embed <- function(ex, solution = FALSE, height = 480L) {
  if (knitr::is_html_output()) {
    pc_iframe(ex, solution = solution, height = height)
  } else {
    pc_link(ex, solution = solution)
  }
}

# ---------------------------------------------------------------------------
# pc_embed_labeled() — embed with a small caption above
# ---------------------------------------------------------------------------
pc_embed_labeled <- function(ex, solution = FALSE, height = 480L, caption = NULL) {
  if (!knitr::is_html_output()) return(pc_link(ex, solution = solution))
  cap <- if (!is.null(caption)) caption else pc_str(ex$label)
  iframe <- pc_iframe(ex, solution = solution, height = height)
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
# pc_embed_toggle() — blank practice + collapsible worked solution
# ---------------------------------------------------------------------------
# Pass the WORKED entry; solution=FALSE gives the blank, solution=TRUE the proof.
#   `r pc_embed_toggle(proofs[["andI-worked"]])`
pc_embed_toggle <- function(ex, height = 480L, summary = "Show solution") {
  if (!knitr::is_html_output()) return(pc_link(ex, solution = FALSE))
  practice <- pc_iframe(ex, solution = FALSE, height = height)
  worked   <- pc_iframe(ex, solution = TRUE,  height = height)
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
# pc_embed_toggle_pair() — separate practice and worked entries
# ---------------------------------------------------------------------------
#   `r pc_embed_toggle_pair(proofs[["andI-practice"]], proofs[["andI-worked"]])`
pc_embed_toggle_pair <- function(practice_ex, worked_ex, height = 480L,
                                  summary = "Show solution") {
  if (!knitr::is_html_output()) return(pc_link(practice_ex, solution = FALSE))
  practice <- pc_iframe(practice_ex, solution = FALSE, height = height)
  worked   <- pc_iframe(worked_ex,   solution = TRUE,  height = height)
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
# pc_load() — read proofs YAML into a named list keyed by id
# ---------------------------------------------------------------------------
pc_load <- function(file = "exercises/proofs-scaffold.yml") {
  raw <- yaml::read_yaml(file)
  ids <- vapply(raw, function(e) pc_str(e$id), character(1L))
  stats::setNames(raw, ids)
}

# ---------------------------------------------------------------------------
# pc_iframe_card() — embed a single card from the proof checker
# ---------------------------------------------------------------------------
# card: "sequent", "proof", "verify", or comma-separated e.g. "sequent,proof"
#
# Examples:
#   Fitch display of a worked proof (compact, no editing):
#     `r pc_iframe_card(proofs[["andI-worked"]], card = "verify", solution = TRUE)`
#
#   Read-only sequent (premises + conclusion display):
#     `r pc_iframe_card(proofs[["mp-worked"]], card = "sequent")`
#
#   Student practice — sequent + proof textarea only:
#     `r pc_iframe_card(proofs[["andI-practice"]], card = "sequent,proof", height = 320L)`
pc_iframe_card <- function(ex, card = "verify", solution = FALSE, height = 300L) {
  if (!knitr::is_html_output()) return(pc_link(ex, solution = solution))
  hash     <- pc_hash(ex, solution = solution)
  open_url <- paste0(PC_BASE, hash)                                      # full app
  full_url <- paste0(PC_BASE, "?card=", URLencode(card, reserved = FALSE), hash)
  src      <- gsub("&", "&amp;", full_url, fixed = TRUE)
  .as_html(sprintf(
    '<div style="position:relative;margin:1em 0">
  <a href="%s" target="_blank"
     style="position:absolute;top:0;right:0;font-size:0.72em;
            background:#fff;padding:2px 7px;border:1px solid #ccc;
            border-radius:4px;z-index:10;text-decoration:none;color:#444">
    Open &#x2197;</a>
  <iframe title="Proof Checker" src="%s"
          style="width:100%%;height:%dpx;border:1px solid #ddd;border-radius:6px;display:block"
          loading="lazy"></iframe>
</div>',
    open_url, src, height
  ))
}

# ---------------------------------------------------------------------------
# pc_embed_toggle_cards() — practice (proof+verify) + collapsible verify-only
# ---------------------------------------------------------------------------
# The standard pattern for in-text examples:
#   top:    card="proof,verify"  — student types, sees live Fitch feedback
#   bottom: card="verify"        — only the finished Fitch display, on click
#
# For separate practice/worked entries (the usual case):
#   `r pc_embed_toggle_cards(proofs[["andI-practice"]], proofs[["andI-worked"]])`
#
# For a single worked entry where solution=T/F gives blank vs filled:
#   `r pc_embed_toggle_cards(proofs[["rep-worked"]])`
#
# Heights:
#   practice_height — for proof+verify card (default 420: textarea + output)
#   worked_height   — for verify-only card (default 220: just Fitch rows)
pc_embed_toggle_cards <- function(practice_ex, worked_ex = practice_ex,
                                   practice_height = 420L,
                                   worked_height   = 220L,
                                   summary         = "Show solution") {
  if (!knitr::is_html_output()) return(pc_link(practice_ex, solution = FALSE))
  practice <- pc_iframe_card(practice_ex, card = "sequent,proof",
                              solution = FALSE, height = practice_height)
  worked   <- pc_iframe_card(worked_ex,   card = "proof,verify",
                              solution = TRUE,  height = worked_height)
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