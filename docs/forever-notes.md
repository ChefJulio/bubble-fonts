# WoW Forever: client notes for addon authors

Carried over from Questmarker's research (2026-11-14, Forever build 1.60.1.70938, TOC interface 16001).
Re-verify against `.tools/wow-ui-source` if the pinned build in `tools/toolchain.json` has moved.

Path shorthands:
- `UI/` = `.tools/wow-ui-source/Interface/AddOns/`
- `DOC/` = `UI/Blizzard_APIDocumentationGenerated/`
- `FA/` = `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/` (installed addons;
  Questie, TomTom, Leatrix are useful references for what works on Forever)

Evidence tags: **[Read]** cited file read; **[Inferred]** from patterns; **[Assumes]** needs in-game check.

## Restriction flags

Many APIs carry `SecretArguments = "AllowedWhenUntainted"`: a *secret value* may be passed as an
argument only from untainted (Blizzard) code. An addon passing ordinary values is unaffected.
`tools/apiguard.py` treats this flag and `AllowedWhenTainted` as benign; it flags `HasRestrictions`,
`Secret*Returns`, `IsProtectedFunction`, `SecureOnly`, and APIs missing from the Forever docs.

`tools/apiguard.py` `OBSERVED_PROTECTED` lists functions seen blocked in game that the docs don't flag.
Add to it only with in-game evidence (BugSack `ADDON_ACTION_BLOCKED`).

## Annotations gap

Ketho's annotations (pinned commit) lack about 44 `C_` namespaces that Forever's docs have
(`C_UIFileAsset`, `C_Intl`, `C_Vehicle`, ...). `tools/lint.py` generates loose declarations for them
into `.tools/generated/ForeverNamespaces.lua`; apiguard still checks those calls against the docs.

## TOC

- One `<Addon>.toc` with `## Interface: 16001` is enough. Blizzard gates files with
  `[AllowLoadGameType camelot]`; third-party addons that ship several flavors pick by file name
  (`_Forever.toc`, `_Camelot.toc`) [Read].
- `## SavedVariables` and `## SavedVariablesPerCharacter` work as usual; Questie also uses
  `## LoadSavedVariablesFirst: 1` [Read].
- Addon list / compartment metadata: `IconTexture` / `IconAtlas` (UI/Blizzard_AddOnList/AddonList.lua:390-391),
  `Group`, `Category` (:453-456), `AddonCompartmentFunc` (+ `OnEnter`/`OnLeave`)
  (UI/Blizzard_Minimap/Mainline/AddonCompartment.lua:106-111) [Read].
- Blizzard-only directives, not for us: `AllowAddOnTableAccess`, `SuppressLocalTableRef`,
  `UseSecureEnvironment`, `AllowLoad`, `AllowLoadGameType`, `DefaultState`, `LoadFirst`,
  `SavedVariablesMachine` [Inferred].
- `@project-version@` in `## Version:` is filled by the packager from the git tag.

## Settings panel API

Present unchanged on Forever, in UI/Blizzard_Settings_Shared/Blizzard_Settings.lua (loads for all game types) [Read]:
- `Settings.RegisterAddOnCategory(category)` (:134-138)
- `Settings.OpenToCategory(categoryID, scrollToElementName)` (:144-146); goes through
  `C_SettingsUtil.OpenSettingsPanel`, check its flags before calling it in combat
- `Settings.RegisterVerticalLayoutCategory(name)`, `RegisterVerticalLayoutSubcategory(parent, name)` (:154-160)
- `Settings.RegisterCanvasLayoutCategory(frame, name)`, `RegisterCanvasLayoutSubcategory(parent, frame, name)` (:162-168)
- `Settings.RegisterAddOnSetting(categoryTbl, variable, variableKey, variableTbl, variableType, name, defaultValue)` (:174-176)
- `Settings.RegisterProxySetting(categoryTbl, variable, variableType, name, defaultValue, getValue, setValue)` (:178-180)
- `Settings.CreateCheckbox` (:388), `CreateSlider` (:404), `CreateDropdown` (:410), `CreateSliderOptions(min, max, rate)` (:309)

Line numbers are from build 1.60.1.70938.

## Local install

WoW lives at `C:\Program Files (x86)\World of Warcraft`; Forever is the `_forever_` folder. Install
the addon for testing as a directory junction from `_forever_\Interface\AddOns\<AddonFolder>` to
this repo, so `/reload` picks up edits directly.
