# BubbleFonts: specification

Status: **approved and implemented** (2026-11-15), pending the in-game checks in section 8.
Decisions are in section 10.

Evidence tags: **[Read]** cited line was read; **[Inferred]** from patterns or code reading, not run;
**[Assumes]** needs an in-game check. Paths:
- `UI/` = `.tools/wow-ui-source/Interface/AddOns/` (Forever build 1.60.1.70938)
- `DOC/` = `UI/Blizzard_APIDocumentationGenerated/`
- `FA/` = `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/` (installed addons)
- `LSM` = `Libs/LibSharedMedia-3.0/LibSharedMedia-3.0/LibSharedMedia-3.0.lua` (vendored v12.1.3)

## 1. Goal

Pick one font once; every addon that lets you choose a font, and optionally the default Blizzard UI,
uses it, without changing any other addon's settings. Turning BubbleFonts off (or uninstalling it)
puts everything back as it was, because no other addon's saved settings are touched.

## 2. Non-goals

- Changing font **sizes** or outline flags. Each consumer keeps its own.
- Per-addon font choices ("Plater gets X, Details gets Y"). One font, everywhere.
- Replacing any function (`LSM:Fetch`, Blizzard functions) or overwriting globals
  (`STANDARD_TEXT_FONT` etc.). See CLAUDE.md conventions.
- Writing other addons' SavedVariables or rewriting LSM's media table.
- Replacing the game's own font files on disk (`_forever_\Fonts\`). That is a manual client mod,
  not something an addon can do. Section 7 lists where it would be the only way.

## 3. Background, for readers new to WoW addons

- **Addon loading.** At login (and on `/reload`), the client runs each enabled addon's Lua files in
  the order its `.toc` lists them, then fires `ADDON_LOADED` for it. `/reload` throws the whole UI
  away and rebuilds it. That is why "apply at load, change takes effect on reload" is a normal,
  safe design.
- **SavedVariables.** Globals named in the TOC are written to disk on logout or reload and restored
  on the next load. Normally that happens *after* the addon's files run;
  `## LoadSavedVariablesFirst: 1` asks the client to restore them *before*. It is used on this client
  by `FA/!BugGrabber/!BugGrabber.toc:30` and `FA/BugSack/BugSack.toc:17` [Read].
- **LibStub / LibSharedMedia (LSM).** Many addons embed their own copy of LSM. LibStub makes sure
  only one copy actually runs (the highest version number), so every addon talks to the same LSM
  instance and the same list of fonts. Addons register fonts by **name** (`"Expressway"` maps to a
  file path), save the name in their settings, and ask LSM for the path when they draw
  (`LSM:Fetch("font", name)`).
- **Font objects.** Blizzard's UI draws text through about 500 named "font objects"
  (`GameFontNormal`, `ChatFontNormal`, ...). Each holds a font file, size and flags. Changing one
  changes every piece of text drawn with it.
- **Taint.** WoW tracks whether code came from Blizzard or from an addon. If addon code changes
  something Blizzard's protected code later relies on, protected actions can be blocked
  ("action blocked" errors, often only in combat). Lint can't see this; only the game can.

## 4. Design

### 4.1 Core: LSM global override (`SetGlobal`), replacing the proposed table rewrite

LSM already has a supported global override, made for exactly this purpose:

```lua
-- LSM:295-300
function lib:Fetch(mediatype, key, noDefault)
    local mtt = mediaTable[mediatype]
    local overridekey = overrideMedia[mediatype]
    local result = mtt and ((overridekey and mtt[overridekey] or mtt[key]) or (not noDefault and ...
```

While `overrideMedia.font` is set, every `Fetch("font", anything)` returns the override font, even
with `noDefault` [Read LSM:298]. `SetGlobal("font", key)` sets it (LSM:324-331) and fires
`LibSharedMedia_SetGlobal`. This is a public API call, not a replacement of `Fetch` (which the
non-goals forbid).

