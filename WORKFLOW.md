# Logic Textbook — Editing & Publishing Workflow

Author's reference for `github.com/gabriel-uzquiano/logic`.
Last updated: 2026-08-15.

---

## 1. Where things live

### On disk (Mac)

| Location | What it is |
|---|---|
| `~/GitHub/logic/` | The git working copy. All editing happens here. |
| `~/GitHub/logic/index.Rmd` | Book preamble + R setup (sources helpers, loads YAMLs). |
| `~/GitHub/logic/01-reason.Rmd` … `12-sol.Rmd` | One `.Rmd` per chapter. |
| `~/GitHub/logic/R/` | R helpers: `proof_checker.R`, `model_checker.R`, `prop_formula_checker.R`, etc. Provide `pc_iframe_card()`, `pc_embed_toggle_cards()`, `mc_embed_counter()`, `qtr_iframe_card()`, and friends. |
| `~/GitHub/logic/exercises/proofs-scaffold.yml` | Every proof widget entry keyed by `id`. Each entry has `role: worked` or `role: practice`, plus `label`, `premises`, `conclusion`, and (for worked) `proof:`. |
| `~/GitHub/logic/exercises/models-scaffold.yml` | Countermodel widget entries for the model checker. |
| `~/GitHub/logic/exercises/ql-formulas.yml`, `ql-translations.yml`, `exercises.yml` | Other exercise catalogs (formula-checker, QL translation, general proof-checker). |
| `~/GitHub/logic/_bookdown.yml` | Lists Rmd files in build order + output dir (`docs/`). |
| `~/GitHub/logic/_output.yml` | Bookdown output format config (`bookdown::tufte_html_book`, custom CSS, split_by chapter). |
| `~/GitHub/logic/lua/practice.lua` | Pandoc filter for practice-block markup. |
| `~/GitHub/logic/custom.css`, `toc.css` | Styling. |
| `~/GitHub/logic/docs/` | **Built output.** GitHub Pages serves this. Regenerated on every render. |
| `~/GitHub/logic/publish.sh` | The publish script (details in §3). |
| `~/GitHub/logic/.gitignore` | Excludes R session artifacts, LaTeX byproducts, `.archive/`. |
| `~/Documents/…/logic-published-pre-ch11-20260815.zip` | Snapshot of the pre-Ch11 published site. Kept for reference. |

### On GitHub (`gabriel-uzquiano/logic`)

Two-branch layout:

| Branch | Contents | Purpose |
|---|---|---|
| `source` | All Rmd + R + exercises + config + built `docs/`. | Where authoring history lives. This is your normal working branch. |
| `main` | Only `docs/` (plus `.nojekyll`, `README.md`, `LICENSE`, `Gemfile`). | What GitHub Pages serves. Kept minimal by design. |

