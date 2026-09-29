# Custom feature guide

This documents everything added on top of the kickstart.nvim baseline (see
`README.md`/`CLAUDE.md` for that baseline and `.claude/skills/nvim-config/SKILL.md`
for this repo's own extension conventions, which everything below follows).

**Architecture decision:** this build stays on the existing `vim.pack` /
kickstart architecture (single `init.lua` in numbered sections, plugins under
`lua/custom/plugins/`) rather than migrating to LazyVim/lazy.nvim, to preserve
the config already in place (Claude integration, Oil, colorschemes, LSP
baseline). Nothing already working was rewritten from scratch — new features
were added alongside it.

Nothing in this session was committed to git. Everything below is an
uncommitted working-tree change you can review with `git diff` / `git status`
and commit (or discard) yourself.

## 1. Customization decisions

Recorded from three rounds of questions, in order:

1. **Architecture**: keep vim.pack, extend it (not a LazyVim migration).
2. **Claude Code integration**: upgrade to `coder/claudecode.nvim` (diff
   review, resume/continue, model picker, context-sending) rather than the
   old minimal terminal toggle.
3. **Dashboard**: add a Snacks dashboard with quick actions, initially generic
   (no Cerne branding, tokyonight stays the active theme) — later personalized
   directly by you with a "RIPATO" ASCII banner (`ansi_shadow` figlet font,
   block characters) + a duck beside it (`custom/plugins/snacks.lua`'s
   `HEADER`), which is your own identity, not the reference spec's branding.
   The banner's real bug (and the fix) is documented in §4 below — it looked
   like a font/terminal problem at first (and cost a font install + a
   terminal migration chasing that theory) but wasn't one.
4. **Format-on-save**: enabled for every configured language.
5. **C/C++ style**: Mozilla-derived. Changed twice: first as an *enforced
   fallback* (`-style=file -fallback-style=Mozilla`, project's own
   `.clang-format` wins), then to *always* Mozilla regardless of project
   config (`-style=Mozilla`), then customized to keep the return type on the
   same line as the function name (stock Mozilla breaks it onto its own line)
   — see §4 for the two-field fix this actually needed.
6. **Language/tooling additions**: JSON, YAML, Markdown, ESLint (all four).
7. **Test runner**: Neotest, Python only (`neotest-python`).
8. **Debug adapters**: both Python (`debugpy`) and C/C++ (`codelldb`).
9. **CodeSnap styling**: theme-matching (the plugin's own default look), not
   Cerne-branded; no workspace/file-path metadata in screenshots either way.
10. **Colorscheme picker**: live-previews each theme as you move through the
    list (`enable_preview = true`); the confirmed selection is saved to
    `stdpath('state')/colorscheme` and reloaded automatically on the next
    startup.
11. **Tabline**: added (`mini.tabline`, always shown) — this is a direct
    deviation from the original spec text's "disable ... bufferline", made at
    explicit request; noted here since it contradicts an earlier stated
    requirement.
12. **Indentation guides**: enabled Snacks' own `indent` module
    (`custom/plugins/snacks.lua`) rather than adding a separate plugin like
    indent-blankline.nvim, since Snacks was already a dependency (dashboard +
    claudecode's terminal provider) — avoids installing a second plugin for
    the same feature.
13. **Alacritty font picker**: at explicit request, built a standalone
    `alacritty-font-picker` script (`~/.local/bin/`, outside this repo — it's
    a terminal-level tool, not a Neovim one) that live-previews font
    family+size using Alacritty's `live_config_reload`, mirroring the
    colorscheme picker's "preview live, save the confirmed choice" pattern.
    See its own header comment for how it works; not otherwise documented
    here since it's outside the Neovim config's scope.
14. **`/theme` and `/font`**: typing exactly `/theme<CR>` or `/font<CR>` in
    normal mode (`custom/plugins/slash-commands.lua`) runs the colorscheme
    picker or opens a terminal running `alacritty-font-picker`, instead of a
    literal search — `/` is Neovim's native search trigger, not a command
    prefix, so this hooks `CmdlineLeave` and sets `v:event.abort = true`
    before the search would run (the documented way to cancel a pending
    command-line command). Only an *exact* match is intercepted — `/theme`
    typed as the start of a longer search (e.g. `/themepark`) still searches
    normally, verified directly: fed the literal keystrokes
    `/themepark<CR>` (cursor moved, real search ran) and `/theme<CR>`
    (cursor did NOT move, search was aborted) into a real buffer and checked
    the cursor position after each.

    **Two real bugs found after you actually used `/font`, fixed:**
    - `:terminal` opens in terminal-**normal** mode, not terminal-**insert**
      mode -- without an explicit `startinsert`, your keystrokes (arrows,
      Enter, Esc) were being interpreted as Neovim commands over the terminal
      buffer and never reached `fzf` inside it at all. That's why nothing
      looked live and Esc did nothing -- there was nothing wrong with the
      picker logic itself, the keys just weren't arriving. Fixed by calling
      `vim.cmd.startinsert()` right after opening the terminal, and by adding
      a `TermClose` autocmd that closes the split automatically once the
      script exits, so there's no terminal-mode mechanics to deal with
      afterwards either.
    - `alacritty-font-picker` used `set -e`, which kills the whole script the
      instant `fzf` exits non-zero (which it always does on Esc/Ctrl-C
      cancel) -- so cancelling never reached the restore-on-cancel logic.
      Combined with the first bug, this is exactly what left your real
      `alacritty.toml` stuck on "DejaVu Sans Mono" (fzf's initial highighted
      entry, alphabetically first) after you tried to back out: the `focus`
      event fired once on startup before you could navigate, then cancelling
      never restored it. Found this by grepping your actual config file
      after the fact and fixed your real file back to
      `JetBrainsMono Nerd Font Mono`. Fixed the script by checking `fzf`'s
      exit status explicitly instead of relying on `set -e`, and verified the
      restore branch is actually reached by mocking a non-zero exit in
      isolation (can't drive a real interactive `fzf` session from here).

    Also installed more Nerd Fonts at explicit request (FiraCode, Hack,
    CascadiaCode, Iosevka, alongside the existing JetBrainsMono) -- the
    picker's family list went from 41 to 82 entries.
15. **Alphabetical ordering**: `alacritty-font-picker`'s family list was
    already alphabetical (`sort -u`). The colorscheme picker's underlying
    list (`vim.fn.getcompletion('', 'color')`) was too, but Telescope's own
    `colorscheme` picker unconditionally force-inserts the *currently active*
    theme at position 1, ahead of everything else, breaking that order at the
    top every time. Fixed by passing an explicit, pre-sorted `colors` list to
    the picker (`custom/plugins/colorscheme.lua`) -- Telescope's force-insert
    only fires when the current theme *isn't* already present in the list you
    hand it, so a list that already contains it (in its correct alphabetical
    spot) sidesteps the reorder entirely. Verified by replicating Telescope's
    own internal decision logic with "catppuccin-mocha" active (a theme far
    from alphabetically first, so it would actually trigger the bug) and
    confirming the reorder branch doesn't fire and the resulting list is
    fully alphabetical.

    That fix alone still displayed Z-A, though: both the *data* order (fixed
    above) and the *visual* order are separate concerns, and both pickers'
    default visual layout draws entry #1 at the **bottom** of the list, not
    the top. Telescope defaults to `sorting_strategy = "descending"`
    (confirmed by reading `require('telescope.config').values.sorting_strategy`
    directly); fzf's default `--layout=default` does the same thing
    conceptually. Fixed by adding `sorting_strategy = 'ascending'` to the
    colorscheme picker's opts and `--layout=reverse` to both `fzf` calls in
    `alacritty-font-picker`. Verified the colorscheme fix by monkey-patching
    `telescope.pickers.new` to capture the actual constructed picker object's
    `.sorting_strategy` field (not just the opts table passed in, in case it
    got dropped along the way) and confirming it reads `"ascending"`.

## 2. Feature map (FR → files → status)

| Area | Files | Status |
|---|---|---|
| Core options (scrolloff/colorcolumn/cmdheight, Ctrl-D/U centering) | `init.lua` §1–2 | ✅ verified |
| blink.cmp ghost text, 200ms doc auto-show, preselect-no-insert | `init.lua` §8 | ✅ verified (config matches blink.cmp's actual API, checked against upstream docs) |
| Snippets: friendly-snippets + editable VS Code-style collection | `custom/plugins/snippets.lua`, `custom/snippets/*.json` | ✅ files load; triggers present for class/singleton/factory/observer/strategy/decorator (+ interface/dataclass/abstract/decoratorclass/policyclass/policyhost per language) |
| Treesitter (json/yaml parsers added) | `init.lua` §9 | ✅ verified (parser attaches on file open) |
| Function/class/parameter text objects (`af`/`if`, `ac`/`ic`, `aP`/`iP`) + motions (`]m`/`[m`/`]M`/`[M`) | `custom/plugins/textobjects.lua` | ✅ plugin loads; not manually exercised keystroke-by-keystroke |
| Flash motions + Treesitter structural selection (`gs`/`gS`) | `custom/plugins/flash.lua` | ✅ loads |
| Auto-close JSX/HTML tags | `custom/plugins/autotag.lua` | ✅ loads |
| Telescope: hidden files, smart-case, layout, recent projects | `init.lua` §5, `custom/plugins/project.lua` | ✅ verified |
| Oil as primary explorer (kept, unchanged) | `custom/plugins/oil.lua` | ✅ pre-existing, untouched |
| Project-wide search/replace | `custom/plugins/grug-far.lua` | ✅ loads (blocked without `rg` — fixed, see §4) |
| Harpoon 2, branch-scoped marks, no git subprocess | `custom/plugins/harpoon.lua` | ✅ verified: branch-key function tested directly against this repo, returned `.../nvim::master`; worktree/detached-HEAD paths reviewed but not live-tested |
| Yank ring + history | `custom/plugins/yanky.lua` | ✅ loads |
| LSP: jsonls, yamlls (schemastore-backed), marksman, eslint added; clangd flags; Pyright+Ruff kept non-competing | `init.lua` §6 | ✅ verified: correct single LSP client attaches per filetype (python→pyright+ruff, cpp→clangd, ts→ts_ls, json→jsonls, yaml→yamlls, md→marksman) |
| clangd extensions (switch header, inlay hints, AST) | `custom/plugins/clangd-extensions.lua` | ✅ loads |
| Python venv selector | `custom/plugins/venv-selector.lua` | ✅ loads; not exercised against a real venv |
| Inc-rename (live preview) | `custom/plugins/inc-rename.lua` | ✅ loads |
| Trouble (diagnostics/symbols/lsp/quickfix/loclist) | `custom/plugins/trouble.lua` | ✅ loads |
| Formatting: format-on-save, Ruff organize-imports→format, clang-format (always Mozilla, return type on same line), Prettier for JSON/YAML/CSS/HTML/MD, StyLua for Lua | `init.lua` §7 | ✅ verified end-to-end via `conform.format()` on a real .cpp file — return type stays on the function's line (see §4 for the fix this needed) |
| Colorscheme: live preview while browsing, saved on selection, restored on startup | `custom/plugins/colorscheme.lua` | ✅ verified end-to-end: wrote a saved-theme state file, did a real fresh headless boot, confirmed it loaded that theme; confirmed clean fallback to the default when the state file is absent |
| Tabline (mini.tabline, always shown) | `custom/plugins/tabline.lua` | ✅ verified: module loads, `showtabline=2`, tabline content populated |
| Indentation guides (Snacks `indent` module) | `custom/plugins/snacks.lua` | ✅ verified: opened an indented Python file, confirmed guide extmarks are actually drawn on the indented lines, not just the module loading silently |
| Neotest (Python) | `custom/plugins/neotest.lua` | ✅ loads, adapter registered; no real test suite run |
| DAP: debugpy + codelldb (launch/attach) | `custom/plugins/debug-adapters.lua`, `kickstart/plugins/debug.lua` | ✅ verified: both packages installed, adapters/configs registered; no live debug session run |
| Markdown: render-markdown.nvim + browser preview | `custom/plugins/markdown.lua` | ✅ verified: renders in-editor; browser-preview app dependencies installed (see §4 for a real bug found/fixed here) |
| Gitsigns, LSP rename/hover/etc, which-key, Telescope | pre-existing, untouched | ✅ |
| LazyGit via kdheepak/lazygit.nvim | `custom/plugins/lazygit.lua` | ✅ verified: `lazygit` binary now installed (v0.57.0, via apt), `:LazyGit` command registered, `<leader>gg` ready |
| Sessions (persistence.nvim) | `custom/plugins/persistence.lua` | ✅ loads |
| Snacks dashboard (generic, tokyonight) + Claude terminal provider | `custom/plugins/snacks.lua` | ✅ verified end-to-end: forced `Snacks.dashboard.open()` directly (bypassing its normal auto-trigger's headless-only guard) — renders correctly, header shows, no error. A real bug was caught and fixed here, see §4. |
| CodeSnap (theme-matching, no path metadata) | `custom/plugins/codesnap.lua` | ✅ installs; clipboard tool (`xclip`) present; actual screenshot output **not visually verified** (no way to inspect clipboard image content headlessly) |
| Claude Code (claudecode.nvim, full integration) | `custom/plugins/claude.lua` | ✅ plugin loads, all commands registered, CLI present/authenticated; **live connection/diff behavior not exercised** — that means actually starting a Claude session, which this verification pass deliberately didn't do |
| Custom Telescope keymap explorer | `custom/plugins/keymap-explorer.lua` | ✅ verified: collected 483 live mappings, categorization spot-checked correct (AI/Git/Harpoon/Motions/Text objects all matched); Telescope UI navigation itself not visually tested (headless) |
| tmux pane navigation | *(not added)* | ❌ **not implemented** — tmux itself isn't installed on this machine; Neovim-side `<C-hjkl>` already works for splits. Revisit once tmux is actually installed. |
| JS/TS Neotest adapter | *(not added)* | Deferred by your own choice (Python-only for now) |

## 3. Shortcut reference (deviations from the usual contract, and why)

Everything not listed here matches the kickstart baseline unchanged (`:WhichKey`
or the new `<leader>sK`/`<leader>sA` explorer below shows all of it live).

| Shortcut | Action | Note |
|---|---|---|
| `<leader>H` | Harpoon: add mark | **Not** `<leader>h` — that's already this repo's Git-hunk group |
| `<C-e>` | Harpoon: menu | matches usual contract |
| `<leader>1`–`9` | Harpoon: jump | matches usual contract |
| `gs` / `gS` | Flash jump / Treesitter selection | **Not** bare `s`/`S` — those are mini.surround's `sa`/`sd`/`sr` prefix in this config |
| `sa`/`sd`/`sr`/... | mini.surround add/delete/replace | kept as-is (already established), **not** remapped to `gsa`/`gsd`/`gsr` |
| `af`/`if`, `ac`/`ic` | function/class text objects | |
| `aP`/`iP` | parameter/argument text object | **Not** `aa`/`ia` — mini.ai already owns `aa`/`ii` here (around/inside-next, remapped to dodge Neovim's own Treesitter incremental-selection keys) |
| `]m`/`[m`/`]M`/`[M` | function start/end motions | |
| `<leader>sp` | Recent projects | **Not** `<leader>fp` — `<leader>f` is bare-bound to format in this config |
| `<leader>sK` | Keymap category explorer | **Not** `<leader>fK`, same reason |
| `<leader>sA` | Flat keymap list (all/searchable) | **Not** `<leader>fA`, same reason |
| `<leader>sR` (n/x) | Project search & replace (grug-far) | **Not** `<leader>sr` — that's Telescope resume here |
| `:KeymapExplorer` | Open the category explorer | matches contract |
| `<leader>P` | Yank history | matches contract |
| `<leader>cr` | Rename, live preview (inc-rename) | matches contract |
| `<leader>cv` | Python venv selector | matches contract |
| `<leader>ch` | Switch source/header (clangd) | matches contract |
| `<leader>cm` | Markdown preview (browser) | not in the original contract table; placed in the Code group |
| `<leader>cp` / `<leader>cP` (visual) | CodeSnap / CodeSnap with highlighted lines | matches contract |
| `<leader>uC` | Colorscheme picker | matches contract |
| `/theme<CR>` (exact) | Colorscheme picker | not in the original contract; added at explicit request (see §1 decision 14) |
| `/font<CR>` (exact) | Alacritty font picker (terminal split) | same as above |
| `<leader>a*` | Claude Code (ac/af/ar/aC/am/ab/as/aa/ad) | matches contract exactly |
| `<leader>T*` | Tests (Tn/Tf/Ts/Tx/TS/To/TO) | **Capital** `T` — lowercase `<leader>t*` is already this config's Toggle group (inlay hints/blame/word-diff) |
| `<leader>d*` | Debugging (dc/db/dB/do/di/dO/du/dt) *(not yet added — see below)* | kickstart's own F-key debug bindings (F1/F2/F3/F5/F7, `<leader>b`/`<leader>B`) are used instead; a `<leader>d*` layer was scoped but not written this pass |
| `<leader>x*` | Trouble (xx/xX/xs/xl/xQ/xL) | plugin's own documented convention (no contract entry existed to preserve) |
| `<leader>gg` | LazyGit | matches contract |
| `<leader>Q*` | Sessions (Qs/QS/Ql/Qd) | **Capital** `Q` — bare `<leader>q` already opens the diagnostic quickfix list; adding sub-keys under it would add a `timeoutlen` delay to that existing mapping |

**Not implemented this pass:** the `<leader>d*` Debugging which-key group was
scoped (see table) but never written as a separate file — kickstart's
existing F-key bindings already cover start/continue/step/breakpoint/REPL for
both adapters, so this is a cosmetic gap (discoverability via which-key),
not a functional one.

## 4. Real issues found and fixed during verification

Verification wasn't just "does it install" — three genuine bugs surfaced and
were fixed before calling this done:

1. **`mason-nvim-dap`'s `ensure_installed` uses its own adapter-name keys,
   not raw mason package names.** `debugpy` (the literal package name) was
   silently never installed; the correct key is `python` (which
   `mason-nvim-dap` maps to the `debugpy` package internally). Fixed in
   `kickstart/plugins/debug.lua`.
2. **A `PackChanged` autocmd registered *after* the `vim.pack.add` call it
   was meant to react to.** `custom/plugins/markdown.lua` registered its own
   install hook for `markdown-preview.nvim`'s JS app *after* installing the
   plugin, so it missed the install event entirely. Moved into the existing
   global `PackChanged` handler in `init.lua` §3, which is registered before
   any plugin installs happen (same pattern already used there for
   `telescope-fzf-native`/`LuaSnip`).
3. **`ripgrep` was not actually installed on this machine**, despite an
   initial check appearing to find it (that was a shell-function artifact of
   this session's own tool environment, not a real binary — confirmed via
   `vim.fn.executable('rg')` returning `0`). This silently breaks Telescope
   live-grep, grug-far, and Snacks' grep — a pre-existing gap, not something
   introduced this pass. Fixed by installing a static `rg` binary (and `fd`,
   same way) into `~/.local/bin`, which is already on `PATH`. No `sudo` was
   available in this session to use `apt` instead.
4. **Crash on actually opening Neovim** (caught by you, not by headless
   testing — Snacks explicitly refuses to render its dashboard in headless
   mode, so this specific path was genuinely untestable ahead of time, as
   flagged in the original report): Snacks' default dashboard `sections`
   include a `startup` section that unconditionally does
   `require('lazy.stats')` with **no guard** — that module only exists under
   lazy.nvim, so it always errors on a `vim.pack` setup like this one,
   regardless of any other plugin. The error message you saw pointed at
   `codesnap.nvim`'s compiled generator library because of a **separate,
   real upstream bug** in `codesnap.nvim` v2: it appends its generator's
   *exact* file path (no `?` wildcard) to `package.cpath`
   (`lua/codesnap/module.lua:49`), so once codesnap loads, any *other*
   `require()` of a genuinely-missing module can mis-resolve through that
   same file and produce a confusing "undefined symbol" error instead of a
   clean "module not found" one. CodeSnap's own feature still works fine —
   this only pollutes *other* modules' failed requires. Fixed the actual
   trigger by dropping the `startup` section entirely (`custom/plugins/snacks.lua`)
   since it's meaningless without lazy.nvim anyway; re-verified by forcing
   `Snacks.dashboard.open()` directly (see the dashboard row above). The
   `codesnap.nvim` cpath issue itself is third-party and wasn't patched —
   if you ever see another "undefined symbol ... linux-x86_64_generator.so"
   error from an unrelated `require()`, that's this same upstream quirk
   surfacing elsewhere; worth reporting to `mistricky/codesnap.nvim` upstream,
   or disabling CodeSnap if it recurs and bothers you.
5. **The RIPATO/duck dashboard header rendered "crooked"** — this was
   mis-diagnosed at first as a font/terminal problem (Unicode box-drawing
   characters' "ambiguous" East Asian Width property), which led to
   installing JetBrainsMono Nerd Font and, separately, migrating to
   Alacritty — both reasonable troubleshooting steps, but neither was the
   actual cause, since the same crooked look persisted on Alacritty with a
   proper Nerd Font too. The **real** bug: the header's own text lines had
   different total lengths (the RIPATO banner block and the duck art weren't
   padded to a common width), and Snacks' dashboard centers each header line
   **individually** based on its own width — unequal line lengths produce a
   staircase-like left-margin offset no matter what renders the glyphs.
   Fixed by computing the padding **at runtime** in `custom/plugins/snacks.lua`
   (`pad_right`, using `vim.fn.strdisplaywidth` for correct multi-byte-aware
   width) instead of storing literal trailing spaces in the file — stylua
   strips trailing whitespace at end-of-line even inside a `[[...]]` long
   string (confirmed directly; `-- stylua: ignore` does **not** protect
   against it), so literal padding would have silently broken again on the
   next format. Re-verified by forcing `Snacks.dashboard.open()` and checking
   every line has identical leading-space count (11) — no staircase.
   The font install and Alacritty migration weren't wasted, though — you now
   have a Nerd Font and a lighter/faster terminal either way.
6. **Mozilla + "return type on same line" silently didn't apply.** The first
   attempt (`-style={BasedOnStyle: Mozilla, AlwaysBreakAfterReturnType: None}`)
   used a clang-format option name (`AlwaysBreakAfterReturnType`) that no
   longer exists in clang-format 23 (confirmed via
   `clang-format --dump-config`, which silently ignores unknown-but-plausible
   key names rather than erroring). The *current* option is
   `BreakAfterReturnType` — but setting only that one still didn't work,
   because Mozilla sets a **second**, independently-effective legacy option,
   `AlwaysBreakAfterDefinitionReturnType`, specifically for top-level
   *definitions* (as opposed to declarations). Both have to be set to `None`
   together. Verified directly with `clang-format --dump-config -style=Mozilla`
   to see the real current field names before guessing again, then confirmed
   the actual fix by formatting a real `.cpp` file three ways: raw
   `clang-format` on the command line, a function *declaration* inside a
   class, and a top-level function *definition* — all three keep the return
   type on the same line now. Also confirmed end-to-end through `conform`
   inside Neovim, not just the standalone `clang-format` binary.

## 5. Known gaps / explicitly unverified

- **tmux integration**: not implemented — tmux itself isn't installed here.
- **`tree-sitter-cli`**: flagged by `:checkhealth` as missing, but every
  language tested (Python/C++/TS/JSON/YAML/Markdown/Lua) got its parser and
  highlighted correctly without it in this session — optional in practice
  for this config's usage pattern, not force-installed.
- **Startup time**: measured (see below), not assumed.
- **Dashboard visuals, CodeSnap image output, live Claude session, a real
  DAP breakpoint session, an actual Neotest run, Harpoon under a real git
  worktree/detached HEAD**: all configured and reviewed, but need your own
  interactive session to see/confirm — headless verification can prove wiring
  is correct but can't drive a real UI, clipboard image, or external process
  the way you would.
- **`nvim-pack-lock.json`** is still gitignored (upstream kickstart's
  default). If you want reviewable, reproducible plugin-version diffs across
  machines (NFR-06), consider un-ignoring and committing it — that's a repo
  policy choice, left to you rather than changed unilaterally.

## 6. Startup time

Measured with `nvim --headless --startuptime`, 3 runs each, after all
plugins/tools were already installed (steady state, not counting first-run
downloads):

- **Before this session** (`nvim.bak.20260928-091637`, isolated profile): ~16–23ms
- **After this session**: ~102–108ms

The increase is expected: `vim.pack` has no lazy-loading mechanism (unlike
lazy.nvim), so all ~20 new plugins load eagerly at startup rather than on
first use. ~105ms is still fast in absolute terms for an editor with this
much functionality, but if you want it tighter later, the plugins used least
often (Neotest, DAP, CodeSnap, grug-far, markdown-preview, project.nvim) are
the best candidates for manual `FileType`/command-based lazy `require()`
wrapping — no such lazy-load pattern existed in this codebase before, so none
was invented without asking first.

## 7. Rollback

Nothing was committed. Two ways back to the exact prior state, pick whichever
fits:

```sh
# Option A: git (this repo has clean history — every change here is uncommitted)
cd ~/.config/nvim
git checkout -- init.lua lua/kickstart/plugins/debug.lua lua/custom/plugins/colorscheme.lua
git clean -fd lua/custom/plugins/ lua/custom/snippets/ CUSTOM.md  # removes all newly-added files
# (review with `git status`/`git clean -n` first if you want to double-check what would be removed)

# Option B: full filesystem backup taken before any change this session
rm -rf ~/.config/nvim
mv ~/.config/nvim.bak.20260928-091637 ~/.config/nvim
```

Newly-installed Mason tools (`debugpy`, `codelldb`, `json-lsp`,
`yaml-language-server`, `marksman`, `eslint-lsp`) and vim.pack plugins live
under `~/.local/share/nvim/` and `~/.local/state/nvim/`, independent of the
config directory — `:Mason` lets you remove tools individually, or delete
`~/.local/share/nvim/site/pack` to reset all plugins (next boot reinstalls
whatever the config in place at the time asks for).

`~/.local/bin/rg` and `~/.local/bin/fd` (added this session, see §4) are
standalone binaries, not tied to this config — remove them the same way if
you'd rather install ripgrep/fd via your package manager once you have
`sudo` access in an interactive shell.

## 8. Maintenance

Follow `.claude/skills/nvim-config/SKILL.md` for this repo's own conventions
(new plugin → `lua/custom/plugins/<name>.lua`, required explicitly from
`init.lua` §10; new language → LSP server in §6's `servers` table, formatter
in §7, treesitter parser in §9). Update plugins with `:lua vim.pack.update()`
(review, then `:write` to apply); `:Mason` manages LSP/formatter/DAP tool
versions independently.