**Why not the originally proposed table rewrite** (pointing every `MediaTable.font[name]` at our path):
- It reaches **fewer** addons correctly. The survey of installed addons found that the font-picker
  dropdowns in Plater, Details, Prat, Questie and DBM-GUI read `LSM:HashTable("font")` directly
  (`FA/Plater/libs/DF/dropdown.lua:1245-1246`; `FA/DBM-GUI/DBM-GUI.lua:165-199`; Prat
  `prototypes.lua:15`) [Read by research agent]. A rewrite makes all of their previews show one
  font. **DBM-GUI saves the path**, not the name, so opening DBM's font picker would write *our*
  path into DBM's settings, and the change would outlive BubbleFonts.
- `Register` refuses to overwrite existing keys (LSM:283-286), so a rewrite has to write to LSM's
  internal tables directly, and redo it for every later registration.
- `SetGlobal` is one call. It is undone by `SetGlobal("font", nil)` or by simply not calling it
  on the next load. LSM upgrades keep it: `lib.OverrideMedia = lib.OverrideMedia or {}` (LSM:45),
  and LibStub returns the **same** table to a newer copy (`Libs/LibStub/LibStub.lua:20-27`) [Read].

**Catch 1: the key must already be registered.** `SetGlobal` silently clears the override if the key
isn't in the media table yet, and still returns `true` (LSM:328) [Read]. So BubbleFonts registers
the chosen font itself before calling `SetGlobal`:

1. SavedVariables keep both the chosen LSM **name** and its **path** (captured when you pick it).
2. At load: if `name` is already registered, `SetGlobal("font", name)`.
3. Otherwise check `C_UIFileAsset.IsKnownFile(path)` (`DOC/UIFileAssetAPIDocumentation.lua:27-30`)
   [Read] and call `LSM:Register("font", name, path, langmask)`, then `SetGlobal`. Registering
   another addon's font name is normal LSM use: Plater and Details both register the same 7 names
   (`FA/Plater/Plater_DefaultSettings.lua:37-43`, `FA/Details/boot.lua:1572-1578`). When the real
   owner registers it later, `Register` returns false (duplicate, same file), which is harmless.
   - The `IsKnownFile` pre-check matters because `Register` reports unknown files to the error
     handler (LSM:251-254), which would put a BugSack error on every login after you uninstall the
     addon that shipped the font.
4. If the path is gone (that addon was uninstalled), fall back to the bundled font, if there is one
   (**DECISION 1**), and print one chat line.
5. If `Register` refuses for locale reasons (4.4), wait for `LibSharedMedia_Registered` with that
   name and call `SetGlobal` then.

**Catch 2: the override must be set before addons that cache at load time.** See 4.3.

### 4.2 Optional: Blizzard font objects

When on (**DECISION 2**), at load:

```
for each name in GetFonts():               -- DOC/FontDocumentation.lua:41-47 [Read]
  obj = _G[name]; file, size, flags = obj:GetFont()
  if file is one of the plain Blizzard text faces: obj:SetFont(ourPath, size, flags)
```

- `GetFonts()` returns every font object name, so no hand-kept list is needed [Read].
- **Which faces get replaced:** proposed `FRIZQT__.TTF` and `ARIALN.TTF`, the body text faces,
  matched by file name. The decorative faces `MORPHEUS` (quest/book titles) and `SKURRI` are left
  alone. These are the roman members across the 200 font families
  (`UI/Blizzard_Fonts_Shared/Shared/Fonts.xml`) [Read by research agent]. Say if you want those
  replaced too.
- Size and flags are kept. Blizzard's text-size setting (`TextSizeManager.lua:52-61`) changes only
  height with `SetFontHeight`, which "Preserves all flags" (`DOC/SimpleFontAPIDocumentation.lua:213`)
  [Read by research agent]. So our font file survives it [Inferred].
- **Restrictions:** `SetFont` is flagged only `SecretArguments = "AllowedWhenUntainted"`
  (`DOC/SimpleFontAPIDocumentation.lua:199-211`) [Read by research agent]. That rule is about
  passing *secret values*, and we pass ordinary strings and numbers. It is not
  `IsProtectedFunction` or `HasRestrictions`.
