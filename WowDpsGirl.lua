local WDGConfig = {
   scale = 1.5,
   xOffset = -200,
   yOffset = 0,
   inactivityTime = 6,
   path = {
      bubble = "Interface\\AddOns\\WowDpsGirl\\bubble.tga",
      girl1 = "Interface\\AddOns\\WowDpsGirl\\girl1.tga",
      girl2 = "Interface\\AddOns\\WowDpsGirl\\girl2.tga",
      girlz = "Interface\\AddOns\\WowDpsGirl\\girlz.tga",
      girlb = "Interface\\AddOns\\WowDpsGirl\\girlb.tga",
   },
   needsUpdate = false,
}

WDG_SavedConfig = WDG_SavedConfig or {}

local mode = "dmg"
local SLEEPING = "ZZZzz"
local WDGFrame = CreateFrame("Frame", "WDGFrame", UIParent)
local myGUID = nil
local stats = {
   heal = {min = 0, max = 0, sum = 0, hits = 0, epoch_first = 0, epoch_last = 0},
   dmg = {min = 0, max = 0, sum = 0, hits = 0, epoch_first = 0, epoch_last = 0}
}

local function resetStats()
   stats = {
      heal = {min = 0, max = 0, sum = 0, hits = 0, epoch_first = 0, epoch_last = 0},
      dmg = {min = 0, max = 0, sum = 0, hits = 0, epoch_first = 0, epoch_last = 0}
   }
end

local function getInactivitySeconds()
   return time() - stats[mode].epoch_last
end

local function isInactive()
   return getInactivitySeconds() > WDGConfig.inactivityTime
end

local function incStats(dmgType, amount)
   local m = stats[dmgType]
   -- start of combat
   if m.epoch_first == 0 then
      m.epoch_first = time()
   end
   m.epoch_last = time()
   m.hits = m.hits + 1
   m.sum = m.sum + amount
   if amount > m.max then
      m.max = amount
   end
   if amount > m.min or m.min == 0 then
      m.min = amount
   end
end

local function getDps()
   local duration = max(stats[mode].epoch_last - stats[mode].epoch_first, 1)
   local dps = stats[mode].sum / duration

   -- if dps == 0 and isInactive() then
   if isInactive() then
      return SLEEPING
   end

   if dps > 1000 then
      return string.format("%.0f", dps/1000).."k"
   end

   return string.format("%.0f", dps)
end

local currentImage = 1

local function getTexture()
   local c = WDGConfig

   if getDps() == SLEEPING then
      return c.path.girlz
   end

   if math.random(0, 100) < 5 then
      return c.path.girlb
   end

   if currentImage == 1 then
      currentImage = 2
      return c.path.girl2
   else
      currentImage = 1
      return c.path.girl1
   end
end

local function getColor()
   if getDps() == SLEEPING then
      return {0, 0, 0}
   end
   if mode == "dmg" then
      return {1, 0, 0}
   else
      return {0, 1, 0}
   end
end

