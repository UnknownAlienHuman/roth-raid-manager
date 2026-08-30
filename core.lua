-- RothRaidManager runtime owner for Retail 12.1.
-- Secure world-marker macros remain declarative and are created only out of combat.
-- Ordinary raid/group utility calls fail closed in combat and are never queued.

local ADDON = ...
local unpack = table.unpack or unpack

RothRaidManagerDB = type(RothRaidManagerDB) == "table" and RothRaidManagerDB or {}

local DB_VERSION = 2
local defaults = {
  version = DB_VERSION,
  enabled = true,
  locked = true,
  scale = 1.0,
  ctrlAltDrag = true,
  expanded = false,
  pos = { point = "LEFT", relPoint = "LEFT", x = 0, y = 0 },
}

local VALID_POINTS = {
  TOPLEFT = true, TOP = true, TOPRIGHT = true,
  LEFT = true, CENTER = true, RIGHT = true,
  BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local DB
local manager
local initialized = false
local pendingInitialize = false
local pendingApply = false
local lastBlockedMessage
local buttons = {}

local RAID_MARKER_TEXTURES = {
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:14:14|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:14:14|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:14:14|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:14:14|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14:14|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:14:14|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:14:14|t",
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14|t",
}

local function CanAccess(value)
  if type(canaccessvalue) == "function" then
    local ok, accessible = pcall(canaccessvalue, value)
    return ok and accessible == true
  end
  if type(issecretvalue) == "function" then
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret ~= true
  end
  return true
end

local function SafeBoolean(value)
  if not CanAccess(value) or type(value) ~= "boolean" then return nil end
  return value
end

local function SafeNumber(value)
  if not CanAccess(value) or type(value) ~= "number" or value ~= value then return nil end
  return value
end

local function SafeString(value)
  if not CanAccess(value) or type(value) ~= "string" then return nil end
  return value
end

local function SafeTable(value)
  if not CanAccess(value) or type(value) ~= "table" then return nil end
  if type(issecrettable) == "function" then
    local ok, secret = pcall(issecrettable, value)
    if not ok or secret == true then return nil end
  end
  return value
end

local function InCombat()
  if type(InCombatLockdown) ~= "function" then return false end
  local ok, value = pcall(InCombatLockdown)
  return ok and SafeBoolean(value) == true
end

local function ClampNumber(value, fallback, minimum, maximum)
  value = SafeNumber(value)
  if value == nil then return fallback end
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function MergeDefaults(target, source)
  if type(target) ~= "table" then target = {} end
  for key, value in pairs(source) do
    if type(value) == "table" then
      target[key] = MergeDefaults(target[key], value)
    elseif type(target[key]) ~= type(value) then
      target[key] = value
    end
  end
  return target
end

local function SanitizeDB()
  DB = MergeDefaults(SafeTable(RothRaidManagerDB) or {}, defaults)
  RothRaidManagerDB = DB

  DB.version = DB_VERSION
  DB.enabled = SafeBoolean(DB.enabled) ~= false
  DB.locked = SafeBoolean(DB.locked) ~= false
  DB.ctrlAltDrag = SafeBoolean(DB.ctrlAltDrag) ~= false
  DB.expanded = SafeBoolean(DB.expanded) == true
  DB.scale = ClampNumber(DB.scale, defaults.scale, 0.6, 2.0)

  DB.pos = SafeTable(DB.pos) or {}
  local point = SafeString(DB.pos.point)
  local relativePoint = SafeString(DB.pos.relPoint)
  DB.pos.point = point and VALID_POINTS[point] and point or defaults.pos.point
  DB.pos.relPoint = relativePoint and VALID_POINTS[relativePoint] and relativePoint or defaults.pos.relPoint
  DB.pos.x = math.floor(ClampNumber(DB.pos.x, defaults.pos.x, -4000, 4000) + 0.5)
  DB.pos.y = math.floor(ClampNumber(DB.pos.y, defaults.pos.y, -4000, 4000) + 0.5)

  DB.pendingApply = nil
  DB.pendingInitialize = nil
  DB.needReload = nil
  return DB
end

local function Print(message)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(message)
  elseif print then
    print(message)
  end
end

local function PrintBlocked(label)
  local now = 0
  if type(GetTime) == "function" then
    local ok, value = pcall(GetTime)
    if ok then now = SafeNumber(value) or 0 end
  end
  if lastBlockedMessage and now - lastBlockedMessage < 1 then return end
  lastBlockedMessage = now
  Print("|cffff5555RothRaidManager:|r " .. label .. " is blocked during combat.")
end

local function RunOutOfCombat(label, functionName, ...)
  if InCombat() then
    PrintBlocked(label)
    return false
  end

  local callback = _G[functionName]
  if type(callback) ~= "function" then
    Print("|cffff5555RothRaidManager:|r " .. label .. " is unavailable on this client.")
    return false
  end

  local ok = pcall(callback, ...)
  if not ok then
    Print("|cffff5555RothRaidManager:|r " .. label .. " failed.")
    return false
  end
  return true
end

local function SetTooltip(button, text)
  button:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(text, 0, 1, 0.5, true)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)
