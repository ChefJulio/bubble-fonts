# Vendored libraries

Copied unmodified from the official WowAce releases below (verified 2026-11-15). Never edit these
files; to upgrade, replace a folder with a newer official release and update this table.

| Library | Release | MINOR | Source | License |
|---|---|---|---|---|
| LibStub | 1.0.2-70000 (2016-08-18) | 2 | https://www.wowace.com/projects/libstub/files/937452 | Public domain ([LICENSE-LibStub.txt](LICENSE-LibStub.txt)) |
| CallbackHandler-1.0 | 1.0.9 (2022-12-12) | 8 | https://www.wowace.com/projects/callbackhandler/files/4167614 | BSD-2.0 per its TOC ([LICENSE-CallbackHandler-1.0.txt](LICENSE-CallbackHandler-1.0.txt)) |
| LibSharedMedia-3.0 | v12.1.3 (2026-10-21) | 12000005 | https://www.wowace.com/projects/libsharedmedia-3-0/files/9277931 | LGPL v2.1 per its source header ([LICENSE-LibSharedMedia-3.0.txt](LICENSE-LibSharedMedia-3.0.txt)) |

Release zip sha256:
- LibStub-1.0.2-70000.zip `8dfe91c949a01bbdaedea88295dfa100d25920bcf93d12b3b9bd5eb3593a2d74`
- CallbackHandler-1.0-1.0.9.zip `75b11a307243d2dbbc80d9d4eb83a7824b4179a097470a98f4cd460c07e0299d`
- LibSharedMedia-3.0-v12.1.3.zip `cb9ddb72a651e2455c8804fdea74e01c44e9fc17c6aaed73ccea1f2208dee8f9`

Left out of the copies (unchanged files, just not needed): LibStub's `tests/`, and the LibStub and
CallbackHandler copies nested inside the CallbackHandler and LSM zips (same code as the standalone
releases above).

License notes:
- None of the three releases ships a license file; the license texts here are added beside the
  folders, not inside them.
- LSM's project page says "All Rights Reserved unless otherwise explicitly stated"; the source header
  (`LibSharedMedia-3.0.lua:10`) explicitly states LGPL v2.1, which is what applies.
- CallbackHandler's TOC says BSD-2.0; its project page shows an unfilled BSD 3-clause template.

Load order in the TOC: LibStub, then CallbackHandler-1.0, then LibSharedMedia-3.0.
