# BubbleFonts

Pick one font and every addon uses it. No more setting the same font in Plater, Details, SexyMap,
Questie and the rest one by one.

For WoW Forever.

## How it works

Most addons with a font dropdown get their fonts from LibSharedMedia, a library they share.
BubbleFonts uses LibSharedMedia's own "global font" setting, so every one of those addons draws with
your font. **Your settings in other addons are not changed**: turn BubbleFonts off and each addon
goes back to the font you picked there.

Optionally (on by default) it also changes Blizzard's own UI fonts: chat, tooltips, quest text, and
addons that copy those fonts (TipTac, Leatrix Plus). Font sizes and outlines are kept.

## Usage

`/bubblefonts` (or Esc > Options > AddOns > BubbleFonts):

- **Enabled**: on or off.
- **Font**: any font registered by any installed addon. The default is the bundled Inter SemiBold.
- **Blizzard UI fonts**: also change the default UI's fonts.

Changes apply after a UI reload; BubbleFonts offers one when you change a setting.

## Known limits

- **Not covered:**
  - Addons that store a font *file* instead of using LibSharedMedia: DBM's bars and
    MinimalistCooldownEdge. Set those in their own options.
  - **VoidBox**: BubbleFonts doesn't try to change it. VoidBox doesn't use LibSharedMedia and has
    no font option of its own, so its frames keep their built-in font.
  - Names above characters' heads and damage numbers in the game world. These come from the game
    client itself.
- While BubbleFonts is on, font dropdowns that preview each font through LibSharedMedia (TipTac,
  SexyMap, Dominos) show every entry in your font. In **TipTac's** options, picking a font while
  BubbleFonts is on saves the BubbleFonts font as your TipTac font.
- Fonts other than the bundled Inter SemiBold may lack Cyrillic or Greek letters, so names in those
  alphabets can show as boxes in addon text. Korean and Chinese text in Blizzard's UI keeps
  Blizzard's fonts.
- An addon that sets LibSharedMedia's global font itself would conflict with BubbleFonts.

## Credits and licenses

- BubbleFonts: GPL v3 (`LICENSE`).
- Inter: SIL Open Font License 1.1 (`Media/OFL.txt`), by the Inter Project Authors.
- LibStub (public domain), CallbackHandler-1.0 (BSD), LibSharedMedia-3.0 (LGPL v2.1). See
  `Libs/README.md`.
