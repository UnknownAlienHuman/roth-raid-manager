local combat = true
local secureCreates = 0
local attributeWrites = 0
local eventFrame
local frames = {}
local SECRET = setmetatable({}, {
  __tostring = function() error("secret stringified") end,
  __eq = function() error("secret compared") end,
  __index = function() error("secret indexed") end,
})

local function assertEq(actual, expected, message)
  if actual ~= expected then error((message or "assert") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2) end
end

local function newObject(name, parent, template)
  local object = {
    name = name, parent = parent, template = template, scripts = {}, events = {}, attributes = {},
    point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, shown = true,
  }
  function object:RegisterEvent(event) self.events[event] = true end
  function object:SetScript(script, callback) self.scripts[script] = callback end
  function object:SetSize(w, h) self.width, self.height = w, h end
  function object:SetWidth(w) self.width = w end
  function object:SetHeight(h) self.height = h end
  function object:SetFrameStrata(v) self.strata = v end
  function object:SetClampedToScreen(v) self.clamped = v end
  function object:SetClampRectInsets(...) self.insets = { ... } end
  function object:SetBackdrop(v) self.backdrop = v end
  function object:SetBackdropColor(...) self.bg = { ... } end
  function object:SetBackdropBorderColor(...) self.border = { ... } end
  function object:SetMovable(v) self.movable = v end
  function object:RegisterForDrag(...) self.drag = { ... } end
  function object:EnableMouse(v) self.mouse = v end
  function object:SetScale(v) self.scale = v end
  function object:SetAlpha(v) self.alpha = v end
  function object:SetText(v) self.text = v end
  function object:ClearAllPoints() self.point = nil end
  function object:SetPoint(point, relativeTo, relativePoint, x, y)
    if type(relativeTo) == "number" then x, y, relativeTo, relativePoint = relativeTo, relativePoint, self.parent, point end
    self.point, self.relativeTo, self.relativePoint, self.x, self.y = point, relativeTo, relativePoint, x or 0, y or 0
  end
  function object:GetPoint() return self.point, self.relativeTo, self.relativePoint, self.x, self.y end
  function object:SetAttribute(key, value)
    if combat then error("attribute write in combat") end
    attributeWrites = attributeWrites + 1
    self.attributes[key] = value
  end
  function object:CreateTexture()
    local texture = newObject(nil, self)
    function texture:SetAllPoints(v) self.allPoints = v end
    function texture:SetColorTexture(...) self.color = { ... } end
    return texture
  end
  function object:StartMoving() self.moving = true end
  function object:StopMovingOrSizing() self.moving = false end
  function object:Show() self.shown = true end
  function object:Hide() self.shown = false end
  return object
end

function canaccessvalue(value) return not rawequal(value, SECRET) end
function issecretvalue(value) return rawequal(value, SECRET) end
function issecrettable(value) return rawequal(value, SECRET) end
function InCombatLockdown() return combat end
function GetTime() return 1 end
function IsAltKeyDown() return true end
function IsControlKeyDown() return true end
function RegisterStateDriver(frame, state, driver) if combat then error("driver in combat") end; frame.driver = driver end
function UnregisterStateDriver(frame) if combat then error("driver in combat") end; frame.driver = nil end
function CreateFrame(_, name, parent, template)
  if combat and type(template) == "string" and template:find("Secure", 1, true) then error("secure create in combat") end
  if type(template) == "string" and template:find("Secure", 1, true) then secureCreates = secureCreates + 1 end
  local frame = newObject(name, parent, template)
  frames[#frames + 1] = frame
  if name then _G[name] = frame elseif not eventFrame then eventFrame = frame end
  return frame
end

DEFAULT_CHAT_FRAME = { AddMessage = function() end }
UIParent = newObject("UIParent")
SlashCmdList = {}
Settings = nil
GameTooltip = { SetOwner=function() end, AddLine=function() end, Show=function() end, Hide=function() end }

RothRaidManagerDB = {
  enabled = true, locked = true, scale = 1,
  pos = { point = "BROKEN", relPoint = SECRET, x = 9999, y = -9999 },
}

assert(loadfile("core.lua"))("RothRaidManager")
local runtime = assert(_G.RothRaidManager_Runtime)
local onEvent = assert(eventFrame.scripts.OnEvent)

local okLoaded, errorLoaded = pcall(onEvent, eventFrame, "ADDON_LOADED", "RothRaidManager")
assertEq(okLoaded, true, "load failed: " .. tostring(errorLoaded))
local db = runtime.GetDB()
assertEq(db.pos.point, "LEFT", "point sanitization")
assertEq(db.pos.relPoint, "LEFT", "relative point sanitization")
assertEq(db.pos.x, 4000, "x clamp")
assertEq(db.pos.y, -4000, "y clamp")

local okLogin, errorLogin = pcall(onEvent, eventFrame, "PLAYER_LOGIN")
assertEq(okLogin, true, "combat login failed: " .. tostring(errorLogin))
assertEq(runtime.GetManager(), nil, "manager created in combat")
assertEq(runtime.IsInitializePending(), true, "pending init missing")
assertEq(secureCreates, 0, "secure frame created in combat")
assertEq(attributeWrites, 0, "attribute written in combat")

combat = false
onEvent(eventFrame, "PLAYER_REGEN_ENABLED")
local manager = assert(runtime.GetManager())
assertEq(runtime.IsInitializePending(), false, "pending init not cleared")
assertEq(runtime.IsInitialized(), true, "not initialized")
assertEq(runtime.GetButtonCount(), 24, "button count")
assertEq(manager.point, "LEFT", "sanitized point not applied")
assertEq(manager.relativePoint, "LEFT", "sanitized relative point not applied")
assertEq(attributeWrites, 34, "unexpected declarative attribute count")
local fixedWrites = attributeWrites

combat = true
RothRaidManagerDB.scale = 1.5
runtime.Apply()
assertEq(runtime.IsApplyPending(), true, "apply not deferred")
assertEq(attributeWrites, fixedWrites, "attributes rewritten in combat")
combat = false
onEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assertEq(runtime.IsApplyPending(), false, "apply flag not cleared")
assertEq(attributeWrites, fixedWrites, "attributes rewritten after apply")

local secretOK, secretError = pcall(SlashCmdList.ROTHRAIDMANAGER, SECRET)
assertEq(secretOK, true, "secret slash escaped boundary: " .. tostring(secretError))

print("PASS: secure initialization defers from combat, anchors sanitize, and attributes remain immutable")
