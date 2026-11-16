# Bundled media

`Icon.tga`: in-game icon, drawn by `tools/logo.py`.

## Fonts

Every font file is unmodified, from its official source, and static (no variable-font tables) at the
weight listed. Each folder in `Fonts/` holds the font and the license that ships with it.
Verified 2026-11-16.

`GF` = `https://raw.githubusercontent.com/google/fonts/7af0d90b4d532ffa4b041937b560c6df4e7b1e95/`
(Google's official font distribution, pinned to a commit).

| Font | Source | Version | sha256 | License |
|---|---|---|---|---|
| Inter SemiBold | Inter v4.1 release zip, `extras/ttf/Inter-SemiBold.ttf`: https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip (zip sha256 `9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e`) | 4.1 | `78a843fade9d4612a5567302fb595b56976eb5fcebf4fea5a5912d638bafcde3` | OFL 1.1 |
| Atkinson Hyperlegible Bold | `GF/ofl/atkinsonhyperlegible/AtkinsonHyperlegible-Bold.ttf` | 1.006 | `5a3b0c8cc8ca545155150b4512a1fa248298df121c50d6557e651e61fbdab92f` | OFL 1.1 |
| Barlow Semi Condensed SemiBold | `GF/ofl/barlowsemicondensed/BarlowSemiCondensed-SemiBold.ttf` | 1.408 | `bd299f4bc5b44d30be8d42e9bad3a5df7d66af1cd55d0ed72a8b8916360a1424` | OFL 1.1 |
| Fredoka SemiBold | https://raw.githubusercontent.com/hafontia-zz/Fredoka-One/35c584ff23450c9bcdf8819706e12fcdeefe1712/fonts/ttf/Fredoka-SemiBold.ttf (the source google/fonts names) | 2.001 | `95839d50cc746b491c4710673be1d2cc8179a132f9600851810863922ddc12f9` | OFL 1.1 |
| Comic Neue Bold | `GF/ofl/comicneue/ComicNeue-Bold.ttf` | 2.003 | `3e7e5fccfd7e0788f317b43312151c1bd5cf058c9697a8d83eac3939050bd61e` | OFL 1.1 |
| Righteous | `GF/ofl/righteous/Righteous-Regular.ttf` | 1.000 | `2ffb3fe5c27d7e6571210b800448c4e234e651b46c6b4426c1bb567e5341348a` | OFL 1.1, Reserved Font Name "Righteous" |
| MedievalSharp | `GF/ofl/medievalsharp/MedievalSharp.ttf` (weight class 500, its only weight) | 1.0 | `74cb2e6738bd7703adf120802f68fba0c9ddb9147a08e6847f1005b1e55df5a5` | OFL 1.1, Reserved Font Name "MedievalSharp" |
| Uncial Antiqua | `GF/ofl/uncialantiqua/UncialAntiqua-Regular.ttf` | 1.000 | `33a5128b59d1c95d4f3788164f4ab3a1196f0a982263cb2cd278c47418366766` | OFL 1.1, Reserved Font Name "Uncial Antiqua" |
| Orbitron SemiBold | https://raw.githubusercontent.com/googlefonts/orbitron-vf/f16482824e0ce4d008dee59b9b632e9ce9663359/fonts/ttf/Orbitron-SemiBold.ttf (the source google/fonts names) | 2.001 | `c7669d18ff29d6d65afc0d2d76da4dab3a942f353b3b0bd5466666f52ec5633d` | OFL 1.1, Reserved Font Name "Orbitron" |
| Russo One | `GF/ofl/russoone/RussoOne-Regular.ttf` | 1.001 | `bc0abcc660bd8b7ad3000ecb2898a27c58a29a50f7ec81652fa12e75148d09df` | OFL 1.1, Reserved Font Name "Russo" |
| Black Ops One | `GF/ofl/blackopsone/BlackOpsOne-Regular.ttf` | 1.004 | `282a825b5f294377387e3969f765408157dbea8da0f5d0aae68c6bc704b145b3` | OFL 1.1 |
| JetBrains Mono SemiBold | JetBrains Mono v2.304 release zip, `fonts/ttf/JetBrainsMono-SemiBold.ttf`: https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip | 2.304 | `1b3bfa1ed5665a4ce3f9feb68d2d4e40e70bf8b4b7d9a3edd418f321b4e166a0` | OFL 1.1 |
| Pixelify Sans Medium | https://raw.githubusercontent.com/eifetx/Pixelify-Sans/39df74aba80df8157546034b878e8be1eb565ced/fonts/ttf/PixelifySans-Medium.ttf (the source google/fonts names) | 1.000 | `5219b5ad08fde84e82b4a926614766c253379757eca86f56b766b0bdbfff69af` | OFL 1.1 |
| Special Elite | `GF/apache/specialelite/SpecialElite-Regular.ttf` | 1.001 | `a776fcb4ceb8bdf03e2967688ebdad42680de5b91a7e62c17e718ae212d14bc4` | Apache 2.0 |

Reserved Font Names only restrict the name of a *modified* font; these files are never modified (no
subsetting or instancing), so they ship under their own names.

## Letter coverage

Counted from each font's cmap: Latin = U+0020-007E and U+00C0-00FF (159), Cyrillic = U+0401,
U+0410-044F, U+0451 (66), Greek = U+0391-03A1, U+03A3-03C9 (56). `Fonts.lua` marks only full sets,
and the LSM langmask follows it (Cyrillic adds the ruRU bit).

| Font | Latin | Cyrillic | Greek |
|---|---|---|---|
| Inter | full | full | full |
| JetBrains Mono | full | full | full |
| Russo One | full | full | 1 |
| Pixelify Sans | full | 64 (no О, П: treated as none) | 52 |
| Orbitron | 152 (no `^`, Ð ð Ø ø Þ þ) | none | none |
| All others | full | none | 0-6 symbol letters (Δ Ω μ π) |
