-- Settings page (Esc > Options > AddOns > BubbleFonts) and the /bubblefonts command.
-- A table of every LSM font, each row drawn in its own font. Choices are saved at once and take
-- effect on reload (docs/SPEC.md section 4.3); the page offers the reload.

local _, ns = ...

local ROW_HEIGHT = 26
local SAMPLE = "Murloc  0/7  1,234"
local PREVIEW_SAMPLE = "Murloc Streamrunner   Kill Murloc 0/7   Experience gained: 480"
local GOLD = NORMAL_FONT_COLOR
local DIM = "|cff5c5c5c"

local category, page, scrollBox, preview, reloadButton, status
local db

-- Where a font file comes from, by its path: Interface\AddOns\<Folder>\... or the game's Fonts\.
local function Source(path)
  local folder = path:match("^[Ii]nterface[\\/][Aa]dd[Oo]ns[\\/]([^\\/]+)[\\/]")
  if folder then
    return folder
  end
  return path:lower():match("^fonts[\\/]") and "Game" or "?"
end

-- Letter coverage as three tags, missing ones dimmed. Known only for the fonts we ship.
local function Letters(bundled)
  if not bundled then
    return DIM .. "?|r"
  end
  local function tag(has, text) return has and text or (DIM .. text .. "|r") end
  return ("Lat  %s  %s"):format(tag(bundled.cyrillic, "Cyr"), tag(bundled.greek, "Gre"))
end

-- Draws text in a font file. Our own font strings, so this never touches anything Blizzard's.
local function SetFace(fontString, path, size)
  if not (path and C_UIFileAsset.IsKnownFile(path) and fontString:SetFont(path, size, "")) then
    fontString:SetFontObject(GameFontHighlight)
  end
end

local function BuildList()
  local provider = CreateDataProvider()
  local function AddSection(header, entries)
    if #entries == 0 then
      return
    end
    provider:Insert({ header = header })
    for i, entry in ipairs(entries) do
      entry.stripe = i % 2 == 0
      provider:Insert(entry)
    end
  end

  local registered = ns.LSM:HashTable("font")
  local ours, others = {}, {}
  for _, font in ipairs(ns.BUNDLED) do
    if registered[font.key] then   -- LSM refuses fonts whose letters don't cover the client's language
      table.insert(ours, { key = font.key, label = font.name, path = font.path, bundled = font })
    end
  end
  for _, key in ipairs(ns.LSM:List("font")) do
    if not ns.BUNDLED_BY_KEY[key] then
      table.insert(others, { key = key, label = key, path = registered[key] })
    end
  end
  AddSection("Bundled with BubbleFonts", ours)
  AddSection("From your other addons", others)
  return provider
end

local function PendingReload()
  local loaded = ns.loaded
  return loaded.enabled ~= db.enabled or loaded.font ~= db.font or loaded.fontObjects ~= db.fontObjects
end

local function UpdateFooter()
  local pending = PendingReload()
  reloadButton:SetEnabled(pending)
  status:SetText(pending and "Changes apply after a reload." or "Your settings are in use.")
end

local function UpdatePreview()
  local bundled = ns.BUNDLED_BY_KEY[db.font]
  local path = bundled and bundled.path or ns.LSM:HashTable("font")[db.font] or db.path
  SetFace(preview.name, path, 22)
  SetFace(preview.sample, path, 14)
  preview.name:SetText(bundled and bundled.name or db.font)
end

local function RefreshRows()
  scrollBox:ForEachFrame(function(row, entry)
    if not entry.header then
      local selected = entry.key == db.font
      row.radio:SetChecked(selected)
      row.selected:SetShown(selected)
    end
  end)
end

local function Select(entry)
  db.font, db.path = entry.key, entry.path
  UpdatePreview()
  RefreshRows()
  UpdateFooter()
end

local function ShowRowTooltip(row)
  local entry = row.entry
  if not entry or entry.header then
    return
  end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:SetText(entry.label, 1, 1, 1)
  -- A path has no spaces to wrap at, so file name and folder go on separate lines.
  local folder, file = entry.path:match("^(.*)[\\/]([^\\/]+)$")
  GameTooltip:AddLine(file or entry.path, 0.85, 0.85, 0.85)
  if folder then
    GameTooltip:AddLine(folder, 0.55, 0.55, 0.55)
  end
  if entry.bundled then
    GameTooltip:AddLine("Letters: Latin" .. (entry.bundled.cyrillic and ", Cyrillic" or "")
      .. (entry.bundled.greek and ", Greek" or ""), GOLD.r, GOLD.g, GOLD.b)
  else
    GameTooltip:AddLine("Registered by another addon; its letter coverage isn't known.", GOLD.r, GOLD.g, GOLD.b, true)
  end
  GameTooltip:Show()
end

