-- RothRaidManager Settings UI (no Ace)
local ADDON = ...
if ADDON ~= "RothRaidManager" then return end

local function DB() return RothRaidManagerDB end
local function Frame() return _G["RothRaidManager"] end

local function Apply()
  local f = Frame()
  if not f then return end
  f:SetScale(DB().scale or 1.0)
  f:ClearAllPoints()
  local p = DB().pos or { point="LEFT", relPoint="LEFT", x=0, y=0 }
  f:SetPoint(p.point or "LEFT", UIParent, p.relPoint or "LEFT", p.x or 0, p.y or 0)
  if f.SetClampRectInsets then f:SetClampRectInsets(-400,0,0,0) end
  f:SetShown(DB().enabled ~= false)
end

local function MakeCheck(parent, label, tooltip, get, set)
  local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
  cb.Text:SetText(label)
  cb.tooltipText = tooltip
  cb:SetScript("OnShow", function(self) self:SetChecked(get() and true or false) end)
  cb:SetScript("OnClick", function(self) set(self:GetChecked()) end)
  return cb
end

local function MakeSlider(parent, label, minV, maxV, step, get, set)
  local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step)
  s:SetObeyStepOnDrag(true)
  s:SetWidth(260)
  _G[s:GetName().."Text"]:SetText(label)
  _G[s:GetName().."Low"]:SetText(tostring(minV))
  _G[s:GetName().."High"]:SetText(tostring(maxV))
  s:SetScript("OnShow", function(self) self:SetValue(get()) end)
  s:SetScript("OnValueChanged", function(self, v) set(v) end)
  return s
end

local panel = CreateFrame("Frame")
panel.name = "RothRaidManager"

panel:SetScript("OnShow", function(self)
  if self._built then return end
  self._built = true

  local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("RothRaidManager")

  local enabled = MakeCheck(self, "Enabled", nil,
    function() return DB().enabled ~= false end,
    function(v) DB().enabled = v and true or false; Apply() end)
  enabled:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -12)

  local unlocked = MakeCheck(self, "Unlocked (allow drag)", "Drag with ALT by default; CTRL+ALT if 'Require CTRL+ALT' is enabled.",
    function() return DB().locked == false end,
    function(v) if SlashCmdList and SlashCmdList.ROTHRAIDMANAGER then SlashCmdList.ROTHRAIDMANAGER(v and "unlock" or "lock") end end)
  unlocked:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 0, -6)

  local req = MakeCheck(self, "Require CTRL+ALT for drag", nil,
    function() return DB().ctrlAltDrag ~= false end,
    function(v) DB().ctrlAltDrag = v and true or false end)
  req:SetPoint("TOPLEFT", unlocked, "BOTTOMLEFT", 0, -6)

  local scale = MakeSlider(self, "Scale", 0.6, 2.0, 0.05,
    function() return tonumber(DB().scale) or 1.0 end,
    function(v) DB().scale = v; local f=Frame(); if f then f:SetScale(v) end end)
  scale:SetPoint("TOPLEFT", req, "BOTTOMLEFT", 0, -18)

  local dock = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
  dock:SetSize(160, 22)
  dock:SetText("Dock Left Edge")
  dock:SetPoint("TOPLEFT", scale, "BOTTOMLEFT", 0, -16)
  dock:SetScript("OnClick", function()
    DB().pos = { point="LEFT", relPoint="LEFT", x=0, y=0 }
    Apply()
  end)

  local reset = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
  reset:SetSize(80, 22)
  reset:SetText("Reset")
  reset:SetPoint("LEFT", dock, "RIGHT", 8, 0)
  reset:SetScript("OnClick", function()
    if SlashCmdList and SlashCmdList.ROTHRAIDMANAGER then SlashCmdList.ROTHRAIDMANAGER("reset") end
    Apply()
  end)
end)

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
  local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
else
  InterfaceOptions_AddCategory(panel)
end
