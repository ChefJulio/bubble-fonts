# BubbleFonts

WoW Forever addon: one chosen font applied everywhere other addons offer font selection.
Spec: [docs/SPEC.md](docs/SPEC.md). Forever client notes: [docs/forever-notes.md](docs/forever-notes.md).

## API ground truth

Model knowledge of the WoW API is out of date and retail-flavored. Forever runs the modern client
(build pinned in `tools/toolchain.json`) with Midnight addon restrictions (secret values, protected calls).

- Before using any API, event, widget method or Blizzard frame, verify it in `.tools/wow-ui-source`
  (Forever branch): `Interface/AddOns/Blizzard_APIDocumentationGenerated/` for API signatures and
  restriction flags, the rest of `Interface/` for how Blizzard itself uses it. Never guess.
- The same goes for bundled libraries (LibStub, LibSharedMedia-3.0, CallbackHandler): read the
  vendored source in `Libs/` before relying on any field or callback, not memory of it.
- `.tools/` is created by `python tools/lint.py`; run it once if missing.

## Lint: mandatory

Run `python tools/lint.py` after every Lua/XML change. It must print `lint: OK`.

- Never silence a finding to get a pass. Fix the call, or for a restricted call that is genuinely
  correct, add `-- apiguard: allow <specific reason>` and tell the user what was acknowledged and why.
- A clean lint does not prove runtime behavior: secret values, taint and combat lockdown only show up
  in-game. Say so when handing changes over for testing.

## Releases

Automatic: pushing a tag `vX.Y.Z` runs `.github/workflows/release.yml` (BigWigs packager), which
uploads the zip to CurseForge and GitHub Releases. `-beta`/`-alpha` in the tag sets the release type.
Needs the `CF_API_KEY` repo secret and `## X-Curse-Project-ID` in the TOC.
Before tagging: replace `CHANGELOG.md` with this release's notes (only this release's), commit, and
check `python tools/package.py --check`. The TOC's version is `@project-version@`, filled from the
tag. `python tools/package.py` builds the same zip locally for testing.
If the addon folder/TOC name changes, update `ADDON` in `tools/package.py` and `package-as` in `.pkgmeta`.

## Conventions

- Lua: 2-space indent; addon state lives on the private namespace (`local ADDON_NAME, ns = ...`).
  New globals only when the client requires them (SavedVariables, `SLASH_*`); add those to
  `diagnostics.globals` in `.luarc.json`.
- Vendored libraries live in `Libs/`, byte-identical to their release (see `.gitattributes`),
  with their licenses alongside. Never edit them; lint skips them.
- Never create, move or show/hide secure frames in combat; queue until `PLAYER_REGEN_ENABLED`.
- Never replace Blizzard functions or scripts (`SetScript` on their frames, overwriting globals):
  that taints. Post-hooks (`HookScript`, `hooksecurefunc`) are allowed where needed; they run after
  Blizzard's code without changing it. Never call Blizzard's update functions from a hook.
  Calling widget methods such as `SetFont` on Blizzard font objects changes state, not code; it is
  allowed but verify in-game that it causes no taint (BugSack) before relying on it.
- Testing is in-game: `/reload`, BugSack/BugGrabber for errors.