function showGirl()
   local c = WDGConfig

   -- bubble
   local myImageFrame2 = CreateFrame("Frame", nil, UIParent)
   myImageFrame2:SetSize(c.scale * 150, c.scale * 130)
   myImageFrame2:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", (-30 + c.xOffset) * c.scale, (65 + c.yOffset) * c.scale) -- Example positioning

   local myImageTexture2 = myImageFrame2:CreateTexture(nil, "ARTWORK")
   myImageTexture2:SetAllPoints(myImageFrame2)
   myImageTexture2:SetTexture(c.path.bubble)
   myImageTexture2:SetBlendMode("BLEND")
   myImageFrame2:Show()

   -- girl
   local myImageFrame1 = CreateFrame("Frame", nil, UIParent)
   -- myImageFrame1:SetSize(220, 241)
   myImageFrame1:SetSize(c.scale * 110, c.scale * 120)
   myImageFrame1:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", c.scale * c.xOffset, c.scale * c.yOffset) -- Example positioning

   local myImageTexture1 = myImageFrame1:CreateTexture(nil, "ARTWORK")
   myImageTexture1:SetAllPoints(myImageFrame1)
   myImageTexture1:SetTexture(c.path.girl1)
   myImageTexture1:SetBlendMode("BLEND")

   -- text
   local f = CreateFrame("Frame", nil, UIParent)
   f:SetSize(50, 30)
   f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", (-80 + c.xOffset) * c.scale, (120 + c.yOffset) * c.scale)

   local fs = f:CreateFontString(nil, "OVERLAY")
   fs:SetFont("Fonts\\ARIALN.TTF", 32, nil) -- OUTLINE third arg if wanted
   fs:SetTextColor(0, 0, 0)
   fs:SetText("OOPS")
   fs:SetPoint("CENTER", f, "CENTER")
   fs:SetRotation(math.rad(18))

   local function updateImage()
      local texture = getTexture()
      local dps = getDps()

      if (c.needsUpdate) then
         myImageFrame2:SetSize(c.scale * 150, c.scale * 130)
         myImageFrame1:SetSize(c.scale * 110, c.scale * 120)
         myImageFrame2:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", (-30 + c.xOffset) * c.scale, (65 + c.yOffset) * c.scale) -- Example positioning
         myImageFrame1:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", c.scale * c.xOffset, c.scale * c.yOffset) -- Example positioning
         f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", (-80 + c.xOffset) * c.scale, (120 + c.yOffset) * c.scale)
         c.needsUpdate = false
      end

      myImageFrame2:Hide()
      myImageFrame1:Hide()
      myImageTexture1:SetTexture(texture)
      myImageFrame2:Show()
      myImageFrame1:Show()
      fs:SetTextColor(unpack(getColor()))
      fs:SetText(dps)

      if isInactive() then
         resetStats()
      end
   end

   myImageFrame1:Show()
   local timer = C_Timer.NewTicker(0.1, updateImage) -- true makes it repeat
end

local function loadConfig ()
   mode = WDG_SavedConfig.mode or "dmg"
   WDGConfig.xOffset = WDG_SavedConfig.xOffset or -200
   WDGConfig.yOffset = WDG_SavedConfig.yOffset or 0
   WDGConfig.scale = WDG_SavedConfig.scale or 1.5
end

local function saveConfig ()
   WDG_SavedConfig.mode = mode
   WDG_SavedConfig.xOffset = WDGConfig.xOffset
   WDG_SavedConfig.yOffset = WDGConfig.yOffset
   WDG_SavedConfig.scale = WDGConfig.scale
end

-- Events
WDGFrame:RegisterEvent("ADDON_LOADED")
WDGFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
WDGFrame:RegisterEvent("PLAYER_LOGOUT")
WDGFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

