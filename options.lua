-- RothRaidManager Settings owner for Retail 12.1.
local ADDON = ...
if ADDON ~= "RothRaidManager" then return end

local registered = false

local function Refresh()
  if type(_G.RothRaidManager_Refresh) == "function" then
    _G.RothRaidManager_Refresh()
  end
end

local function RegisterSettings()
  if registered or not Settings or not Settings.RegisterVerticalLayoutCategory then return false end
  registered = true

  local category = Settings.RegisterVerticalLayoutCategory("RothRaidManager")
  _G.RothRaidManager_SettingsCategoryID = category:GetID()

  local function AddCheckbox(variable, key, label, defaultValue, tooltip)
    local setting = Settings.RegisterAddOnSetting(
      category,
      variable,
      key,
      RothRaidManagerDB,
      Settings.VarType.Boolean,
      label,
      defaultValue
    )
    setting:SetValueChangedCallback(function() Refresh() end)
    Settings.CreateCheckbox(category, setting, tooltip)
    return setting
  end

  AddCheckbox("ROTH_RAID_MANAGER_ENABLED", "enabled", "Enabled", true, "Show the panel while in a party or raid.")
  AddCheckbox("ROTH_RAID_MANAGER_LOCKED", "locked", "Locked", true, "Disable modifier-dragging while locked.")
  AddCheckbox("ROTH_RAID_MANAGER_CTRL_ALT_DRAG", "ctrlAltDrag", "Require CTRL+ALT to drag", true)
  AddCheckbox("ROTH_RAID_MANAGER_EXPANDED", "expanded", "Expanded panel", false, "Use the wider, fully opaque panel state.")

  local scaleSetting = Settings.RegisterAddOnSetting(
    category,
    "ROTH_RAID_MANAGER_SCALE",
    "scale",
    RothRaidManagerDB,
    Settings.VarType.Number,
    "Scale",
    1.0
  )
  scaleSetting:SetValueChangedCallback(function() Refresh() end)
  local options = Settings.CreateSliderOptions(0.6, 2.0, 0.05)
  Settings.CreateSlider(category, scaleSetting, options, "Scale the raid utility panel.")

  Settings.RegisterAddOnCategory(category)
  return true
end

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
  EventUtil.ContinueOnAddOnLoaded(ADDON, RegisterSettings)
else
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function(self)
    if RegisterSettings() then self:UnregisterAllEvents() end
  end)
end