- **Taint:** no Blizzard secure code was found that branches on a font object's *file*. Secure reads
  found take only the height, or check that a font exists (`SecureUtil.lua:26, 38`;
  `Blizzard_Shared_StoreUISecure.lua:2479`) [Read by research agent]. Calling a widget method
  changes the object's state, not Blizzard's code, so taint is not expected [Inferred]. **This must
  be confirmed in game (8.2).** Watch in particular: chat bubbles in instances, which are forbidden
  frames that share `ChatBubbleFont`, and raid frames.
- **Chat windows take a private copy** of `ChatFontNormal` when `UPDATE_CHAT_WINDOWS` fires
  (`ChatFrameOverrides.lua:118-123` leads to `FontableFrameMixin.lua:128-136`, `CopyFontObject`)
  [Read by research agent]. That fires after all addons have loaded [Inferred], so a change made at
  load reaches them.
- **Objective tracker:** it re-points `ObjectiveTrackerLineFont` to `ObjectiveTrackerFont<size>`
  in Edit Mode (`Blizzard_ObjectiveTrackerManager.lua:97-106`). Iterating every object covers the
  `ObjectiveTrackerFont12..22` targets too.
- Leatrix Plus and Maps copy the face from Blizzard objects (`QuestFont:GetFont()`,
  `Leatrix_Plus.lua:8674-8678`), and so does TipTac's default config (`ttCore.lua:1874`).
  Applying at load, before they run, means they pick up our font [Inferred].

### 4.3 Timing: when the override is set

**Plan:** apply both 4.1 and 4.2 from the addon's own main chunk, the earliest moment our code runs,
with `## LoadSavedVariablesFirst: 1` so the saved choice is already available. If the SavedVariables
turn out to be nil there on a second login (meaning the directive doesn't work as assumed
[Assumes]), apply at our `ADDON_LOADED` instead. The apply function is written to be safe to call
twice, so this fallback costs nothing.

**When do other addons fetch?** (research agent, file:line in each addon)

| Addon | Fetch timing | Needs us loaded first? |
|---|---|---|
| Plater | on plate text refresh; Blizzard nameplate fonts at PLAYER_LOGIN (`Plater.lua:4793, 8444-8450`) | no |
| Details | on row refresh, title bar and tooltips; caches the path in its settings but re-fetches when applying (`window_main.lua:4215`, `fw.lua:1491-1493`) | no [Inferred: override wins on re-fetch] |
| SexyMap | PLAYER_LOGIN and on settings change (`SexyMap.lua:403`) | no |
| Questie | every tracker line (`TrackerLine.lua:208-216`) | no |
| Dominos cast/progress | bar update (`DominosTimerBarTemplate.lua:86`) | no |
| Prat | module enable / PLAYER_ENTERING_WORLD; chat font empty by default (`Font.lua:34`) | no |
| **MikScrollingBattleText** | **at its own load: copies every LSM font into its own table** (`MediaRegistry.lua:83-85`) | **yes** |

Only load-time cachers depend on load order. Among the installed addons that is only MSBT ("M" loads
after "Bu"). Any change made mid-session shows up only after `/reload`, so the UI offers a reload
button instead of trying to refresh other addons live.

**Load order and the "!" prefix:** neither Blizzard's source nor its docs state the load order. It is
done inside the game client, not in Lua. `AddonList` sorts by the client's own index, not by name
(`UI/Blizzard_AddOnList/AddonList.lua:523-535`) [Read by research agent]. The only evidence that
order is alphabetical is a DBM comment ("DBM would load before TomTom", `FA/DBM-Core/DBM-Arrow.lua:328`).
The "!" convention (`!BugGrabber`) is community knowledge [Assumes]. No TOC directive can say "load
before X" for addons we don't control: `LoadFirst` is Blizzard-only (`docs/forever-notes.md:35`),
and `Dependencies` only works in the other direction. **We will measure it in game** (8.3) rather than
rely on it.
**DECISION 3** (folder name).

### 4.4 Glyph coverage

- **LSM's locale gate:** on koKR/ruRU/zhCN/zhTW clients, `Register` rejects a font unless its
  langmask has that locale's bit (LSM:256-259; bits at LSM:31-35) [Read]. Fonts other addons
  registered on such a client therefore already claim coverage, and BubbleFonts will only use a
  font that LSM accepted on this client.