The published site is at [gabriel-uzquiano.github.io/logic/](https://gabriel-uzquiano.github.io/logic/), fed by `main`.

### External tools (deployed separately)

| Site | Repo | Consumed via |
|---|---|---|
| [gabriel-uzquiano.github.io/proof-checker/](https://gabriel-uzquiano.github.io/proof-checker/) | `gabriel-uzquiano/proof-checker` | `pc_iframe_card`, `pc_embed_toggle_cards` |
| [gabriel-uzquiano.github.io/model-checker/](https://gabriel-uzquiano.github.io/model-checker/) | `gabriel-uzquiano/model-checker` | `mc_embed_counter` |
| Translation checker (deployed via Pages) | `gabriel-uzquiano/…` | `qtr_iframe_card`, `qtr_embed_toggle_cards` |

Each is a standalone static site loaded into the book via `<iframe>`. The book only stores the URL and a base64-encoded state hash; the checkers themselves live in their own repos.

---

## 2. Regular editing loop

### 2a. Prose or math edits inside a chapter

1. Open the relevant `NN-name.Rmd` in RStudio.
2. Edit. Save.
3. **Build → Build Book** (or `Ctrl/Cmd + Shift + B`). RStudio invokes `bookdown::render_book("index.Rmd", "bookdown::tufte_html_book")` and refreshes `docs/`.
4. RStudio's Viewer opens `docs/index.html`. Click through to the changed chapter and inspect.
5. Iterate.

You do **not** commit or push until you're happy with the changes.

### 2b. Adding a new proof exercise

1. Open `exercises/proofs-scaffold.yml`.
2. Copy an existing worked entry as a template. Fields:
   - `id`: a stable slug (`ch11-ex4a`), unique across the file.
   - `role`: `worked` (has a `proof:`) or `practice` (no proof; student fills in).
   - `label`: shown in the widget header. Include the sequent.
   - `premises`: comma-separated, ASCII-friendly (`∀x(Px→Qx), Pa`).
   - `conclusion`: single formula.
   - `proof:` (worked only): a single-line block scalar with `\n` between proof lines. Two spaces separate the formula from the rule and citation. Indentation with two spaces indicates subproofs.
3. In the Rmd, add the widget call inside the exercise:
   ```r
   `r pc_embed_toggle_cards(proofs[["ch11-ex4a"]], proofs[["ch11-ex4a-worked"]], worked_height = 360L)`
   ```
4. Verify the worked proof text validates in the deployed proof-checker before publishing (paste it into [gabriel-uzquiano.github.io/proof-checker/](https://gabriel-uzquiano.github.io/proof-checker/) or run the repo's test suite).

### 2c. Adding a new countermodel exercise

Same idea in `exercises/models-scaffold.yml`. Widget call:
```r
`r mc_embed_counter(models[["ch11-ex4a-counter"]], height = 420L, summary = "Show a countermodel")`
```
Verify in [gabriel-uzquiano.github.io/model-checker/](https://gabriel-uzquiano.github.io/model-checker/) before publishing. Notes:
- The model-checker parser requires **ASCII `=`** for identity and **explicit parens** around `∃x(...)` scope.
- The book's YAML uses these exact conventions; do not paraphrase.

### 2d. Chapter formatting tips

- Numbered lists inside `## Exercises {-}`: use `#.  ` (with **two spaces** after the period) uniformly across siblings. Mixing one-space and two-space markers breaks Pandoc's paragraph-loose list rendering and drops widget "Open ↗" links.
- Widget calls inside a list item must be indented **8 spaces** from the outer numbered marker and be preceded and followed by a blank line.
- HTML comments (`<!-- … -->`) are safe between list items.

---

## 3. Publishing

Once the local render looks good and you're ready to push it live:

```bash
cd ~/GitHub/logic
./publish.sh "Short commit message describing the changes"
```

### What `publish.sh` does, in order

1. Confirms you're on branch `source`.
2. Confirms `docs/` exists and looks rendered (has `index.html`).
3. `git add -A && git commit` on `source` with your message.
4. `git push origin source`.
5. `git fetch origin main` — pulls whatever is currently deployed.
6. `git branch -f main origin/main` — resets local `main` to match origin exactly. This prevents divergence errors on the push in step 9.
7. Creates a temporary worktree in `/tmp/logic-publish-XXXXXX` checked out on `main`.
8. `rm -rf` the old `docs/` in the worktree, `cp -R` the newly rendered `docs/` over.
9. `git add -A && git commit && git push origin main` inside the worktree.
10. Removes the worktree.
11. Leaves you on `source` with a clean working tree.

The `trap` on `EXIT` cleans up the worktree even if something errors midway.

GitHub Pages picks up the new `main` within about a minute. Reload the site with a cache-buster (`?v=1`) if you don't see the update immediately.

### Rules of thumb

- **Always render before publishing.** The script trusts `docs/`.
- **`publish.sh` is idempotent.** Safe to re-run if you get transient network errors.
- **Never edit `docs/` by hand.** It's the render output; changes will vanish on the next build.
- **Don't check out `main` locally to fix things.** The script handles it. If you ever need to inspect what's live, `git show origin/main:docs/index.html | head` or just visit the live site.

---

## 4. Recovering from common issues

### "Updates were rejected (fetch first)"

Someone else — or a past you — pushed to origin. Fix:

```bash
git fetch origin
git pull --rebase origin source           # if the reject was on source
# OR
git branch -f main origin/main            # if the reject was on main
```

Then re-run `./publish.sh`.

### Rebase conflicts

`git status` shows both-modified files. Open them, look for `<<<<<<<` markers, decide which side to keep (delete the markers plus the losing side), then:

```bash
git add <resolved-files>
git rebase --continue
```

If git opens vim for a commit message: `Esc`, then `:wq`, then `Enter`.
If you want out: `git rebase --abort` returns you to the pre-rebase state.

### Stray worktree lying around

If `publish.sh` errors after creating the worktree, its `trap` should clean up. If it doesn't:

```bash
git worktree list                          # see what's stuck
git worktree remove --force /tmp/logic-publish-XXXXXX
git worktree prune
```

### `docs/` looks stale on the live site

Verify:

```bash
git log --oneline origin/main -3           # is your latest publish there?
```

Then check the GitHub Pages status: `github.com/gabriel-uzquiano/logic/deployments`. If the deploy failed, the Pages workflow tab shows why.

### RStudio Terminal shows "(busy)" and nothing else

You're in a text editor (usually vim) waiting for input. `Esc` then `:wq` then `Enter` will save-and-quit.

To skip vim in the future:

```bash
git config --global core.editor "nano"
# or, if you have VS Code installed:
git config --global core.editor "code --wait"
```

---

## 5. Archives

- Pre-Ch11 site snapshot: `~/Documents/…/logic-published-pre-ch11-20260815.zip`
  A zip of `docs/` as it existed on `origin/main` immediately before the Ch11 publish. Contains 100 HTML/CSS/JS/image files (~1.5 MB). Open `docs/index.html` inside the zip to browse locally.

For future publishes where you want to keep a snapshot, run before publishing:

```bash
cd ~/GitHub/logic
STAMP=$(date +%Y%m%d)
git archive --format=zip -o "$HOME/Documents/logic-published-$STAMP.zip" origin/main -- docs/
```

That captures the currently deployed version before you overwrite it.

---

## 6. Quick command cheatsheet

```bash
# See what you've changed
git status
git diff                                    # tracked changes, all files
git diff -- 11-identity.Rmd                # one file only

# Discard changes to a file (careful — no undo)
git checkout -- 11-identity.Rmd

# See history
git log --oneline -20
git log --oneline -- 11-identity.Rmd       # commits that touched this file
git show <commit-hash>                     # what a specific commit changed

# Publish
./publish.sh "commit message"

# Snapshot the currently-published site first
git archive --format=zip -o "$HOME/Documents/logic-$(date +%Y%m%d).zip" origin/main -- docs/

# Emergency: undo the last local commit (does NOT touch pushed history)
git reset --soft HEAD~1                    # keep changes staged
git reset --mixed HEAD~1                   # keep changes but unstaged
git reset --hard HEAD~1                    # DROP the changes entirely
```

---

## 7. RStudio git integration

- **Git pane** (top-right by default): shows modified files, lets you view diffs by clicking `Diff`, and lets you stage/commit through the UI.
- **History (clock icon in Git pane)**: browse past commits with per-commit diffs.
- **Branch dropdown**: quickly see which branch you're on. Always `source` for editing.
- **Terminal tab** (bottom-left, next to Console): run `./publish.sh`, `git rebase`, and any git commands the GUI doesn't cover.

The UI is fine for staging + committing, but **publishing must happen via `./publish.sh`** because the two-branch dance isn't something RStudio's Git pane knows how to do.

---

## 8. Sanity checks before each publish

Fast pre-flight in the Terminal:

```bash
git status                                  # anything unexpectedly modified?
ls docs/index.html                          # render output actually exists?
git log --oneline -3                        # what did I just commit?
```

If anything looks off, don't publish. Fix locally first.

---

*This file lives at `~/GitHub/logic/WORKFLOW.md`. Feel free to edit or annotate. Commit it to source alongside the book.*
