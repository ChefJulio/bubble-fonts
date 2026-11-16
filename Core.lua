-- BubbleFonts core: makes every LibSharedMedia font lookup return the chosen font.
-- Design and evidence: docs/SPEC.md section 4.

local ADDON_NAME, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

ns.LSM = LSM

ns.DEFAULTS = {
  enabled = true,
  font = ns.DEFAULT_FONT.key,   -- LSM key of the chosen font
  path = ns.DEFAULT_FONT.path,  -- its file, so we can register it before its own addon loads
  fontObjects = true,           -- also restyle Blizzard's font objects (FontObjects.lua)
}
local DEFAULTS = ns.DEFAULTS

local notices = {}   -- chat lines queued until PLAYER_LOGIN, when the chat frame shows them
local applied = false

local function Notify(msg)
  table.insert(notices, msg)
end

function ns.Print(msg)
  print("|cff66ccffBubbleFonts|r: " .. msg)
end

local function InitDB()
  BubbleFontsDB = BubbleFontsDB or {}
  for key, value in pairs(DEFAULTS) do
    if BubbleFontsDB[key] == nil then
      BubbleFontsDB[key] = value
    end
  end
  return BubbleFontsDB
end

-- Turns the override on for `key` (which must be registered; SetGlobal clears unknown keys).
local function Activate(db, key)
  LSM:SetGlobal("font", key)
  if db.fontObjects then
    ns.ApplyFontObjects(LSM:HashTable("font")[key])
  end
end

-- Late path: the chosen font is registered by an addon loading after us. Used when our own
-- registration was refused (LSM's locale gate on non-western clients).
local function ActivateWhenRegistered(db)
  LSM.RegisterCallback(ns, "LibSharedMedia_Registered", function(_, mediatype, key)
    if mediatype == "font" and key == db.font then
      LSM.UnregisterCallback(ns, "LibSharedMedia_Registered")
      Activate(db, key)
    end
  end)
end

local function Apply(db)
  applied = true
  -- What this session runs with; the settings page compares against it to offer a reload.
  ns.loaded = { enabled = db.enabled, font = db.font, fontObjects = db.fontObjects }
  if not db.enabled then
    return
  end

  -- A bundled font's file can move between versions; its key stays.
  local bundled = ns.BUNDLED_BY_KEY[db.font]
  if bundled then
    db.path = bundled.path
  end

  local fonts = LSM:HashTable("font")
  if fonts[db.font] then
    Activate(db, db.font)
    return
  end

  -- Not registered yet: register it ourselves from the saved path. Pre-check the file, because
  -- LSM:Register reports unknown files to the error handler (LibSharedMedia-3.0.lua:251-254).
  if db.path and C_UIFileAsset.IsKnownFile(db.path) then
    if LSM:Register("font", db.font, db.path, LSM.LOCALE_BIT_western) then
      Activate(db, db.font)
    else
      ActivateWhenRegistered(db)
    end
    return
  end

  -- The font's file is gone (its addon was removed): fall back to the bundled font. That one is
  -- missing only where LSM refused it (koKR/zh clients); then there is nothing to apply.
  local default = ns.DEFAULT_FONT
  if db.font ~= default.key then
    Notify(("font \"%s\" is no longer installed; using %s."):format(db.font, default.name))
    db.font, db.path = default.key, default.path
    ns.loaded.font = db.font
  end
  if fonts[db.font] then
    Activate(db, db.font)
  end
end

-- Registered at load so they show up in every addon's LSM font list. The langmask tells LSM which
-- clients the glyphs cover: it refuses these fonts on clients whose letters they lack.
for _, font in ipairs(ns.BUNDLED) do
  local langmask = LSM.LOCALE_BIT_western + (font.cyrillic and LSM.LOCALE_BIT_ruRU or 0)
  LSM:Register("font", font.key, font.path, langmask)
end

-- Apply as early as possible: with LoadSavedVariablesFirst the saved choice is already here, before
-- addons that load after us read any font. On a first install it is nil; ADDON_LOADED applies then.
if BubbleFontsDB then
  Apply(InitDB())
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    self:UnregisterEvent("ADDON_LOADED")
    local db = InitDB()
    if not applied then
      Apply(db)
    end
    ns.InitOptions(db)
  elseif event == "PLAYER_LOGIN" then
    self:UnregisterEvent("PLAYER_LOGIN")
    for _, msg in ipairs(notices) do
      ns.Print(msg)
    end
  end
end)