- **Our own registration:** the bundled font is registered with the langmask its actual glyphs
  support, for example `western + ruRU` for a Latin and Cyrillic font. A font picked from another
  addon is re-registered with `western` only. On a non-western client that registration is refused,
  and we wait for the owning addon to register it (4.1 step 5).
- **LSM-drawn text** gets one plain font file with no fallback, so characters the font lacks (for
  example Cyrillic names on an English client) show as boxes. That is already true whenever you pick
  such a font in Plater; BubbleFonts doesn't make it worse, but it does make it universal. It is the
  main reason to bundle a font that covers Latin, Cyrillic and Greek. Bundling CJK is not practical,
  since those fonts are 10+ MB.
- **Blizzard font objects** are font *families* with one member per alphabet (all 200 define
  roman/korean/simplifiedchinese/traditionalchinese/russian; `UI.xsd:168-176`) [Read by research
  agent]. We expect `SetFont` to replace only the client's own alphabet member, so Korean and
  Chinese text on an English client keeps Blizzard's fonts [Inferred, via
  `GetFontObjectForAlphabet` in `DOC/SimpleFontAPIDocumentation.lua:75-88`]. **Check in game (8.4).**
  The face filter in 4.2 matches only Latin face files, so on a ruRU client objects using
  `FRIZQT___CYR` are replaced only if our font covers ruRU. On koKR/zh clients they are not touched
  at all.

### 4.5 Settings and UI

**Superseded in 0.2.0** (2026-11-16): the vertical-list panel below became a canvas page
(`Settings.RegisterCanvasLayoutCategory`, used on Forever by TomTom, Auctionator and AceConfigDialog).
It shows a table of every LSM font, built from `HashTable` paths and never `Fetch`, so the override
doesn't flatten it. Each row is drawn in its own font, with columns for letter coverage (bundled fonts
only, from `Fonts.lua`) and source addon (from the file path). Above the table are a large preview and
the two checkboxes; below it is a footer with an in-page Reload UI button that is enabled while the
saved settings differ from the ones loaded (`ns.loaded`). There is no popup. The ScrollBox pieces
(`WowScrollBoxList`, `MinimalScrollBar`, `CreateScrollBoxListLinearView`,
`ScrollUtil.InitScrollBoxListWithScrollBar`) were checked in `UI/Blizzard_SharedXML/Shared/Scroll/`.
Bundled fonts: 14, listed in `Fonts.lua`, with sources in `Media/README.md`.

Original 0.1.0 design:

