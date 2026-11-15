-- Settings panel (Esc > Options > AddOns > BubbleFonts) and the /bubblefonts command.
-- Changes are saved immediately and take effect on /reload (docs/SPEC.md section 4.3).

local _, ns = ...

local RELOAD_KEY = "BubbleFontsReload"
local category

local function AskReload()
  if StaticPopup_IsCustomGenericConfirmationShown(RELOAD_KEY) then
    return
  end
  StaticPopup_ShowCustomGenericConfirmation({
    text = "BubbleFonts: reload the UI to apply the new font settings?",
    callback = ReloadUI,
    acceptText = "Reload",
    cancelText = "Later",
    referenceKey = RELOAD_KEY,
  })
end

-- Builds the font list each time the dropdown opens, so fonts registered late are included.
-- Labels are plain text: previewing through LSM:Fetch would show every entry in the override font.
local function FontOptions()
  local container = Settings.CreateControlTextContainer()
  for _, name in ipairs(ns.LSM:List("font")) do
    container:Add(name, name)
  end
  return container:GetData()
end

function ns.InitOptions(db)
  category = Settings.RegisterVerticalLayoutCategory("BubbleFonts")

  local enabled = Settings.RegisterProxySetting(category, "BUBBLEFONTS_ENABLED", Settings.VarType.Boolean,
    "Enabled", true,
    function() return db.enabled end,
    function(value) db.enabled = value; AskReload() end)
  Settings.CreateCheckbox(category, enabled,
    "Make every addon that uses LibSharedMedia fonts use the font below.")

  local font = Settings.RegisterProxySetting(category, "BUBBLEFONTS_FONT", Settings.VarType.String,
    "Font", ns.BUNDLED_NAME,
    function() return db.font end,
    function(value)
      db.font = value
      db.path = ns.LSM:HashTable("font")[value]
      AskReload()
    end)
  Settings.CreateDropdown(category, font, FontOptions,
    "Fonts registered with LibSharedMedia by any installed addon.")

  local fontObjects = Settings.RegisterProxySetting(category, "BUBBLEFONTS_FONT_OBJECTS",
    Settings.VarType.Boolean, "Blizzard UI fonts", true,
    function() return db.fontObjects end,
    function(value) db.fontObjects = value; AskReload() end)
  Settings.CreateCheckbox(category, fontObjects,
    "Also use the font in the default UI: chat, tooltips, quest text, and addons that copy those fonts.")

  Settings.RegisterAddOnCategory(category)
end

SLASH_BUBBLEFONTS1 = "/bubblefonts"
SLASH_BUBBLEFONTS2 = "/bfonts"
SlashCmdList.BUBBLEFONTS = function()
  -- Opening the settings panel goes through C_SettingsUtil.OpenSettingsPanel, flagged
  -- HasRestrictions (SettingsUtilDocumentation.lua:15-18); stay out of combat with it.
  if InCombatLockdown() then
    ns.Print("can't open settings in combat.")
    return
  end
  -- apiguard: allow only from a typed slash command (hardware event), never in combat (guard above)
  Settings.OpenToCategory(category:GetID())
end