end

local function CreateButton(parent, name, text, tooltip, secure)
  local template = secure and "SecureActionButtonTemplate,UIPanelButtonTemplate" or "UIPanelButtonTemplate"
  local button = CreateFrame("Button", name, parent, template)
  button:SetSize(30, 30)
  button:SetText(text)
  SetTooltip(button, tooltip)
  buttons[#buttons + 1] = button
  return button
end

local function SetUtilityAction(button, label, functionName, ...)
  local arguments = { ... }
  button:SetScript("OnClick", function()
    RunOutOfCombat(label, functionName, unpack(arguments))
  end)
end

local function ApplyVisibilityDriver()
  if not manager then return end
  if InCombat() then pendingApply = true return end

  if type(UnregisterStateDriver) == "function" then
    pcall(UnregisterStateDriver, manager, "visibility")
  end

  if DB.enabled then
    if type(RegisterStateDriver) == "function" then
      pcall(RegisterStateDriver, manager, "visibility", "[group:party][group:raid] show; hide")
    else
      manager:Show()
    end
  else
    manager:Hide()
  end
end

local function Apply()
  if not initialized or not manager then return false end
  SanitizeDB()
  if InCombat() then pendingApply = true return false end

  pendingApply = false
  manager:ClearAllPoints()
  manager:SetPoint(DB.pos.point, UIParent, DB.pos.relPoint, DB.pos.x, DB.pos.y)
  manager:SetScale(DB.scale)
  manager:SetWidth(DB.expanded and 275 or 200)
  manager:SetAlpha(DB.expanded and 1 or 0.4)
  manager:EnableMouse(not DB.locked)
  ApplyVisibilityDriver()
  return true
end

local function ToggleExpanded()
  if InCombat() then
    PrintBlocked("panel expansion")
    return false
  end
  DB.expanded = not DB.expanded
  Apply()
  return true
end

local function CreateUI()
  if manager then return true end
  if InCombat() then
    pendingInitialize = true
    return false
  end

  manager = CreateFrame("Frame", ADDON, UIParent, "SecureHandlerStateTemplate,BackdropTemplate")
  manager:SetFrameStrata("DIALOG")
  manager:SetSize(200, 390)
  manager:SetClampedToScreen(true)
  if manager.SetClampRectInsets then manager:SetClampRectInsets(-400, 0, 0, 0) end
  manager:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  manager:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  manager:SetBackdropBorderColor(0.7, 0.7, 0.7)
  manager:SetMovable(true)
  manager:RegisterForDrag("LeftButton")

  manager:SetScript("OnDragStart", function(self)
    if DB.locked or InCombat() then return end
    if type(IsAltKeyDown) == "function" and not IsAltKeyDown() then return end
    if DB.ctrlAltDrag and type(IsControlKeyDown) == "function" and not IsControlKeyDown() then return end
    self:StartMoving()
  end)

  manager:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    point, relativePoint = SafeString(point), SafeString(relativePoint)
    x, y = SafeNumber(x), SafeNumber(y)
    if point and VALID_POINTS[point] and relativePoint and VALID_POINTS[relativePoint] and x and y then
      DB.pos.point, DB.pos.relPoint = point, relativePoint
      DB.pos.x, DB.pos.y = math.floor(x + 0.5), math.floor(y + 0.5)
    end
  end)

  local previous
  for index, texture in ipairs(RAID_MARKER_TEXTURES) do
    local place = CreateButton(manager, ADDON .. "WorldMarker" .. index, texture, "Place world marker " .. index, true)
    place:SetAttribute("type", "macro")
    place:SetAttribute("macrotext", string.format("/wm %d", index))
    if previous then
      place:SetPoint("TOP", previous, "BOTTOM", 0, 0)
    else
      place:SetPoint("TOPRIGHT", manager, -25, -10)
    end

    local clear = CreateButton(
      manager,
      ADDON .. "WorldMarker" .. index .. "Clear",
      "|TInterface\\Buttons\\UI-GroupLoot-Pass-Up:14:14:0:0|t",
      "Clear world marker " .. index,
      true
    )
    clear:SetAttribute("type", "macro")
    clear:SetAttribute("macrotext", string.format("/cwm %d", index))
    clear:SetPoint("RIGHT", place, "LEFT", 0, 0)
    previous = place
  end

  local clearAll = CreateButton(manager, ADDON .. "ClearAll", "|TInterface\\Buttons\\UI-GroupLoot-Pass-Up:14:14:0:0|t", "Clear all world markers")
  SetUtilityAction(clearAll, "clear all world markers", "ClearRaidMarker")
  clearAll:SetPoint("TOP", previous, "BOTTOM", 0, 0)
  previous = clearAll

  local roleCheck = CreateButton(manager, ADDON .. "RoleCheck", "|TInterface\\LFGFrame\\LFGRole:14:14:0:0:64:16:32:48:0:16|t", "Role check")
  SetUtilityAction(roleCheck, "role check", "InitiateRolePoll")
  roleCheck:SetPoint("TOP", previous, "BOTTOM", 0, -10)
  previous = roleCheck

  local toParty = CreateButton(manager, ADDON .. "ToParty", "|TInterface\\GroupFrame\\UI-Group-AssistantIcon:14:14:0:0|t", "Convert raid to party")
  SetUtilityAction(toParty, "convert to party", "ConvertToParty")
  toParty:SetPoint("RIGHT", roleCheck, "LEFT", 0, 0)

  local ready = CreateButton(manager, ADDON .. "ReadyCheck", "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t", "Ready check")
  SetUtilityAction(ready, "ready check", "DoReadyCheck")
  ready:SetPoint("TOP", previous, "BOTTOM", 0, 0)
  previous = ready

  local toRaid = CreateButton(manager, ADDON .. "ToRaid", "|TInterface\\GroupFrame\\UI-Group-LeaderIcon:14:14:0:0|t", "Convert party to raid")
  SetUtilityAction(toRaid, "convert to raid", "ConvertToRaid")
  toRaid:SetPoint("RIGHT", ready, "LEFT", 0, 0)

  local pull = CreateButton(manager, ADDON .. "Pull", "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14:14:0:0|t", "Run /pull 10", true)
  pull:SetAttribute("type", "macro")
  pull:SetAttribute("macrotext", "/pull 10")
  pull:SetPoint("TOP", previous, "BOTTOM", 0, 0)
  previous = pull

  local stopwatch = CreateButton(manager, ADDON .. "Stopwatch", "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-AwayMobile:14:14:0:0|t", "Toggle stopwatch")
  SetUtilityAction(stopwatch, "stopwatch", "Stopwatch_Toggle")
  stopwatch:SetPoint("RIGHT", pull, "LEFT", 0, 0)

  local toggle = CreateButton(manager, ADDON .. "PanelToggle", "", "Expand or collapse the raid manager")
  toggle:SetPoint("TOPRIGHT", manager, "TOPRIGHT", -3, -3)
  toggle:SetPoint("BOTTOMRIGHT", manager, "BOTTOMRIGHT", -3, 3)
  toggle:SetWidth(15)
  toggle:SetScript("OnClick", ToggleExpanded)
  local toggleBackground = toggle:CreateTexture(nil, "BACKGROUND")
  toggleBackground:SetAllPoints(toggle)
  toggleBackground:SetColorTexture(1, 1, 1, 0.05)

  _G.RothRaidManager = manager
  return true