local function CreateRow(row)
  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()
  row.selected = row:CreateTexture(nil, "BACKGROUND", nil, 1)
  row.selected:SetAllPoints()
  row.selected:SetColorTexture(GOLD.r, GOLD.g, GOLD.b, 0.12)
  row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
  row.highlight:SetAllPoints()
  row.highlight:SetColorTexture(1, 1, 1, 0.06)

  row.radio = CreateFrame("CheckButton", nil, row, "UIRadialButtonTemplate")
  row.radio:SetPoint("LEFT", 6, 0)
  row.radio:EnableMouse(false)   -- the whole row is the click target

  -- Every font string starts from a template: SetText errors ("Font not set") on one with no font,
  -- and SetFace only replaces the face when the file is valid.
  row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  row.name:SetPoint("LEFT", 32, 0)
  row.name:SetWidth(250)
  row.name:SetJustifyH("LEFT")
  row.name:SetWordWrap(false)

  row.sample = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  row.sample:SetPoint("LEFT", 292, 0)
  row.sample:SetPoint("RIGHT", -190, 0)
  row.sample:SetJustifyH("LEFT")
  row.sample:SetWordWrap(false)
  row.sample:SetTextColor(0.85, 0.85, 0.85)

  row.letters = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.letters:SetPoint("RIGHT", -96, 0)
  row.letters:SetWidth(88)
  row.letters:SetJustifyH("LEFT")

  row.from = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  row.from:SetPoint("RIGHT", -8, 0)
  row.from:SetWidth(84)
  row.from:SetJustifyH("LEFT")
  row.from:SetWordWrap(false)

  row.header = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  row.header:SetPoint("BOTTOMLEFT", 8, 4)

  row:SetScript("OnClick", function(self) if self.entry and not self.entry.header then Select(self.entry) end end)
  row:SetScript("OnEnter", ShowRowTooltip)
  row:SetScript("OnLeave", GameTooltip_Hide)
end

local function InitRow(row, entry)
  if not row.created then
    row.created = true
    CreateRow(row)
  end
  row.entry = entry
  local isHeader = entry.header ~= nil
  row.header:SetShown(isHeader)
  for _, part in ipairs({ row.radio, row.name, row.sample, row.letters, row.from, row.highlight }) do
    part:SetShown(not isHeader)
  end
  row:EnableMouse(not isHeader)
  if isHeader then
    row.header:SetText(entry.header:upper())
    row.bg:SetColorTexture(0, 0, 0, 0)
    row.selected:Hide()
    return
  end
  row.bg:SetColorTexture(1, 1, 1, entry.stripe and 0.025 or 0)   -- zebra stripes
  SetFace(row.name, entry.path, 14)
  row.name:SetText(entry.label)
  SetFace(row.sample, entry.path, 13)
  row.sample:SetText(SAMPLE)
  row.letters:SetText(Letters(entry.bundled))
  row.from:SetText(entry.bundled and "BubbleFonts" or Source(entry.path or ""))
  local selected = entry.key == db.font
  row.radio:SetChecked(selected)
  row.selected:SetShown(selected)
end

local function CreateCheckbox(label, tooltip, get, set)
  local check = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
  check:SetSize(26, 26)
  check.Text:SetFontObject(GameFontHighlight)
  check.Text:SetText(label)
  check.tooltip = tooltip
  check:SetScript("OnClick", function(self) set(self:GetChecked()); UpdateFooter() end)
  check:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(label, 1, 1, 1)
    GameTooltip:AddLine(self.tooltip, GOLD.r, GOLD.g, GOLD.b, true)
    GameTooltip:Show()
  end)
  check:SetScript("OnLeave", GameTooltip_Hide)
  check.Refresh = function(self) self:SetChecked(get()) end
  return check
end

local function Refresh()
  page.enabled:Refresh()
  page.fontObjects:Refresh()
  scrollBox:SetDataProvider(BuildList(), ScrollBoxConstants.RetainScrollPosition)
  UpdatePreview()
  UpdateFooter()
end