- SavedVariables `BubbleFontsDB`: `{ enabled = true, font = <LSM name>, path = <file path>, fontObjects = <bool> }`.
- **DECISION 4** (how the font is picked). The proposal is a panel in Blizzard's settings window
  (Settings API, `docs/forever-notes.md` "Settings panel API"):
  - an "Enabled" checkbox
  - a font dropdown built from `LSM:List("font")` when the panel opens, so fonts registered late are
    listed
  - a "Blizzard UI fonts" checkbox

  `/bubblefonts` (and `/bf`, if it isn't taken) opens the panel. Any change shows a "Reload UI to
  apply" popup.
  - Blizzard's dropdown shows names as plain text, with no preview in each font. So our own list
    is not flattened by the override (we read paths from `HashTable`, never from `Fetch`).
- `ReloadUI()` is not in the generated docs, because it is a global rather than a `C_` function.
  Blizzard calls it from its own addon-list button (`UI/Blizzard_AddOnList/AddonList.lua:618`)
  [Read]. Calling it from our popup button, which is also a click, is expected to work [Inferred].

## 5. Vendored libraries (done)

These are in `Libs/`, byte-identical to the official WowAce releases, and the hashes match the
downloads. Provenance, hashes and license notes are in `Libs/README.md`.

| Library | Release | MINOR | License |
|---|---|---|---|
| LibStub | 1.0.2-70000 | 2 | Public domain |
| CallbackHandler-1.0 | 1.0.9 | 8 | BSD-2.0 (TOC) |
| LibSharedMedia-3.0 | v12.1.3 (2026-10-21) | 12000005 | LGPL v2.1 (source header) |

- **Licenses:** none of the releases ships a license file. LSM's project page says "All Rights
  Reserved unless otherwise explicitly stated", and its source header explicitly states LGPL v2.1,
  which is what we ship with it. Not legal advice; noted for completeness.
- **Our copy is not the newest LSM code:** DBM-Core, Dominos and Plater embed an unreleased trunk
  build (r186) with the **same** MINOR. LibStub keeps whichever same-MINOR copy loads first
  (`LibStub.lua:25`), so loading earlier than them means ours runs. The only difference is one extra
  registered CJK font name ("AR HeiUHK BD") [Read by research agent]. Harmless.
- **Older copies:** Details and MSBT embed MINOR 8020003 and Questie 12000002. Their table
  initialization uses the same `x = x or {}` pattern, so whichever loads, upgrades keep the override
  [Read by research agent].

## 6. Coverage on the installed addons (expected)

| Addon | Covered by | Notes |
|---|---|---|
| Plater (incl. Blizzard nameplate fonts) | 4.1 | |
| Details | 4.1 | path cached in settings, but the override wins on re-fetch [Inferred] |
| SexyMap, Questie, Dominos cast/progress, Prat editbox | 4.1 | |
| MSBT | 4.1 | only because we load before it |
| Chat windows, tooltips, default UI, Prat chat | 4.2 | Prat sets no chat font by default |
| TipTac | 4.2 | uses `GameFontNormal`'s face at its load; restores the GameTooltip fonts it captured, which will be ours |
| Leatrix Plus/Maps | 4.2 | copy faces from Blizzard objects |
| **DBM bars** | **not covered** | saves paths; "standardFont" is hard-coded `Fonts\FRIZQT__.TTF` (`StandardFont.lua:4-14`), deliberately ("skinning mods like to taint it") |
| **MinimalistCooldownEdge** | **not covered** | saves paths |
| **VoidBox** | **not attempted** (confirmed in game 2026-11-15) | no LSM, no font option; saved path defaulting to `Fonts\FRIZQT__.TTF` (VoidBox `Core.lua:26,48`), `STANDARD_TEXT_FONT` for auras (`Auras.lua:389`). The only ways to reach it (a global `SetFont` hook or writing its settings) break this spec's non-goals |
| **In-world unit names, floating damage numbers** | **not covered** | the game client reads `UNIT_NAME_FONT` / `DAMAGE_TEXT_FONT` (`Shared/GameFonts.xml:3-27`); covering them would mean overwriting globals |

## 7. Known limits

1. **Hard-coded and path-saving consumers** (table above): DBM, MinimalistCooldownEdge, VoidBox and
   anything else that saves a file path or uses `Fonts\FRIZQT__.TTF` directly. You set those by hand
   in their own options, which is also safe, since BubbleFonts doesn't fight them.
2. **Font dropdowns that preview through `Fetch` show every entry in our font:** TipTacOptions,
   SexyMap's LibDDI pickers and Dominos_Config. **TipTacOptions also saves the fetched path**, so
   picking any font there while BubbleFonts is on saves *our* path into TipTac
   (`AzOptionsFactory.lua:849-858`). Other dropdowns (Plater, Details, Prat, Questie, DBM) still
   preview correctly, but choosing a font there has no visible effect while BubbleFonts is on.
3. **Changes need `/reload`.** Most addons have no "font changed" callback. Prat registers one, but
   its handler has an argument bug and never acts (`Font.lua:178-190`). MSBT caches at load.
4. **Load order** is not under our control and not documented (4.3). Addons that cache fonts while
   loading and sort before us would miss the font.
5. **Glyph coverage** (4.4): LSM-drawn text has no per-alphabet fallback.
6. **Another addon calling `SetGlobal("font", ...)`** would conflict, and the last caller wins. None
   of the installed addons does [Read by research agent].
7. **Taint** is verified only in game (8.2).

## 8. In-game verification plan (`/reload` + BugSack)

`python tools/lint.py` catches API misuse only. Taint, timing and glyph problems appear only in game.

1. **Basics:** pick the font, `/reload`, then check Plater plates, Details windows, the SexyMap clock,
   the Questie tracker, MSBT scrolling text, chat, tooltips and quest log.
   `/dump LibStub("LibSharedMedia-3.0"):GetGlobal("font")` must print our key.
2. **Taint:** play with BugSack open through combat, a dungeon (chat bubbles), the raid frames and
   Edit Mode. Optionally run `/console taintLog 1`, `/reload`, play, then read `Logs\taint.log`.
   That the cvar exists on Forever is [Assumes]. Any `ADDON_ACTION_BLOCKED` naming BubbleFonts is a
   blocker.
3. **Load order:** a temporary debug line logs `debugprofilestop()` in our main chunk, and we compare
   it with `/dump` of `C_AddOns.GetAddOnInfo` order or a temporary `ADDON_LOADED` print listing which
   addons loaded before us. Run it with and without the "!" prefix.
4. **Glyphs:** `/dump GameFontNormal:GetFontObjectForAlphabet("russian"):GetFont()` vs `"roman"`
   after applying. The roman member should be ours and the russian one unchanged. Then look at a
   Cyrillic or Korean player name in chat.
5. **LoadSavedVariablesFirst:** on the second login, a debug print in the main chunk shows that
   `BubbleFontsDB` is not nil.

## 9. Implementation plan (after approval)

1. `BubbleFonts.toc`:
   - `## Interface: 16001`, Title/Notes, `## Version: @project-version@`
   - `## SavedVariables: BubbleFontsDB`, `## LoadSavedVariablesFirst: 1`
   - `## X-Curse-Project-ID` once you have the project
   - file list: Libs (LibStub, CallbackHandler, LSM lib.xml), then `Core.lua`, `FontObjects.lua`,
     `Options.lua`
2. `Media/` holds the bundled font (if DECISION 1 bundles one) plus its license file.
3. `Core.lua`:
   - namespace, defaults merge
   - `RegisterBundledFont()`
   - `ApplyOverride()` (4.1 steps 1-5)
   - `LibSharedMedia_Registered` wait for a late font
   - apply at main chunk, with the `ADDON_LOADED` fallback
4. `FontObjects.lua`: the face filter and the `GetFonts()` pass (4.2). It runs only when the toggle is
   on and the font covers the client's locale.
5. `Options.lua`: settings category, checkboxes, LSM dropdown, reload popup, slash commands. Every
   Settings API call is verified against `UI/Blizzard_Settings_Shared` first.
6. `.luarc.json`: add `BubbleFontsDB`, `SLASH_BUBBLEFONTS1` (and `2`) to `diagnostics.globals`.
7. Run `python tools/lint.py` after every Lua change.
8. Junction install:
   `mklink /J "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\<Folder>" C:\Dev\BosDev\bubble-fonts`
   This links a game folder to the repo, so `/reload` picks up edits.
9. Write `README.md` (what it covers, the limits from section 7, the font license) and `CHANGELOG.md`
   (first release notes). Run `python tools/package.py --check`, then build the zip.

## 10. Decisions (answered 2026-11-15)

1. **DECISION 1 – Font:** **bundle Inter SemiBold** (SIL OFL 1.1; chosen 2026-11-15 over Noto Sans,
   Source Sans 3, Fira Sans, Rubik and Nunito after a visual comparison) as the default and fallback,
   registered under the LSM name "BubbleFonts: Inter SemiBold" with langmask `western + ruRU`
   (Latin, Cyrillic, Greek; checked from the font's cmap). The font file and `OFL.txt` come from the official Inter release and go in
   `Media/`, with the source and hash recorded.
2. **DECISION 2 – Blizzard font-object toggle:** **on** by default.
3. **DECISION 3 – Folder/TOC name:** **`BubbleFonts`** (no "!"). Revisit only if in-game check 8.3
   shows an addon that caches fonts while loading and loads before us.
4. **DECISION 4 – Picker:** **settings panel + slash command**, as described in 4.5.