end

local function Activate()
  if initialized then return true end
  if InCombat() then
    pendingInitialize = true
    return false
  end
  if not DB then SanitizeDB() end
  if not CreateUI() then return false end
  initialized = true
  pendingInitialize = false
  return Apply()
end

local function ResetPosition()
  if InCombat() then
    PrintBlocked("position reset")
    return false
  end
  DB.pos = { point = "LEFT", relPoint = "LEFT", x = 0, y = 0 }
  return Apply()
end

local function Slash(message)
  message = SafeString(message)
  message = message and message:lower():gsub("^%s+", ""):gsub("%s+$", "") or ""
  if not DB then SanitizeDB() end

  if message == "unlock" then
    DB.locked = false
    Apply()
    Print("|cff00ff00RothRaidManager|r unlocked (ALT-drag; CTRL+ALT when required).")
  elseif message == "lock" then
    DB.locked = true
    Apply()
    Print("|cff00ff00RothRaidManager|r locked.")
  elseif message == "toggle" then
    DB.enabled = not DB.enabled
    Apply()
    Print("|cff00ff00RothRaidManager|r " .. (DB.enabled and "enabled" or "disabled"))
  elseif message == "reset" then
    if ResetPosition() then Print("|cff00ff00RothRaidManager|r position reset.") end
  elseif message == "expand" then
    if not DB.expanded then ToggleExpanded() end
  elseif message == "collapse" then
    if DB.expanded then ToggleExpanded() end
  elseif message == "config" and _G.RothRaidManager_SettingsCategoryID and Settings then
    Settings.OpenToCategory(_G.RothRaidManager_SettingsCategoryID)
  else
    Print("|cff00ff00RothRaidManager|r: /rrm lock | unlock | toggle | reset | expand | collapse | config")
  end
end

SLASH_ROTHRAIDMANAGER1 = "/rrm"
SlashCmdList.ROTHRAIDMANAGER = Slash

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
EventFrame:SetScript("OnEvent", function(_, event, argument)
  if event == "ADDON_LOADED" then
    local name = SafeString(argument)
    if name == ADDON then SanitizeDB() end
  elseif event == "PLAYER_LOGIN" then
    if not DB then SanitizeDB() end
    Activate()
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pendingInitialize then
      Activate()
    elseif pendingApply then
      Apply()
    end
  end
end)

_G.RothRaidManager_Refresh = Apply
_G.RothRaidManager_Runtime = {
  Activate = Activate,
  Apply = Apply,
  RunOutOfCombat = RunOutOfCombat,
  GetManager = function() return manager end,
  GetButtonCount = function() return #buttons end,
  IsApplyPending = function() return pendingApply end,
  IsInitializePending = function() return pendingInitialize end,
  IsInitialized = function() return initialized end,
  GetDB = function() return DB end,
}
