local combat = false
local now = 10
local calls = {
  clear = 0,
  role = 0,
  party = 0,
  ready = 0,
  raid = 0,
  stopwatch = 0,
}
local visibilityRegistrations = 0
local visibilityUnregistrations = 0
local eventFrame
local namedFrames = {}

local function assertEq(actual, expected, message)
  if actual ~= expected then
    error((message or "assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

local function newObject(objectType, name, parent, template)
  local object = {
    objectType = objectType or "Frame",
    name = name,
    parent = parent,
    template = template,
    width = 0,
    height = 0,
    alpha = 1,
    scale = 1,
    point = "CENTER",
    relativeTo = parent,
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    shown = true,
    scripts = {},
    attributes = {},
    events = {},
  }

  function object:RegisterEvent(event) self.events[event] = true end
  function object:UnregisterAllEvents() self.events = {} end
  function object:SetScript(script, callback) self.scripts[script] = callback end
  function object:SetFrameStrata(value) self.strata = value end
  function object:SetSize(width, height) self.width, self.height = width, height end
  function object:SetWidth(width) self.width = width end
  function object:SetHeight(height) self.height = height end
  function object:GetWidth() return self.width end
  function object:GetHeight() return self.height end
  function object:SetScale(value) self.scale = value end
  function object:SetAlpha(value) self.alpha = value end
  function object:ClearAllPoints() self.point = nil end
  function object:SetPoint(point, relativeTo, relativePoint, x, y)
    if type(relativeTo) == "number" then
      x, y = relativeTo, relativePoint
      relativeTo, relativePoint = self.parent, point
    end
    self.point, self.relativeTo, self.relativePoint = point, relativeTo, relativePoint
    self.x, self.y = x or 0, y or 0
  end
  function object:GetPoint() return self.point, self.relativeTo, self.relativePoint, self.x, self.y end
  function object:SetMovable(value) self.movable = value end
  function object:EnableMouse(value) self.mouseEnabled = value end
  function object:RegisterForDrag(button) self.dragButton = button end
  function object:SetClampedToScreen(value) self.clamped = value end
  function object:SetClampRectInsets(...) self.clampInsets = { ... } end
  function object:SetBackdrop(value) self.backdrop = value end
  function object:SetBackdropColor(...) self.backdropColor = { ... } end
  function object:SetBackdropBorderColor(...) self.backdropBorderColor = { ... } end
  function object:SetText(value) self.text = value end
  function object:SetShown(value) self.shown = value end
  function object:Show() self.shown = true end
  function object:Hide() self.shown = false end
  function object:IsShown() return self.shown end
  function object:StartMoving() self.isMoving = true end
  function object:StopMovingOrSizing() self.isMoving = false end
  function object:SetAttribute(key, value) self.attributes[key] = value end
  function object:GetAttribute(key) return self.attributes[key] end
  function object:CreateTexture(_, layer)
    local texture = newObject("Texture", nil, self, nil)
    texture.layer = layer
    function texture:SetAllPoints(relativeTo) self.relativeTo = relativeTo end
    function texture:SetColorTexture(...) self.color = { ... } end
    return texture
  end

  if name then
    namedFrames[name] = object
    _G[name] = object
  end
  return object
end

function canaccessvalue(value) return value ~= _G.SECRET end
function issecretvalue(value) return value == _G.SECRET end
function InCombatLockdown() return combat end
function GetTime() return now end
function IsAltKeyDown() return true end
function IsControlKeyDown() return true end
function RegisterStateDriver(frame, state, driver)
  visibilityRegistrations = visibilityRegistrations + 1
  frame.stateDriver = { state, driver }
end
function UnregisterStateDriver(frame, state)
  visibilityUnregistrations = visibilityUnregistrations + 1
  frame.stateDriver = nil
end
function ClearRaidMarker() calls.clear = calls.clear + 1 end
function InitiateRolePoll() calls.role = calls.role + 1 end
function ConvertToParty() calls.party = calls.party + 1 end
function DoReadyCheck() calls.ready = calls.ready + 1 end
function ConvertToRaid() calls.raid = calls.raid + 1 end
function Stopwatch_Toggle() calls.stopwatch = calls.stopwatch + 1 end

UIParent = newObject("Frame", "UIParent")
SlashCmdList = {}
Settings = nil
GameTooltip = {
  SetOwner = function() end,
  AddLine = function() end,
  Show = function() end,
  Hide = function() end,
}

function CreateFrame(objectType, name, parent, template)
  local frame = newObject(objectType, name, parent, template)
  if not eventFrame and not name then eventFrame = frame end
  return frame
end

local chunk = assert(loadfile("core.lua"))
chunk("RothRaidManager")
local onEvent = assert(eventFrame.scripts.OnEvent)
onEvent(eventFrame, "ADDON_LOADED", "RothRaidManager")
onEvent(eventFrame, "PLAYER_LOGIN")

local runtime = assert(_G.RothRaidManager_Runtime)
local manager = assert(runtime.GetManager())
assertEq(runtime.GetButtonCount(), 24, "button count")
assertEq(manager.template, "SecureHandlerStateTemplate,BackdropTemplate", "manager template")
assertEq(visibilityRegistrations, 1, "initial visibility driver")

for index = 1, 8 do
  local place = assert(namedFrames["RothRaidManagerWorldMarker" .. index])
  local clear = assert(namedFrames["RothRaidManagerWorldMarker" .. index .. "Clear"])
  assertEq(place.attributes.type, "macro", "world marker type")
  assertEq(place.attributes.macrotext, "/wm " .. index, "world marker macro")
  assertEq(clear.attributes.type, "macro", "clear marker type")
  assertEq(clear.attributes.macrotext, "/cwm " .. index, "clear marker macro")
end
assertEq(namedFrames.RothRaidManagerPull.attributes.macrotext, "/pull 10", "pull macro")

combat = true
now = 20
namedFrames.RothRaidManagerRoleCheck.scripts.OnClick()
namedFrames.RothRaidManagerReadyCheck.scripts.OnClick()
namedFrames.RothRaidManagerToParty.scripts.OnClick()
namedFrames.RothRaidManagerToRaid.scripts.OnClick()
namedFrames.RothRaidManagerClearAll.scripts.OnClick()
assertEq(calls.role, 0, "role poll ran in combat")
assertEq(calls.ready, 0, "ready check ran in combat")
assertEq(calls.party, 0, "party conversion ran in combat")
assertEq(calls.raid, 0, "raid conversion ran in combat")
assertEq(calls.clear, 0, "clear marker ran in combat")

combat = false
namedFrames.RothRaidManagerRoleCheck.scripts.OnClick()
namedFrames.RothRaidManagerReadyCheck.scripts.OnClick()
namedFrames.RothRaidManagerToParty.scripts.OnClick()
namedFrames.RothRaidManagerToRaid.scripts.OnClick()
namedFrames.RothRaidManagerClearAll.scripts.OnClick()
assertEq(calls.role, 1, "role poll out of combat")
assertEq(calls.ready, 1, "ready check out of combat")
assertEq(calls.party, 1, "party conversion out of combat")
assertEq(calls.raid, 1, "raid conversion out of combat")
assertEq(calls.clear, 1, "clear marker out of combat")

local oldScale, oldWidth, oldAlpha = manager.scale, manager.width, manager.alpha
RothRaidManagerDB.scale = 1.5
RothRaidManagerDB.expanded = true
combat = true
_G.RothRaidManager_Refresh()
assertEq(runtime.IsApplyPending(), true, "apply was not queued")
assertEq(manager.scale, oldScale, "scale changed in combat")
assertEq(manager.width, oldWidth, "width changed in combat")
assertEq(manager.alpha, oldAlpha, "alpha changed in combat")
assertEq(visibilityRegistrations, 1, "state driver changed in combat")

combat = false
onEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assertEq(runtime.IsApplyPending(), false, "pending apply did not clear")
assertEq(manager.scale, 1.5, "deferred scale")
assertEq(manager.width, 275, "deferred expanded width")
assertEq(manager.alpha, 1, "deferred expanded alpha")
assertEq(visibilityRegistrations, 2, "visibility driver was not reapplied")
assert(visibilityUnregistrations >= 1, "visibility driver was not unregistered before reapply")

combat = true
manager.scripts.OnDragStart(manager)
assertEq(manager.isMoving, nil, "drag started in combat")
combat = false
manager.scripts.OnDragStart(manager)
assertEq(manager.isMoving, nil, "locked manager started moving")
RothRaidManagerDB.locked = false
_G.RothRaidManager_Refresh()
manager.scripts.OnDragStart(manager)
assertEq(manager.isMoving, true, "unlocked manager did not start moving")

print("PASS: secure marker macros remain declarative, utility actions fail closed in combat, and panel apply is deferred")