local function BuildPage()
  page = CreateFrame("Frame")

  local title = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("BubbleFonts")
  local subtitle = page:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  subtitle:SetText("One font for every addon. Each row below is drawn in its own font.")

  page.enabled = CreateCheckbox("Enabled",
    "Make every addon that uses LibSharedMedia fonts use the font you pick here.",
    function() return db.enabled end, function(value) db.enabled = value end)
  page.enabled:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -4, -10)
  page.fontObjects = CreateCheckbox("Blizzard UI fonts",
    "Also use it in the default UI: chat, tooltips, quest text, and addons that copy those fonts.",
    function() return db.fontObjects end, function(value) db.fontObjects = value end)
  page.fontObjects:SetPoint("LEFT", page.enabled.Text, "RIGHT", 28, 0)

  -- Live preview of the selected font.
  preview = CreateFrame("Frame", nil, page)
  preview:SetPoint("TOPLEFT", page.enabled, "BOTTOMLEFT", 4, -10)
  preview:SetPoint("RIGHT", -16, 0)
  preview:SetHeight(64)
  local previewBg = preview:CreateTexture(nil, "BACKGROUND")
  previewBg:SetAllPoints()
  previewBg:SetColorTexture(0, 0, 0, 0.35)
  local previewEdge = preview:CreateTexture(nil, "BORDER")
  previewEdge:SetPoint("TOPLEFT")
  previewEdge:SetPoint("BOTTOMLEFT")
  previewEdge:SetWidth(2)
  previewEdge:SetColorTexture(GOLD.r, GOLD.g, GOLD.b, 0.8)
  preview.name = preview:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  preview.name:SetPoint("TOPLEFT", 14, -10)
  preview.name:SetTextColor(GOLD.r, GOLD.g, GOLD.b)
  preview.name:SetShadowOffset(1, -1)
  preview.sample = preview:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  preview.sample:SetPoint("BOTTOMLEFT", 14, 10)
  preview.sample:SetPoint("RIGHT", -14, 0)
  preview.sample:SetJustifyH("LEFT")
  preview.sample:SetWordWrap(false)
  preview.sample:SetShadowOffset(1, -1)
  preview.sample:SetText(PREVIEW_SAMPLE)

  -- Column headings, aligned with the row layout in CreateRow.
  local columns = CreateFrame("Frame", nil, page)
  columns:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -10)
  columns:SetPoint("RIGHT", -38, 0)
  columns:SetHeight(16)
  local function Column(text, point, x, width)
    local heading = columns:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    heading:SetPoint(point, x, 0)
    if width then heading:SetWidth(width) end
    heading:SetJustifyH("LEFT")
    heading:SetText(text)
  end
  Column("Font", "LEFT", 32)
  Column("Sample", "LEFT", 292)
  Column("Letters", "RIGHT", -96, 88)
  Column("From", "RIGHT", -8, 84)

  -- Footer: reload state.
  reloadButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
  reloadButton:SetSize(120, 24)
  reloadButton:SetPoint("BOTTOMRIGHT", -16, 12)
  reloadButton:SetText("Reload UI")
  reloadButton:SetScript("OnClick", function() ReloadUI() end)
  status = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  status:SetPoint("RIGHT", reloadButton, "LEFT", -12, 0)

  -- The table.
  scrollBox = CreateFrame("Frame", nil, page, "WowScrollBoxList")
  scrollBox:SetPoint("TOPLEFT", columns, "BOTTOMLEFT", 0, -4)
  scrollBox:SetPoint("BOTTOMRIGHT", reloadButton, "TOPRIGHT", -22, 12)
  local scrollBar = CreateFrame("EventFrame", nil, page, "MinimalScrollBar")
  scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 8, 0)
  scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 8, 0)
  local view = CreateScrollBoxListLinearView()
  view:SetElementExtent(ROW_HEIGHT)
  view:SetElementInitializer("Button", InitRow)
  ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

  page.OnRefresh = Refresh
  page.OnDefault = function()
    for key, value in pairs(ns.DEFAULTS) do
      db[key] = value
    end
    Refresh()
  end
  page:SetScript("OnShow", Refresh)
end

function ns.InitOptions(savedDB)
  db = savedDB
  BuildPage()
  category = Settings.RegisterCanvasLayoutCategory(page, "BubbleFonts")
  Settings.RegisterAddOnCategory(category)
end

local function OpenSettings()
  if not category then   -- the page is built at ADDON_LOADED; an error there leaves it missing
    ns.Print("settings aren't available; see BugSack for the load error.")
    return
  end
  -- Opening the settings panel goes through C_SettingsUtil.OpenSettingsPanel, flagged
  -- HasRestrictions (SettingsUtilDocumentation.lua:15-18); stay out of combat with it.
  if InCombatLockdown() then
    ns.Print("can't open settings in combat.")
    return
  end
  -- apiguard: allow only from a slash command or compartment click (hardware events), never in combat
  Settings.OpenToCategory(category:GetID())
end

SLASH_BUBBLEFONTS1 = "/bubblefonts"
SLASH_BUBBLEFONTS2 = "/bfonts"
SlashCmdList.BUBBLEFONTS = OpenSettings

-- Entry in Blizzard's addon compartment (the minimap's addon list), declared in the TOC
-- (## AddonCompartmentFunc / FuncOnEnter / FuncOnLeave); Blizzard calls these by global name
-- (UI/Blizzard_Minimap/Mainline/AddonCompartment.lua:106-111). Same pattern as Questmarker.
function BubbleFonts_OnAddonCompartmentClick()
  OpenSettings()
end

function BubbleFonts_OnAddonCompartmentEnter(_, menuButton)
  local bundled = db and ns.BUNDLED_BY_KEY[db.font]
  GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
  GameTooltip:SetText("BubbleFonts", 1, 1, 1)
  if db then
    GameTooltip:AddLine(db.enabled and ("Font: " .. (bundled and bundled.name or db.font)) or "Off",
      GOLD.r, GOLD.g, GOLD.b)
  end
  GameTooltip:AddLine("Click: settings", 0.8, 0.8, 0.8)
  GameTooltip:Show()
end

function BubbleFonts_OnAddonCompartmentLeave()
  GameTooltip:Hide()
end
