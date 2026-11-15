-- Optional: put the chosen font on Blizzard's font objects, keeping each one's size and flags.
-- Design and evidence: docs/SPEC.md section 4.2.

local _, ns = ...

-- Body-text faces that get replaced, matched by file name. Decorative faces (MORPHEUS, SKURRI) and
-- the CJK faces stay. GetFont returns the member for the client's own alphabet, so on koKR/zh
-- clients nothing here matches.
local REPLACED_FACES = {
  ["frizqt__.ttf"] = true,
  ["frizqt___cyr.ttf"] = true,
  ["arialn.ttf"] = true,
}

local function FaceName(file)
  return file:lower():match("([^\\/]+)$")
end

function ns.ApplyFontObjects(path)
  for _, name in ipairs(GetFonts()) do
    local object = _G[name]
    if type(object) == "table" and object.IsObjectType and object:IsObjectType("Font") then
      local file, height, flags = object:GetFont()
      if file and height and height > 0 and REPLACED_FACES[FaceName(file)] then
        object:SetFont(path, height, flags)
      end
    end
  end
end