WDGFrame:SetScript(
   "OnEvent",
   function(_, event, ...)
      if event == "ADDON_LOADED" then
         local addonName = ...
         if addonName == "WowDpsGirl" then
            mode = WDG_SavedConfig.mode or "dmg"
            -- WDG_SavedConfig.xOffset = WDGConfig.xOffset
            -- WDG_SavedConfig.yOffset = WDGConfig.yOffset
            -- WDG_SavedConfig.scale = WDGConfig.scale
         end

      elseif event == "PLAYER_ENTERING_WORLD" then
         myGUID = UnitGUID("player")
         resetStats()
         loadConfig()
         showGirl()

      elseif event == "PLAYER_LOGOUT" then
         saveConfig()

      elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
         local timestamp,
            subEvent,
            hideCaster,
            sourceGUID,
            sourceName,
            sourceFlags,
            sourceRaidFlags,
            destGUID,
            destName,
            destFlags,
            destRaidFlags,
            spellID,
            spellName,
            spellSchool,
            amount,
            overkill,
            school,
            resisted,
            blocked,
            absorbed,
            critical,
            glancing,
            crushing,
            isOffHand = CombatLogGetCurrentEventInfo()

         if sourceGUID ~= myGUID then
            return
         end

         if (subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL") and amount and amount > 0 then
            incStats("heal", amount)
         elseif tonumber(amount) and amount > 0 then
            incStats("dmg", amount)
         elseif subEvent == "SWING_DAMAGE" and amount == nil and spellID and spellID > 0 then
            incStats("dmg", spellID)
         end
      end
   end
)

local defaultFrame = DEFAULT_CHAT_FRAME
local defaultWrite = DEFAULT_CHAT_FRAME.AddMessage
local log = function(text, r, g, b, group, holdTime)
   defaultWrite(defaultFrame, tostring(text), r, g, b, group, holdTime)
end

local commands = setmetatable(
   {
      ["ax"] = function(arg)
         print("Adjusting x")
         WDGConfig.xOffset = WDGConfig.xOffset + arg
         WDGConfig.needsUpdate = true
         saveConfig()
      end,

      ["ay"] = function(arg)
         print("Adjusting y")
         WDGConfig.yOffset = WDGConfig.yOffset + arg
         WDGConfig.needsUpdate = true
         saveConfig()
      end,

      ["x"] = function(arg)
         print("Setting x")
         WDGConfig.xOffset = arg
         WDGConfig.needsUpdate = true
         saveConfig()
      end,

      ["y"] = function(arg)
         print("Setting y")
         WDGConfig.yOffset = arg
         WDGConfig.needsUpdate = true
         saveConfig()
      end,

      ["s"] = function(arg)
         print("Setting scale")
         WDGConfig.scale = arg
         WDGConfig.needsUpdate = true
         saveConfig()
      end,

      ["p"] = function(arg)
         print("Printing settings:")
         print("Scale: "..WDGConfig.scale)
         print("xOffset: "..WDGConfig.xOffset)
         print("yOffset: "..WDGConfig.yOffset)
      end,

      ["r"] = function(arg)
         print("Resetting customizations")
         WDGConfig.scale = 1.5
         WDGConfig.xOffset = -200
         WDGConfig.yOffset = 0
         WDGConfig.needsUpdate = true
         saveConfig()
      end,

      ["d"] = function(args)
         print("Enabling damage mode")
         mode = "dmg"
      end,

      ["h"] = function(args)
         print("Enabling heal mode")
         mode = "heal"
      end,
   }, {
      __index = function()
         return function()
            local dmgChosen = " |cff00ff33(active)."
            local healChosen = "."
            if mode == "heal" then
               dmgChosen = "."
               healChosen = " |cff00ff33(active)."
            end
            log("|cffff33cc[DpsGirl]|cffff9999 - Small DPS calculator")
            log("Commands:")
            log("  |cffff66cc/dg d|cffffffff - Enable damage mode"..dmgChosen)
            log("  |cffff66cc/dg h|cffffffff - Enable heal mode"..healChosen)
            log("  |cffff66cc/dg x|cffffffff - Set X")
            log("  |cffff66cc/dg y|cffffffff - Set Y")
            log("  |cffff66cc/dg ax|cffffffff - Adjust X")
            log("  |cffff66cc/dg ay|cffffffff - Adjust Y")
            log("  |cffff66cc/dg s|cffffffff - Set scale")
            log("  |cffff66cc/dg p|cffffffff - Print settings")
            log("  |cffff66cc/dg r|cffffffff - Reset settings")
         end
      end
})

SLASH_WDG1 = "/dpsgirl"
SLASH_WDG2 = "/wowdpsgirl"
SLASH_WDG3 = "/dg"
SLASH_WDG4 = "/wdg"
function SlashCmdList.WDG(args)
   if args then
      _, _, cmd, subargs = string.find(args, "^%s*(%S-)%s(.+)$")
      if not cmd then
         cmd = args
      end
      commands[string.lower(cmd)](subargs)
   else
      print("|cffff0000[DPSGIRL]: Unknown option|r")
   end
end
