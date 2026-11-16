-- The fonts BubbleFonts ships, in the order the settings table lists them. Letter coverage comes from
-- each file's cmap (Media/README.md): every font has full Latin; `cyrillic` and `greek` mark full sets.

local ADDON_NAME, ns = ...

local DIR = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Fonts\\"

ns.BUNDLED = {
  { name = "Inter SemiBold", file = "Inter\\Inter-SemiBold.ttf", cyrillic = true, greek = true },
  { name = "Atkinson Hyperlegible Bold", file = "AtkinsonHyperlegible\\AtkinsonHyperlegible-Bold.ttf" },
  { name = "Barlow Semi Condensed SemiBold", file = "BarlowSemiCondensed\\BarlowSemiCondensed-SemiBold.ttf" },
  { name = "Fredoka SemiBold", file = "Fredoka\\Fredoka-SemiBold.ttf" },
  { name = "Comic Neue Bold", file = "ComicNeue\\ComicNeue-Bold.ttf" },
  { name = "Righteous", file = "Righteous\\Righteous-Regular.ttf" },
  { name = "MedievalSharp", file = "MedievalSharp\\MedievalSharp.ttf" },
  { name = "Uncial Antiqua", file = "UncialAntiqua\\UncialAntiqua-Regular.ttf" },
  { name = "Orbitron SemiBold", file = "Orbitron\\Orbitron-SemiBold.ttf" },
  { name = "Russo One", file = "RussoOne\\RussoOne-Regular.ttf", cyrillic = true },
  { name = "Black Ops One", file = "BlackOpsOne\\BlackOpsOne-Regular.ttf" },
  { name = "JetBrains Mono SemiBold", file = "JetBrainsMono\\JetBrainsMono-SemiBold.ttf", cyrillic = true, greek = true },
  -- Pixelify Sans lacks Cyrillic O and P (U+041E, U+041F), so it is not offered to ruRU clients.
  { name = "Pixelify Sans Medium", file = "PixelifySans\\PixelifySans-Medium.ttf" },
  { name = "Special Elite", file = "SpecialElite\\SpecialElite-Regular.ttf" },
}

ns.BUNDLED_BY_KEY = {}
for _, font in ipairs(ns.BUNDLED) do
  font.key = "BubbleFonts: " .. font.name   -- LSM key: groups our fonts in every addon's font list
  font.path = DIR .. font.file
  ns.BUNDLED_BY_KEY[font.key] = font
end

ns.DEFAULT_FONT = ns.BUNDLED[1]
