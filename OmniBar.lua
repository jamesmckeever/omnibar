local addonName, addon = ...

local COMBATLOG_FILTER_STRING_UNKNOWN_UNITS = COMBATLOG_FILTER_STRING_UNKNOWN_UNITS
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local C_Timer_After = C_Timer.After
local CanInspect = CanInspect
local ClearInspectPlayer = ClearInspectPlayer
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CreateFrame = CreateFrame
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local GetArenaOpponentSpec = GetArenaOpponentSpec
local GetBattlefieldScore = GetBattlefieldScore
local GetClassInfo = GetClassInfo
local GetInspectSpecialization = GetInspectSpecialization
local GetNumBattlefieldScores = GetNumBattlefieldScores
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSpecializationsForClassID = GetNumSpecializationsForClassID
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetRaidRosterInfo = GetRaidRosterInfo
local GetServerTime = GetServerTime
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpecializationInfoByID = GetSpecializationInfoByID
local GetSpecializationInfoForClassID = GetSpecializationInfoForClassID
local GetSpellInfo = C_Spell and C_Spell.GetSpellInfo or GetSpellInfo
local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
local GetTime = GetTime
local GetUnitName = GetUnitName
local GetZonePVPInfo = GetZonePVPInfo
local InCombatLockdown = InCombatLockdown
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsRatedBattleground = C_PvP.IsRatedBattleground
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local LibStub = LibStub
local MAX_CLASSES = MAX_CLASSES
local NotifyInspect = NotifyInspect
local SlashCmdList = SlashCmdList
local UIParent = UIParent
local UNITNAME_SUMMON_TITLE1 = UNITNAME_SUMMON_TITLE1
local UNITNAME_SUMMON_TITLE2 = UNITNAME_SUMMON_TITLE2
local UNITNAME_SUMMON_TITLE3 = UNITNAME_SUMMON_TITLE3
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsPlayer = UnitIsPlayer
local UnitIsPossessed = UnitIsPossessed
local UnitIsUnit = UnitIsUnit
local UnitReaction = UnitReaction
local WOW_PROJECT_CLASSIC = WOW_PROJECT_CLASSIC
local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE
local bit_band = bit.band
local date = date
local tinsert = tinsert
local wipe = wipe
local tContains = tContains
local IsRatedBattleground = C_PvP.IsRatedBattleground
local IsSoloShuffle = C_PvP and C_PvP.IsSoloShuffle
local GetSoloShuffleActiveRound = C_PvP and C_PvP.GetSoloShuffleActiveRound


local CHANNELED_SPELLS = {
    [382445] = true,

}




local function GetSpellName(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id)
    else
        return GetSpellInfo(id)
    end
end

OmniBar = LibStub("AceAddon-3.0"):NewAddon("OmniBar", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OmniBar")


for k, v in pairs(addon.Cooldowns) do
    if v.duration and type(v.duration) == "number" then
        local adjust = v.adjust or 0
        if type(adjust) == "table" then
            adjust = adjust.default or 0
        end
        addon.Cooldowns[k].duration = v.duration + adjust
    end
end

addon.CooldownReduction = {}
OmniBar.activeChannels = {}


OmniBar.debugEvents = {}
local CLASS_ORDER = {
    ["GENERAL"] = 0,
    ["DEMONHUNTER"] = 1,
    ["DEATHKNIGHT"] = 2,
    ["PALADIN"] = 3,
    ["WARRIOR"] = 4,
    ["DRUID"] = 5,
    ["PRIEST"] = 6,
    ["WARLOCK"] = 7,
    ["SHAMAN"] = 8,
    ["HUNTER"] = 9,
    ["MAGE"] = 10,
    ["ROGUE"] = 11,
    ["MONK"] = 12,
    ["EVOKER"] = 13,
}

local ARENA_STATE = {
    inArena = false,
    inActiveCombat = false,
    inPrep = false,
    stealthEvents = {},
    lastStealthTime = 0,
    stealthProtection = false,
    lastShuffleRound = 0



}
local MAX_ARENA_SIZE = addon.MAX_ARENA_SIZE or 0

local PLAYER_NAME = GetUnitName("player")

local DEFAULTS = {
    adaptive          = false,
    align             = "CENTER",
    arena             = true,
    battleground      = true,
    border            = true,
    center            = false,
    columns           = 8,
    cooldownCount     = true,
    glow              = true,
    growUpward        = true,
    highlightFocus    = false,
    highlightTarget   = true,
    locked            = false,
    maxIcons          = 32,
    multiple          = true,
    names             = false,
    padding           = 2,
    ratedBattleground = true,
    scenario          = true,
    showUnused        = false,
    size              = 40,
    sortMethod        = "player",
    swipeAlpha        = 0.65,
    tooltips          = true,
    trackUnit         = "ENEMY",
    unusedAlpha       = 0.45,
    usedAlpha         = 1.0,
    world             = true,
}




local DB_VERSION = 4

local MAX_DUPLICATE_ICONS = 5

local BASE_ICON_SIZE = 36

function OmniBar:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99OmniBar|r: " .. message)
end

function OmniBar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("OmniBarDB", {
        global = {
            version = DB_VERSION,
            cooldowns = {},
            cooldownReduction = {}
        },
        profile = { bars = {} }
    }, true)

    ARENA_STATE = ARENA_STATE or {}
    ARENA_STATE.lastPrepEvent = ARENA_STATE.lastPrepEvent or 0
    self.arenaInitialized = false

    self.arenaSpecs = {}
    self.arenaSpecsAttempts = 0
    self.arenaSpecsInitialized = false
    self.cooldowns = addon.Cooldowns
    self.bars = {}
    self.specs = {}
    self.spellCasts = {}
    self.inArena = false
    self.arenaSpecMap = {}
    self.db.RegisterCallback(self, "OnProfileChanged", "OnEnable")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnEnable")
    self.db.RegisterCallback(self, "OnProfileReset", "OnEnable")


    self:RegisterEvent("PLAYER_ENTERING_WORLD", "ResetArenaSpecs")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", "ResetArenaSpecs")

    self:RegisterEvent("ARENA_OPPONENT_UPDATE", "RefreshArenaSpecs")

    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "GetSpecs")
    self:RegisterComm("OmniBarSpell", function(_, payload, _, sender)
        if (not UnitExists(sender)) or sender == PLAYER_NAME then return end
        local success, event, sourceGUID, sourceName, sourceFlags, spellID, serverTime = self:Deserialize(payload)
        if (not success) then return end
        self:AddSpellCast(event, sourceGUID, sourceName, sourceFlags, spellID, serverTime)
    end)

    local version, major, minor = C_AddOns.GetAddOnMetadata(addonName, "Version") or "", 0, 0
    if version:sub(1, 1) == "@" then
        version = "Development"
    else
        major, minor = version:match("v(%d+)%.?(%d*)")
    end
    self.version = setmetatable({
        string = version,
        major = tonumber(major),
        minor = tonumber(minor) or 0,
    }, {
        __tostring = function()
            return version
        end
    })


    if self.version.major > 0 then
        self:RegisterComm("OmniBarVersion", "ReceiveVersion")
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "SendVersion")
        C_Timer_After(10, function()
            self:SendVersion()
            if IsInGuild() then self:SendVersion("GUILD") end
            self:SendVersion("YELL")
        end)
    end


    for k, v in pairs(self.db.global.cooldowns) do
        if (not GetSpellInfo(k)) then
            self.db.global.cooldowns[k] = nil
        end
    end


    for spellId, _ in pairs(self.cooldowns) do
        local name, icon
        if C_Spell and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(spellId)
            name = spellInfo and spellInfo.name
            icon = spellInfo and spellInfo.iconID
        else
            name, _, icon = GetSpellInfo(spellId)
        end
        self.cooldowns[spellId].icon = self.cooldowns[spellId].icon or icon
        self.cooldowns[spellId].name = name
    end
    for triggerID, reductions in pairs(self.db.global.cooldownReduction) do
        addon.CooldownReduction[tonumber(triggerID)] = {}
        for targetID, amount in pairs(reductions) do
            addon.CooldownReduction[tonumber(triggerID)][tonumber(targetID)] = amount
        end
    end

    if not self.db.global.cooldownReduction[2139] then
        self.db.global.cooldownReduction[2139] = {}
    end
    if not self.db.global.cooldownReduction[2139][2139] then
        self.db.global.cooldownReduction[2139][2139] = {
            amount = 4,
            event = "SPELL_INTERRUPT"
        }
    end












    for spellID, spellData in pairs(addon.Cooldowns) do
        if spellData.class == "MAGE" and spellData.duration and not spellData.parent then
            if not self.db.global.cooldownReduction[382445] then
                self.db.global.cooldownReduction[382445] = {}
            end


            if not self.db.global.cooldownReduction[382445][spellID] then
                self.db.global.cooldownReduction[382445][spellID] = {
                    amount = 3,
                    event = "SPELL_CAST_SUCCESS"
                }
            end


            if not addon.CooldownReduction[382445] then
                addon.CooldownReduction[382445] = {}
            end
            addon.CooldownReduction[382445][spellID] = {
                amount = 3,
                event = "SPELL_CAST_SUCCESS"
            }
        end
    end

    addon.CooldownReduction[2139] = addon.CooldownReduction[2139] or {}
    addon.CooldownReduction[2139][2139] = {
        amount = 4,
        event = "SPELL_INTERRUPT"
    }
    self:SetupOptions()
end

local function ShouldPreventReset()
    if ARENA_STATE.inArena and ARENA_STATE.inActiveCombat and not ARENA_STATE.inPrep then
        return true
    end


    if ARENA_STATE.stealthProtection or
        (GetTime() - ARENA_STATE.lastStealthTime < 3.0) then
        return true
    end


    for unit, event in pairs(ARENA_STATE.stealthEvents) do
        if GetTime() - event.time < 5.0 then
            return true
        end
    end

    return false
end


local function SafeRefresh(self)
    if ShouldPreventReset() then
        OmniBar_UpdateAllBorders(self)
        return false
    end
    return true
end
local function UpdateArenaState()
    local inInstance, instanceType = IsInInstance()
    local wasInArena = ARENA_STATE.inArena

    ARENA_STATE.inArena = (inInstance and instanceType == "arena")

    if wasInArena and not ARENA_STATE.inArena then
        ARENA_STATE.inActiveCombat = false
        ARENA_STATE.inPrep = false
        ARENA_STATE.stealthEvents = {}
        ARENA_STATE.stealthProtection = false
    end

    if ARENA_STATE.inArena then
        if C_PvP and C_PvP.IsInArenaMatch then
            local inMatch = C_PvP.IsInArenaMatch()
            local inPrep = not inMatch
            local prepChanged = ARENA_STATE.inPrep ~= inPrep

            ARENA_STATE.inPrep = inPrep


            if prepChanged and not inPrep then
                ARENA_STATE.inActiveCombat = true
            end
        end
    end

    return ARENA_STATE.inArena
end


local function SaveCooldownStates(self)
    if not ARENA_STATE.inArena then return {} end

    local cooldownStates = {}
    for i, icon in ipairs(self.active) do
        if icon.spellID and icon:IsVisible() then
            local remainingTime = icon.cooldown and icon.cooldown.finish and
                (icon.cooldown.finish - GetTime()) or 0

            local key = tostring(icon.spellID) .. "-" .. tostring(icon.sourceGUID)
            cooldownStates[key] = {
                charges = icon.charges,
                remainingTime = remainingTime > 0 and remainingTime or 0,
                sourceGUID = icon.sourceGUID,
                sourceName = icon.sourceName,
                spellID = icon.spellID
            }
        end
    end

    return cooldownStates
end


local function RestoreCooldownStates(self, cooldownStates)
    if not cooldownStates or next(cooldownStates) == nil then return end

    for i, icon in ipairs(self.active) do
        local key = tostring(icon.spellID) .. "-" .. tostring(icon.sourceGUID)
        local state = cooldownStates[key]

        if state and state.remainingTime > 0 then
            icon.cooldown:Show()
            OmniBar_StartCooldown(self, icon, GetTime())
            icon.cooldown.finish = GetTime() + state.remainingTime


            if state.charges ~= nil then
                icon.charges = state.charges
                icon.Count:SetText(state.charges > 0 and state.charges or "")
            end
        end
    end
end


local function GetDefaultCommChannel()
    if IsInRaid() then
        return IsInRaid(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "RAID"
    elseif IsInGroup() then
        return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
    elseif IsInGuild() then
        return "GUILD"
    else
        return "YELL"
    end
end

function OmniBar:ReceiveVersion(_, payload, _, sender)
    self.sender = sender
    if (not payload) or type(payload) ~= "string" then return end
    local major, minor = payload:match("v(%d+)%.?(%d*)")
    major = tonumber(major)
    minor = tonumber(minor) or 0
    if (not major) or (not minor) then return end
    if major < self.version.major then return end
    if major == self.version.major and minor <= self.version.minor then return end
    if (not self.outdatedSender) or self.outdatedSender == sender then
        self.outdatedSender = sender
        return
    end
    if self.nextWarn and self.nextWarn > GetTime() then return end
    self.nextWarn = GetTime() + 1800
    self:Print(L.UPDATE_AVAILABLE)
    self.outdatedSender = nil
end

function OmniBar:SendVersion(distribution)
    if (not self.version) or self.version.major == 0 then return end
    self:SendCommMessage("OmniBarVersion", self.version.string, distribution or GetDefaultCommChannel())
end

function OmniBar:OnEnable()
    wipe(self.specs)
    wipe(self.spellCasts)

    self.index = 1

    for i = #self.bars, 1, -1 do
        self:Delete(self.bars[i].key, true)
        table.remove(self.bars, i)
    end

    for key, _ in pairs(self.db.profile.bars) do
        self:Initialize(key)
        self.index = self.index + 1
    end


    if self.index == 1 then
        self:Initialize("OmniBar1", "OmniBar")
        self.index = 2
    end

    for key, _ in pairs(self.db.profile.bars) do
        self:AddBarToOptions(key)
    end


    self:GetSpecs()


    C_Timer.After(0.1, function()
        self:Refresh(true)
    end)
end

function OmniBar_Refresh(self)
    if not SafeRefresh(self) then return end


    OmniBar_ResetIcons(self)
    OmniBar_ReplaySpellCasts(self)
end

function OmniBar:Decode(encoded)
    local LibDeflate = LibStub:GetLibrary("LibDeflate")
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if (not decoded) then return self:ImportError("DecodeForPrint") end
    local decompressed = LibDeflate:DecompressZlib(decoded)
    if (not decompressed) then return self:ImportError("DecompressZlib") end
    local success, deserialized = self:Deserialize(decompressed)
    if (not success) then return self:ImportError("Deserialize") end
    return deserialized
end

function OmniBar:ExportProfile()
    local LibDeflate = LibStub:GetLibrary("LibDeflate")
    local data = {
        profile = self.db.profile,
        customSpells = self.db.global.cooldowns,
        version = 1
    }
    local serialized = self:Serialize(data)
    if (not serialized) then return end
    local compressed = LibDeflate:CompressZlib(serialized)
    if (not compressed) then return end
    return LibDeflate:EncodeForPrint(compressed)
end

function OmniBar:ImportError(message)
    if (not message) or self.import.editBox.editBox:GetNumLetters() == 0 then
        self.import.statustext:SetTextColor(1, 0.82, 0)
        self.import:SetStatusText(L["Paste a code to import an OmniBar profile."])
    else
        self.import.statustext:SetTextColor(1, 0, 0)
        self.import:SetStatusText(L["Import failed (%s)"]:format(message))
    end
    self.import.button:SetDisabled(true)
end

function OmniBar:ImportProfile(data)
    if (data.version ~= 1) then return self:ImportError(L["Invalid version"]) end

    local profile = L["Imported (%s)"]:format(date())

    self.db.profiles[profile] = data.profile
    self.db:SetProfile(profile)


    for k, v in pairs(data.customSpells) do
        self.db.global.cooldowns[k] = nil
        self.options.args.customSpells.args.spellId.set(nil, k, v)
    end

    self:OnEnable()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("OmniBar")
    return true
end

function OmniBar:ShowExport()
    self.export.editBox:SetText(self:ExportProfile())
    self.export:Show()
    self.export.editBox:SetFocus()
    self.export.editBox:HighlightText()
end

function OmniBar:ShowImport()
    self.import.editBox:SetText("")
    self:ImportError()
    self.import:Show()
    self.import.button:SetDisabled(true)
    self.import.editBox:SetFocus()
end

function OmniBar:Delete(key, keepProfile)
    local bar = _G[key]
    if (not bar) then return end
    bar:UnregisterEvent("PLAYER_ENTERING_WORLD")
    bar:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    bar:UnregisterEvent("PLAYER_TARGET_CHANGED")
    bar:UnregisterEvent("PLAYER_REGEN_DISABLED")
    bar:UnregisterEvent("GROUP_ROSTER_UPDATE")
    bar:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
    if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
        bar:UnregisterEvent("PLAYER_FOCUS_CHANGED")
        bar:UnregisterEvent("ARENA_OPPONENT_UPDATE")
    end
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        bar:UnregisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
        bar:UnregisterEvent("UPDATE_BATTLEFIELD_STATUS")
        bar:UnregisterEvent("PVP_MATCH_ACTIVE")
    end
    bar:Hide()
    if (not keepProfile) then self.db.profile.bars[key] = nil end
    self.options.args.bars.args[key] = nil
    LibStub("AceConfigRegistry-3.0"):NotifyChange("OmniBar")
end

OmniBar.BackupCooldowns = {}

function OmniBar:CopyCooldown(cooldown)
    local copy = {}

    for _, v in pairs({ "class", "charges", "parent", "name", "icon" }) do
        if cooldown[v] then
            copy[v] = cooldown[v]
        end
    end

    if cooldown.duration then
        if type(cooldown.duration) == "table" then
            copy.duration = {}
            for k, v in pairs(cooldown.duration) do
                copy.duration[k] = v
            end
        else
            copy.duration = { default = cooldown.duration }
        end
    end

    if cooldown.specID then
        copy.specID = {}
        for i = 1, #cooldown.specID do
            table.insert(copy.specID, cooldown.specID[i])
        end
    end

    return copy
end

SLASH_OBARENA1 = "/obarena"
SlashCmdList.OBARENA = function()
    print("OmniBar Arena State:")
    print("In Arena: " .. tostring(ARENA_STATE.inArena))
    print("In Prep: " .. tostring(ARENA_STATE.inPrep))
    print("Active Combat: " .. tostring(ARENA_STATE.inActiveCombat))
    print("Stealth Protection: " .. tostring(ARENA_STATE.stealthProtection))
    print("Last Stealth: " .. string.format("%.1f seconds ago", GetTime() - ARENA_STATE.lastStealthTime))
    print("Last Prep Event: " .. string.format("%.1f seconds ago", GetTime() - ARENA_STATE.lastPrepEvent))


    print("Detected Specs:")
    for i = 1, MAX_ARENA_SIZE do
        local specID = GetArenaOpponentSpec(i)
        if specID and specID > 0 then
            local _, name, _, _, _, class = GetSpecializationInfoByID(specID)
            print(string.format("Arena%d: %s (%s) - ID: %d", i, name or "Unknown", class or "Unknown", specID))
        else
            print(string.format("Arena%d: No spec detected", i))
        end
    end

    print("Stealth Events:")
    for unit, event in pairs(ARENA_STATE.stealthEvents) do
        print(string.format("Arena%d: %s (%.1f seconds ago)",
            unit, event.type, GetTime() - event.time))
    end
end

function OmniBar_ArenaAddIcon(self, info)
    if not self.inArena then
        return OmniBar_AddIcon(self, info)
    end


    if not OmniBar_IsSpellEnabled(self, info.spellID) then return end


    local spellClass = addon.Cooldowns[info.spellID].class
    local requiresSpec = addon.Cooldowns[info.spellID].specID ~= nil


    if spellClass == "GENERAL" then
        return OmniBar_AddIcon(self, info)
    end


    if info.sourceGUID and type(info.sourceGUID) == "number" then
        local arenaIndex = info.sourceGUID
        local specID = info.specID or self.arenaSpecMap[arenaIndex]


        if requiresSpec and specID and specID > 0 then
            local matchesSpec = false
            for i = 1, #addon.Cooldowns[info.spellID].specID do
                if addon.Cooldowns[info.spellID].specID[i] == specID then
                    matchesSpec = true
                    break
                end
            end


            if matchesSpec then
                return OmniBar_AddIcon(self, info)
            else
                return nil
            end
        elseif not requiresSpec then
            return OmniBar_AddIcon(self, info)
        end
    end


    if not self.inArena then
        return OmniBar_AddIcon(self, info)
    end

    return nil
end

function OmniBar:ResetArenaSpecs(force)
    UpdateArenaState()


    if not force and ShouldPreventReset() then return end

    wipe(self.arenaSpecs)
    self.arenaSpecsAttempts = 0
    self.arenaSpecsInitialized = false
    OmniBar.arenaInitialized = false


    if force or (self.inArena and not ShouldPreventReset()) then
        for _, bar in ipairs(self.bars) do
            if not bar.disabled and bar.inArena then
                C_Timer.After(0.5, function()
                    ForceArenaIconInitialization(bar)
                end)
            end
        end
    end
end

local SPELL_ID_BY_NAME
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    SPELL_ID_BY_NAME = {}
    for id, value in pairs(addon.Cooldowns) do
        if (not value.parent) then SPELL_ID_BY_NAME[GetSpellName(id)] = id end
    end
end

function OmniBar:AddCustomSpells()
    for k, v in pairs(self.BackupCooldowns) do
        addon.Cooldowns[k] = self:CopyCooldown(v)
    end


    for k, v in pairs(self.db.global.cooldowns) do
        local name, _, icon
        if C_Spell and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(k)
            name = spellInfo and spellInfo.name
            icon = spellInfo and spellInfo.iconID
        else
            name, _, icon = GetSpellInfo(k)
        end
        if name then
            if addon.Cooldowns[k] and (not addon.Cooldowns[k].custom) and (not self.BackupCooldowns[k]) then
                self.BackupCooldowns[k] = self:CopyCooldown(addon.Cooldowns[k])
            end
            addon.Cooldowns[k] = v
            addon.Cooldowns[k].icon = addon.Cooldowns[k].icon or icon
            addon.Cooldowns[k].name = name
            if SPELL_ID_BY_NAME then SPELL_ID_BY_NAME[name] = k end
        else
            self.db.global.cooldowns[k] = nil
        end
    end
end

local function OmniBar_IsAdaptive(self)
    if self.settings.adaptive then return true end


    if self.zone == "arena" then return true end


    if self.settings.trackUnit ~= "ENEMY" then return true end
end

function OmniBar_SpellCast(self, event, name, spellID)
    if self.disabled then return end



    OmniBar_AddIcon(self, self.spellCasts[name][spellID])
end

function OmniBar:Initialize(key, name)
    if (not self.db.profile.bars[key]) then
        self.db.profile.bars[key] = { name = name }
        for a, b in pairs(DEFAULTS) do
            self.db.profile.bars[key][a] = b
        end
    end

    self:AddCustomSpells()

    local f = _G[key] or CreateFrame("Frame", key, UIParent, "OmniBarTemplate")
    f:Show()
    f.settings = self.db.profile.bars[key]
    f.settings.align = f.settings.align or "CENTER"
    f.settings.maxIcons = f.settings.maxIcons or DEFAULTS.maxIcons
    f.key = key
    f.icons = {}
    f.active = {}
    f.detected = {}
    f.spellCasts = self.spellCasts
    f.specs = self.specs
    f.BASE_ICON_SIZE = BASE_ICON_SIZE
    f.numIcons = 0
    f:RegisterForDrag("LeftButton")
    f.sortKeys = {}
    f.sortKeysAssigned = nil
    f.forceResort = nil
    f.frozenOrder = nil

    f.anchor.text:SetText(f.settings.name)


    f.settings.units = nil
    if (not f.settings.trackUnit) then f.settings.trackUnit = "ENEMY" end


    if f.settings.spells then
        for k, _ in pairs(f.settings.spells) do
            if (not addon.Cooldowns[k]) or addon.Cooldowns[k].parent then f.settings.spells[k] = nil end
        end
    end

    f.adaptive = OmniBar_IsAdaptive(f)


    for k, v in pairs(f.settings) do
        local spellID = tonumber(k:match("^spell(%d+)"))
        if spellID then
            if (not f.settings.spells) then
                f.settings.spells = {}
                if (not f.settings.noDefault) then
                    for k, v in pairs(addon.Cooldowns) do
                        if v.default then f.settings.spells[k] = true end
                    end
                end
            end
            f.settings.spells[spellID] = v
            f.settings[k] = nil
        end
    end
    f.settings.noDefault = nil


    OmniBar_LoadSettings(f)


    for spellID, _ in pairs(addon.Cooldowns) do
        if OmniBar_IsSpellEnabled(f, spellID) then
            OmniBar_CreateIcon(f)
        end
    end


    for i = 1, MAX_DUPLICATE_ICONS do
        OmniBar_CreateIcon(f)
    end

    OmniBar_ShowAnchor(f)
    OmniBar_ResetIcons(f)
    OmniBar_UpdateIcons(f)
    OmniBar_Center(f)

    f.OnEvent = OmniBar_OnEvent

    f:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
    f:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
    f:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
    f:RegisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")

    if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
        f:RegisterEvent("PLAYER_FOCUS_CHANGED", "OnEvent")
        f:RegisterEvent("ARENA_OPPONENT_UPDATE", "OnEvent")
    end

    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        f:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", "OnEvent")
        f:RegisterEvent("UPDATE_BATTLEFIELD_STATUS", "OnEvent")
        f:RegisterEvent("PVP_MATCH_ACTIVE", "OnEvent")
    end

    f:RegisterEvent("UPDATE_BATTLEFIELD_SCORE", "OnEvent")

    table.insert(self.bars, f)
end

function OmniBar:Create()
    while true do
        local key = "OmniBar" .. self.index
        self.index = self.index + 1
        if (not self.db.profile.bars[key]) then
            self:Initialize(key, "OmniBar " .. (self.index - 1))
            self:AddBarToOptions(key, true)
            self:OnEnable()
            return
        end
    end
end

function OmniBar:Refresh(full)
    self:GetSpecs()
    for key, _ in pairs(self.db.profile.bars) do
        local f = _G[key]
        if f then
            f.container:SetScale(f.settings.size / BASE_ICON_SIZE)
            if full then
                f.adaptive = OmniBar_IsAdaptive(f)
                OmniBar_OnEvent(f, "PLAYER_ENTERING_WORLD")
                OmniBar_OnEvent(f, "PLAYER_TARGET_CHANGED")
                OmniBar_OnEvent(f, "PLAYER_FOCUS_CHANGED")
                OmniBar_OnEvent(f, "GROUP_ROSTER_UPDATE")
            else
                OmniBar_LoadPosition(f)
                OmniBar_UpdateIcons(f)
                OmniBar_Center(f)
            end
        end
    end
end

local Masque = LibStub and LibStub("Masque", true)


local SPEC_ID_BY_NAME = {}
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    for classID = 1, MAX_CLASSES do
        local _, classToken = GetClassInfo(classID)
        SPEC_ID_BY_NAME[classToken] = {}
        for i = 1, GetNumSpecializationsForClassID(classID) do
            local id, name = GetSpecializationInfoForClassID(classID, i)
            SPEC_ID_BY_NAME[classToken][name] = id
        end
    end
end

local function UnitIsHostile(unit)
    if (not unit) then return end
    if UnitIsUnit("player", unit) then return end
    local reaction = UnitReaction("player", unit)
    if (not reaction) then return end
    return UnitIsPlayer(unit) and reaction < 4 and (not UnitIsPossessed(unit))
end

function OmniBar_ShowAnchor(self)
    if self.disabled or self.settings.locked or #self.active > 0 then
        self.anchor:Hide()
    else
        local width = self.anchor.text:GetWidth() + 29
        self.anchor:SetSize(width, 30)
        self.anchor:Show()
    end
end

function OmniBar_CreateIcon(self)
    if InCombatLockdown() then return end
    self.numIcons = self.numIcons + 1
    local name = self:GetName()
    local key = name .. "Icon" .. self.numIcons
    local f = _G[key] or CreateFrame("Button", key, _G[name .. "Icons"], "OmniBarButtonTemplate")


    if not f.borderTop then
        f.borderTop = f:CreateTexture(nil, "OVERLAY")
        f.borderBottom = f:CreateTexture(nil, "OVERLAY")
        f.borderLeft = f:CreateTexture(nil, "OVERLAY")
        f.borderRight = f:CreateTexture(nil, "OVERLAY")
    end

    table.insert(self.icons, f)
end

local function SpellBelongsToSpec(spellID, specID)
    if not addon.Cooldowns[spellID].specID then return true end


    if not specID or specID == 0 then
        return true
    end


    for i = 1, #addon.Cooldowns[spellID].specID do
        if addon.Cooldowns[spellID].specID[i] == specID then return true end
    end

    return false
end
local SPECIFIC_SPELL_ID = 32727
function HasSpecificBuff()
    local i = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source,
        isStealable, nameplateShowPersonal, spellId = UnitBuff("player", i)

        if not name then break end

        if spellId == SPECIFIC_SPELL_ID then
            return true
        end
        i = i + 1
    end

    return false
end

function OmniBar:RefreshArenaSpecs(event)
    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then return end


    UpdateArenaState()
    local roundChanged = false
    if HasSpecificBuff() then
        roundChanged = true
    end

    if roundChanged then
        self:ResetArenaSpecs(true)


        for _, bar in ipairs(self.bars) do
            if not bar.disabled and bar.inArena then
                for _, icon in ipairs(bar.active) do
                    if icon.cooldown then
                        icon.cooldown:SetCooldown(0, 0)
                        icon.cooldown.finish = nil
                    end
                    if icon.charges ~= nil and addon.Cooldowns[icon.spellID] and addon.Cooldowns[icon.spellID].charges then
                        icon.charges = addon.Cooldowns[icon.spellID].charges
                        icon.Count:SetText(icon.charges)
                    end
                end


                wipe(bar.active)
                OmniBar_ResetIcons(bar)
            end
        end
        return
    end


    local hasData = false
    for i = 1, MAX_ARENA_SIZE do
        local specID = GetArenaOpponentSpec(i)
        if specID and specID > 0 then
            hasData = true
            break
        end
    end


    if IN_SOLO_SHUFFLE and not hasData and self.arenaSpecsInitialized then
        return
    end


    if not hasData and self.arenaSpecsAttempts < 5 then
        self.arenaSpecsAttempts = self.arenaSpecsAttempts + 1
        C_Timer.After(1, function() self:RefreshArenaSpecs() end)
        return
    end


    if hasData then
        local newSpecs = false
        for i = 1, MAX_ARENA_SIZE do
            local specID = GetArenaOpponentSpec(i)
            if specID and specID > 0 then
                local _, _, _, _, _, class = GetSpecializationInfoByID(specID)
                if class then
                    if not self.arenaSpecs[i] or self.arenaSpecs[i].specID ~= specID then
                        newSpecs = true
                    end
                    self.arenaSpecs[i] = {
                        specID = specID,
                        class = class
                    }

                    self.arenaSpecMap = self.arenaSpecMap or {}
                    self.arenaSpecMap[i] = specID
                end
            end
        end

        self.arenaSpecsInitialized = true


        if newSpecs then

        end
    end
end

function OmniBar:UpdateBarsWithArenaSpecs()
    if not self.arenaSpecsInitialized then return end


    for _, bar in ipairs(self.bars) do
        if not bar.disabled and bar.settings.showUnused then
            if bar.inArena and bar.settings.trackUnit == "ENEMY" then
                local cooldownStates = {}
                for i, icon in ipairs(bar.active) do
                    if icon.spellID and icon:IsVisible() then
                        local remainingTime = icon.cooldown and icon.cooldown.finish and
                            (icon.cooldown.finish - GetTime()) or 0

                        local key = tostring(icon.spellID) .. "-" .. tostring(icon.sourceGUID)
                        cooldownStates[key] = {
                            charges = icon.charges,
                            remainingTime = remainingTime > 0 and remainingTime or 0,
                            sourceGUID = icon.sourceGUID,
                            sourceName = icon.sourceName,
                            spellID = icon.spellID
                        }
                    end
                end


                bar.arenaSpecMap = bar.arenaSpecMap or {}


                for i = 1, MAX_ARENA_SIZE do
                    if self.arenaSpecs[i] and self.arenaSpecs[i].specID then
                        bar.arenaSpecMap[i] = self.arenaSpecs[i].specID


                        local hasIconsForUnit = false
                        for _, icon in ipairs(bar.active) do
                            if icon.sourceGUID == i then
                                hasIconsForUnit = true
                                break
                            end
                        end


                        if not hasIconsForUnit then
                            OmniBar_AddArenaIcons(bar, i, self.arenaSpecs[i].specID, self.arenaSpecs[i].class)
                        end
                    end
                end


                if next(cooldownStates) ~= nil then
                    for i, icon in ipairs(bar.active) do
                        local key = tostring(icon.spellID) .. "-" .. tostring(icon.sourceGUID)
                        local state = cooldownStates[key]

                        if state and state.remainingTime > 0 then
                            icon.cooldown:Show()
                            OmniBar_StartCooldown(bar, icon, GetTime())
                            icon.cooldown.finish = GetTime() + state.remainingTime


                            if state.charges ~= nil then
                                icon.charges = state.charges
                                icon.Count:SetText(state.charges > 0 and state.charges or "")
                            end
                        end
                    end
                end


                OmniBar_Position(bar)
            end
        end
    end


    OmniBar.arenaInitialized = true
end

function VerifyArenaIcons(self)
    if not self.settings.showUnused then return end


    local visibleCount = 0
    for _, icon in ipairs(self.active) do
        if icon:IsVisible() then
            visibleCount = visibleCount + 1
        end
    end


    if visibleCount == 0 then
        local hasSpecs = false
        for i = 1, MAX_ARENA_SIZE do
            local specID = GetArenaOpponentSpec(i)
            if specID and specID > 0 then
                hasSpecs = true
                break
            end
        end

        if hasSpecs then
            ForceArenaIconInitialization(self)
        end
    end
end

function OmniBar:AddSpecificSpellsByClass(bar, class, sourceGUID, specID)
    for spellID, spell in pairs(addon.Cooldowns) do
        if OmniBar_IsSpellEnabled(bar, spellID) and spell.class == "GENERAL" then
            OmniBar_AddIcon(bar, {
                spellID = spellID,
                sourceGUID = sourceGUID,
                specID = specID,
                class = "GENERAL"
            })
        end
    end


    for spellID, spell in pairs(addon.Cooldowns) do
        if OmniBar_IsSpellEnabled(bar, spellID) and spell.class == class then
            local belongsToSpec = true
            if spell.specID and specID and specID > 0 then
                belongsToSpec = false
                for i = 1, #spell.specID do
                    if spell.specID[i] == specID then
                        belongsToSpec = true
                        break
                    end
                end
            end

            if belongsToSpec then
                OmniBar_AddIcon(bar, {
                    spellID = spellID,
                    sourceGUID = sourceGUID,
                    specID = specID,
                    class = class
                })
            end
        end
    end
end

function OmniBar_AddIconsByClass(self, class, sourceGUID, specID)
    if self.inArena then
        for spellID, spell in pairs(addon.Cooldowns) do
            if OmniBar_IsSpellEnabled(self, spellID) and spell.class == "GENERAL" then
                OmniBar_ArenaAddIcon(self, { spellID = spellID, sourceGUID = sourceGUID, specID = specID })
            end
        end


        for spellID, spell in pairs(addon.Cooldowns) do
            if OmniBar_IsSpellEnabled(self, spellID) and spell.class == class then
                OmniBar_ArenaAddIcon(self, { spellID = spellID, sourceGUID = sourceGUID, specID = specID })
            end
        end

        return
    end


    for spellID, spell in pairs(addon.Cooldowns) do
        if OmniBar_IsSpellEnabled(self, spellID) and
            (spell.class == "GENERAL" or
                (spell.class == class and SpellBelongsToSpec(spellID, specID)))
        then
            OmniBar_AddIcon(self, { spellID = spellID, sourceGUID = sourceGUID, specID = specID })
        end
    end
end

local function IconIsUnit(iconGUID, guid)
    if (not guid) then return end
    if type(iconGUID) == "number" then
        return UnitGUID("arena" .. iconGUID) == guid
    end
    return iconGUID == guid
end

local function OmniBar_StartAnimation(self, icon)
    if (not self.settings.glow) then return end
    icon.flashAnim:Play()
    icon.newitemglowAnim:Play()
end

local function OmniBar_StopAnimation(self, icon)
    if icon.flashAnim:IsPlaying() then icon.flashAnim:Stop() end
    if icon.newitemglowAnim:IsPlaying() then icon.newitemglowAnim:Stop() end
end

local function IsIconUsed(icon)
    if not icon.cooldown or not icon:IsVisible() then return false end


    if icon.charges ~= nil then
        return icon.charges == 0 and icon.cooldown:GetCooldownTimes() > 0
    end


    return icon.cooldown:GetCooldownTimes() > 0
end

function OmniBar_UpdateBorder(self, icon)
    local border
    local guid = icon.sourceGUID
    local name = icon.sourceName


    local isStealthedUnit = false
    if type(guid) == "number" then
        if ARENA_STATE.stealthEvents[guid] and
            ARENA_STATE.stealthEvents[guid].type == "destroyed" and
            (GetTime() - ARENA_STATE.stealthEvents[guid].time) < 5 then
            isStealthedUnit = true
        end
    end

    if guid or name then
        if self.settings.highlightFocus and
            self.settings.trackUnit == "ENEMY" and
            (IconIsUnit(guid, UnitGUID("focus")) or name == GetUnitName("focus", true)) and
            UnitIsPlayer("focus")
        then
            icon.FocusTexture:SetAlpha(1)
            border = true
        else
            icon.FocusTexture:SetAlpha(0)
        end
        if self.settings.highlightTarget and
            self.settings.trackUnit == "ENEMY" and
            (IconIsUnit(guid, UnitGUID("target")) or name == GetUnitName("target", true)) and
            UnitIsPlayer("target")
        then
            icon.FocusTexture:SetAlpha(0)
            icon.TargetTexture:SetAlpha(1)
            border = true
        else
            icon.TargetTexture:SetAlpha(0)
        end
    else
        local _, class = UnitClass("focus")
        if self.settings.highlightFocus and
            self.settings.trackUnit == "ENEMY" and
            class and (class == icon.class or icon.class == "GENERAL") and
            UnitIsPlayer("focus")
        then
            icon.FocusTexture:SetAlpha(1)
            border = true
        else
            icon.FocusTexture:SetAlpha(0)
        end
        _, class = UnitClass("target")
        if self.settings.highlightTarget and
            self.settings.trackUnit == "ENEMY" and
            class and (class == icon.class or icon.class == "GENERAL") and
            UnitIsPlayer("target")
        then
            icon.FocusTexture:SetAlpha(0)
            icon.TargetTexture:SetAlpha(1)
            border = true
        else
            icon.TargetTexture:SetAlpha(0)
        end
    end

    local isUsed = IsIconUsed(icon)
    if isStealthedUnit then


    elseif not isUsed and not border then
        icon:SetAlpha(self.settings.unusedAlpha or 1)
    else
        icon:SetAlpha(self.settings.usedAlpha or 1)
    end
end

function OmniBar_UpdateAllBorders(self)
    for i = 1, #self.active do
        OmniBar_UpdateBorder(self, self.active[i])
    end
end

function OmniBar_UpdateCooldownSort(self)
    if self.settings.sortMethod == "cooldown" and #self.active > 0 then
        self.forceResort = true
        OmniBar_Position(self)
    end
end

function OmniBar_SortIcons(self)
    local sortMethod = self.settings.sortMethod or "player"


    local isStableSortMethod = (sortMethod == "player")
    local isArena = IsInInstance() and select(1, GetInstanceInfo()) == "arena"


    if InCombatLockdown() and isStableSortMethod and isArena and self.frozenOrder then
        table.sort(self.active, function(a, b)
            local orderA = self.frozenOrder[a] or 999
            local orderB = self.frozenOrder[b] or 999
            return orderA < orderB
        end)
        return
    end



    table.sort(self.active, function(a, b)
        if sortMethod == "player" then
            if isArena then
                if type(a.sourceGUID) == "number" and type(b.sourceGUID) == "number" then
                    return a.sourceGUID < b.sourceGUID
                elseif type(a.sourceGUID) == "number" then
                    return true
                elseif type(b.sourceGUID) == "number" then
                    return false
                end
            end


            local aClass, bClass = a.class or 0, b.class or 0
            if aClass ~= bClass then
                return CLASS_ORDER[aClass] < CLASS_ORDER[bClass]
            end


            local x, y = a.ownerName or a.sourceName or "", b.ownerName or b.sourceName or ""
            if x ~= y then return x < y end


            return a.spellID < b.spellID
        elseif sortMethod == "cooldown" then
            local aIsUsed = IsIconUsed(a)
            local bIsUsed = IsIconUsed(b)


            if aIsUsed ~= bIsUsed then
                return bIsUsed
            end


            if aIsUsed and bIsUsed then
                local aRemaining = a.cooldown and a.cooldown.finish and (a.cooldown.finish - GetTime()) or 0
                local bRemaining = b.cooldown and b.cooldown.finish and (b.cooldown.finish - GetTime()) or 0
                if aRemaining ~= bRemaining then
                    return aRemaining < bRemaining
                end
            end


            local x, y = a.ownerName or a.sourceName or "", b.ownerName or b.sourceName or ""
            if x ~= y then return x < y end
            return a.spellID < b.spellID
        else
            if isArena then
                if type(a.sourceGUID) == "number" and type(b.sourceGUID) == "number" then
                    return a.sourceGUID < b.sourceGUID
                elseif type(a.sourceGUID) == "number" then
                    return true
                elseif type(b.sourceGUID) == "number" then
                    return false
                end
            end


            local aClass, bClass = a.class or 0, b.class or 0
            if aClass ~= bClass then
                return CLASS_ORDER[aClass] < CLASS_ORDER[bClass]
            end


            local x, y = a.ownerName or a.sourceName or "", b.ownerName or b.sourceName or ""
            if x ~= y then return x < y end


            return a.spellID < b.spellID
        end
    end)


    if not InCombatLockdown() and isStableSortMethod and isArena then
        self.frozenOrder = self.frozenOrder or {}
        wipe(self.frozenOrder)


        for i, icon in ipairs(self.active) do
            self.frozenOrder[icon] = i
        end
    end
end

function OmniBar_SetZone(self, refresh)
    local disabled = self.disabled
    local _, zone = IsInInstance()
    local wasInArena = self.inArena


    self.inArena = (zone == "arena")


    if self.inArena and not wasInArena then
        wipe(self.active)
        wipe(self.detected)


        self.arenaSpecMap = {}


        OmniBar.arenaInitialized = false
        ARENA_STATE.inPrep = true
        ARENA_STATE.inActiveCombat = false
        ARENA_STATE.stealthEvents = {}
        ARENA_STATE.stealthProtection = false
    end


    self.zone = zone
    self.rated = IsRatedBattleground and IsRatedBattleground()
    self.disabled = (zone == "arena" and (not self.settings.arena)) or
        (self.rated and (not self.settings.ratedBattleground)) or
        (zone == "pvp" and (not self.settings.battleground) and (not self.rated)) or
        (zone == "scenario" and (not self.settings.scenario)) or
        (zone ~= "arena" and zone ~= "pvp" and zone ~= "scenario" and (not self.settings.world))

    self.adaptive = OmniBar_IsAdaptive(self)

    if refresh or disabled ~= self.disabled then
        OmniBar_LoadPosition(self)
        OmniBar_ResetIcons(self)
        OmniBar_UpdateIcons(self)
        OmniBar_ShowAnchor(self)
        if zone == "arena" and (not self.disabled) then
            self.detected = self.detected or {}


            if (not OmniBar.arenaInitialized and self.settings.showUnused) then
                ForceArenaIconInitialization(self)
            else
                OmniBar_OnEvent(self, "ARENA_OPPONENT_UPDATE")
            end
        end
    end
end

function ForceArenaIconInitialization(self)
    if not self.settings.showUnused then return end


    if ARENA_STATE.stealthProtection and ARENA_STATE.inArena and ARENA_STATE.inActiveCombat then
        return
    end


    local cooldownStates = {}
    if not ARENA_STATE.inPrep then
        for i, icon in ipairs(self.active) do
            if icon.spellID and icon:IsVisible() then
                local remainingTime = icon.cooldown and icon.cooldown.finish and
                    (icon.cooldown.finish - GetTime()) or 0

                local key = tostring(icon.spellID) .. "-" .. tostring(icon.sourceGUID)
                cooldownStates[key] = {
                    charges = icon.charges,
                    remainingTime = remainingTime > 0 and remainingTime or 0,
                    sourceGUID = icon.sourceGUID,
                    sourceName = icon.sourceName,
                    spellID = icon.spellID
                }
            end
        end
    end


    for i = 1, self.numIcons do
        if self.icons[i].MasqueGroup then
            self.icons[i].MasqueGroup = nil
        end
        self.icons[i].TargetTexture:SetAlpha(0)
        self.icons[i].FocusTexture:SetAlpha(0)
        self.icons[i].flash:SetAlpha(0)
        self.icons[i].NewItemTexture:SetAlpha(0)

        if ARENA_STATE.inPrep then
            if self.icons[i].cooldown then
                self.icons[i].cooldown:SetCooldown(0, 0)
                self.icons[i].cooldown.finish = nil
            end

            if self.icons[i].charges ~= nil and addon.Cooldowns[self.icons[i].spellID] then
                self.icons[i].charges = addon.Cooldowns[self.icons[i].spellID].charges or 1
                self.icons[i].Count:SetText(self.icons[i].charges > 0 and self.icons[i].charges or "")
            end
        end
        self.icons[i]:Hide()
    end


    wipe(self.active)

    if ARENA_STATE.inPrep then
        wipe(self.detected)
    end


    for i = 1, MAX_ARENA_SIZE do
        if self.settings.trackUnit == "ENEMY" or self.settings.trackUnit == "arena" .. i then
            local specID = GetArenaOpponentSpec(i)
            if specID and specID > 0 then
                local _, _, _, _, _, class = GetSpecializationInfoByID(specID)
                if class then
                    self.detected[i] = class


                    self.arenaSpecMap = self.arenaSpecMap or {}
                    self.arenaSpecMap[i] = specID


                    for spellID, spell in pairs(addon.Cooldowns) do
                        if OmniBar_IsSpellEnabled(self, spellID) and spell.class == "GENERAL" then
                            OmniBar_AddIcon(self, { spellID = spellID, sourceGUID = i, specID = specID })
                        end
                    end


                    for spellID, spell in pairs(addon.Cooldowns) do
                        if OmniBar_IsSpellEnabled(self, spellID) and spell.class == class then
                            if not spell.specID or SpellBelongsToSpec(spellID, specID) then
                                OmniBar_AddIcon(self, { spellID = spellID, sourceGUID = i, specID = specID })
                            end
                        end
                    end
                end
            end
        end
    end


    if next(cooldownStates) ~= nil and not ARENA_STATE.inPrep then
        for i, icon in ipairs(self.active) do
            local key = tostring(icon.spellID) .. "-" .. tostring(icon.sourceGUID)
            local state = cooldownStates[key]

            if state and state.remainingTime > 0 then
                icon.cooldown:Show()
                OmniBar_StartCooldown(self, icon, GetTime())
                icon.cooldown.finish = GetTime() + state.remainingTime


                if state.charges ~= nil then
                    icon.charges = state.charges
                    icon.Count:SetText(state.charges > 0 and state.charges or "")
                end
            end
        end
    end


    OmniBar_Position(self)


    OmniBar.arenaInitialized = true
end

local UNITNAME_SUMMON_TITLES = {
    UNITNAME_SUMMON_TITLE1,
    UNITNAME_SUMMON_TITLE2,
    UNITNAME_SUMMON_TITLE3,
}
local tooltip = CreateFrame("GameTooltip", "OmniBarPetTooltip", nil, "GameTooltipTemplate")
local tooltipText = OmniBarPetTooltipTextLeft2
local function UnitOwnerName(guid)
    if (not guid) then return end
    for i = 1, 3 do
        _G["UNITNAME_SUMMON_TITLE" .. i] = "OmniBar %s"
    end
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink("unit:" .. guid)
    local name = tooltipText:GetText()
    for i = 1, 3 do
        _G["UNITNAME_SUMMON_TITLE" .. i] = UNITNAME_SUMMON_TITLES[i]
    end
    if (not name) then return end
    local owner = name:match("OmniBar (.+)")
    if owner then return owner end
end

local function IsSourceHostile(sourceFlags)
    local band = bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)
    if UnitIsPossessed("player") and band == 0 then return true end
    return band == COMBATLOG_OBJECT_REACTION_HOSTILE
end

local function GetCooldownDuration(cooldown, specID)
    if (not cooldown.duration) then return end
    if type(cooldown.duration) == "table" then
        if specID and cooldown.duration[specID] then
            return cooldown.duration[specID]
        else
            return cooldown.duration.default
        end
    else
        return cooldown.duration
    end
end

function OmniBar:AddSpellCast(event, sourceGUID, sourceName, sourceFlags, spellID, serverTime, customDuration)
    local isLocal = (not serverTime)
    serverTime = serverTime or GetServerTime()


    if (not customDuration) then
        for i = 1, #addon.Shared do
            local shared = addon.Shared[i]
            if (shared.triggers and tContains(shared.triggers, spellID)) or tContains(shared.spells, spellID) then
                for i = 1, #shared.spells do
                    if spellID ~= shared.spells[i] then
                        local amount = shared.amount

                        if type(amount) == "table" then amount = shared.amount.default end
                        if addon.Cooldowns[shared.spells[i]] and (not addon.Cooldowns[shared.spells[i]].parent) then
                            self:AddSpellCast(
                                event,
                                sourceGUID,
                                sourceName,
                                sourceFlags,
                                shared.spells[i],
                                nil,
                                amount
                            )
                        end
                    end
                end
            end
        end
    end

    if (not addon.Resets[spellID]) and (not addon.Cooldowns[spellID]) then return end


    sourceName = sourceName == COMBATLOG_FILTER_STRING_UNKNOWN_UNITS and nil or sourceName


    local ownerName = UnitOwnerName(sourceGUID)
    local name = ownerName or sourceName

    if (not name) then return end

    if addon.Resets[spellID] and self.spellCasts[name] and event == "SPELL_CAST_SUCCESS" then
        for i = 1, #addon.Resets[spellID] do
            local reset = addon.Resets[spellID][i]
            if type(reset) == "table" and reset.amount then
                if self.spellCasts[name][reset.spellID] then
                    self.spellCasts[name][reset.spellID].duration = self.spellCasts[name][reset.spellID].duration -
                    reset.amount
                    if self.spellCasts[name][reset.spellID].duration < 1 then
                        self.spellCasts[name][reset.spellID] = nil
                    end
                end
            else
                if type(reset) == "table" then reset = reset.spellID end
                self.spellCasts[name][reset] = nil
            end
        end
        self:SendMessage("OmniBar_ResetSpellCast", name, spellID)
    end

    if (not addon.Cooldowns[spellID]) then return end

    local now = GetTime()

    local charges = addon.Cooldowns[spellID].charges
    local duration = customDuration or GetCooldownDuration(addon.Cooldowns[spellID])


    spellID = addon.Cooldowns[spellID].parent or spellID



    if self.spellCasts[name] and
        self.spellCasts[name][spellID] and
        (customDuration or self.spellCasts[name][spellID].serverTime == serverTime)
    then
        return
    end


    if (not ownerName) and bit_band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == 0 then return end


    if (not charges) then
        charges = addon.Cooldowns[spellID].charges
    end


    if (not duration) then
        duration = GetCooldownDuration(addon.Cooldowns[spellID])
    end






    self.spellCasts[name] = self.spellCasts[name] or {}
    self.spellCasts[name][spellID] = {
        charges = charges,
        duration = duration,
        event = event,
        expires = now + duration,
        ownerName = ownerName,
        serverTime = serverTime,
        sourceFlags = sourceFlags,
        sourceGUID = sourceGUID,
        sourceName = sourceName,
        spellID = spellID,
        spellName = GetSpellName(spellID),
        timestamp = now,
    }

    self:SendMessage("OmniBar_SpellCast", name, spellID)
end

function OmniBar:AlertGroup(...)
    if (not IsInGroup()) or GetNumGroupMembers() > 5 then return end
    local event, sourceGUID, sourceName, sourceFlags, spellID, serverTime = ...
    self:SendCommMessage("OmniBarSpell", self:Serialize(...), GetDefaultCommChannel(), nil, "ALERT")
end

function OmniBar:UNIT_SPELLCAST_SUCCEEDED(event, unit, _, spellID)
    if (not addon.Cooldowns[spellID]) then return end

    local sourceFlags = 0

    if UnitReaction("player", unit) < 4 then
        sourceFlags = sourceFlags + COMBATLOG_OBJECT_REACTION_HOSTILE
    end

    if UnitIsPlayer(unit) then
        sourceFlags = sourceFlags + COMBATLOG_OBJECT_TYPE_PLAYER
    end

    self:AddSpellCast(event, UnitGUID(unit), GetUnitName(unit, true), sourceFlags, spellID)
end

function OmniBar:COMBAT_LOG_EVENT_UNFILTERED()
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, destRaidFlags, spellID, spellName =
    CombatLogGetCurrentEventInfo()


    if (subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_INTERRUPT") then
        if spellID == 0 and SPELL_ID_BY_NAME then spellID = SPELL_ID_BY_NAME[spellName] end
        self:AddSpellCast(subevent, sourceGUID, sourceName, sourceFlags, spellID)
    end


    if CHANNELED_SPELLS[spellID] then
        if subevent == "SPELL_CAST_SUCCESS" then
            self.activeChannels[sourceGUID] = {
                spellID = spellID,
                sourceName = sourceName,
                sourceFlags = sourceFlags,
                timestamp = timestamp
            }
        elseif subevent == "SPELL_CAST_FAILED" or subevent == "SPELL_AURA_REMOVED" then
            self.activeChannels[sourceGUID] = nil
        elseif subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "SPELL_PERIODIC_HEAL" or
            subevent == "SPELL_DAMAGE" or subevent:match("^SPELL_") then
            local channelInfo = self.activeChannels[sourceGUID]
            if channelInfo and channelInfo.spellID == spellID then
                self:ProcessCooldownReduction(spellID, sourceGUID, sourceName, "SPELL_CHANNEL_TICK")
            end
        end
    end


    if subevent == "SPELL_INTERRUPT" or subevent == "SPELL_CAST_SUCCESS" or
        subevent == "SPELL_DAMAGE" or subevent == "SPELL_AURA_APPLIED" then
        self:ProcessCooldownReduction(spellID, sourceGUID, sourceName, subevent)
    end
end

function OmniBar:ProcessCooldownReduction(spellID, sourceGUID, sourceName, eventType)
    if not addon.CooldownReduction[spellID] then return end

    for _, bar in ipairs(self.bars) do
        for _, icon in ipairs(bar.active) do
            if not addon.CooldownReduction[spellID] or not addon.CooldownReduction[spellID][icon.spellID] then

            else
                local reductionInfo = addon.CooldownReduction[spellID][icon.spellID]
                local reduction, requiredEvent

                if type(reductionInfo) == "number" then
                    reduction = reductionInfo
                elseif type(reductionInfo) == "table" then
                    reduction = reductionInfo.amount
                    requiredEvent = reductionInfo.event
                else
                    return
                end


                if CHANNELED_SPELLS[spellID] and eventType == "SPELL_CHANNEL_TICK" then
                    if requiredEvent and requiredEvent ~= "SPELL_CAST_SUCCESS" and requiredEvent ~= "ANY" then
                        return
                    end
                elseif requiredEvent and requiredEvent ~= eventType and requiredEvent ~= "ANY" then
                    return
                end


                local samePlayer = false
                if sourceGUID and icon.sourceGUID then
                    samePlayer = (sourceGUID == icon.sourceGUID)
                elseif sourceName and icon.sourceName then
                    samePlayer = (sourceName == icon.sourceName)
                end


                if samePlayer then
                    local start, duration = icon.cooldown:GetCooldownTimes()
                    if start > 0 and duration > 0 then
                        local remaining = (start / 1000 + duration / 1000) - GetTime()
                        remaining = math.max(0, remaining - reduction)


                        icon.cooldown:SetCooldown(GetTime(), remaining)


                        if icon.cooldown.finish then
                            icon.cooldown.finish = GetTime() + remaining
                        end
                    end
                end
            end
        end
    end
end

function OmniBar_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or
        event == "ZONE_CHANGED_NEW_AREA" or
        event == "PLAYER_TARGET_CHANGED" or
        event == "PLAYER_FOCUS_CHANGED" or
        event == "GROUP_ROSTER_UPDATE" then
        if not SafeRefresh(self) then return end
    end
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateArenaState()


        if ShouldPreventReset() and ARENA_STATE.inArena then
            OmniBar_UpdateAllBorders(self)
            return
        end

        local inInstance, instanceType = IsInInstance()

        self.inArena = (inInstance and instanceType == "arena")

        if not self.inArena then
            self.arenaSpecMap = self.arenaSpecMap or {}
            wipe(self.arenaSpecMap)
        end

        OmniBar_SetZone(self, true)


        if self.inArena and self.settings.showUnused then
            C_Timer.After(0.5, function()
                ForceArenaIconInitialization(self)
            end)
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        OmniBar_SetZone(self, true)
    elseif event == "UPDATE_BATTLEFIELD_STATUS" then
        if self.disabled or self.zone ~= "pvp" then return end
        if (not self.rated) and IsRatedBattleground() then OmniBar_SetZone(self) end
    elseif event == "UPDATE_BATTLEFIELD_SCORE" then
        for i = 1, GetNumBattlefieldScores() do
            local name, _, _, _, _, _, _, _, classToken, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i)
            if name and SPEC_ID_BY_NAME[classToken] and SPEC_ID_BY_NAME[classToken][talentSpec] then
                if (not self.specs[name]) then
                    self.specs[name] = SPEC_ID_BY_NAME[classToken][talentSpec]
                    self:SendMessage("OmniBar_SpecUpdated", name)
                end
            end
        end
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        UpdateArenaState()


        if ShouldPreventReset() and ARENA_STATE.inArena then
            OmniBar_UpdateAllBorders(self)
            return
        end

        local inInstance, instanceType = IsInInstance()

        self.inArena = (inInstance and instanceType == "arena")

        if not self.inArena then
            self.arenaSpecMap = self.arenaSpecMap or {}
            wipe(self.arenaSpecMap)
        end

        OmniBar_SetZone(self, true)


        if self.inArena and self.settings.showUnused then
            C_Timer.After(0.5, function()
                ForceArenaIconInitialization(self)
            end)
        end
    elseif event == "ARENA_OPPONENT_UPDATE" then
        if self.disabled then return end


        local unit, updateType = ...


        if not unit or not UnitExists(unit) then return end


        UpdateArenaState()


        if updateType == "destroyed" then
            local arenaIndex = tonumber(unit:match("%d+"))
            if arenaIndex then
                ARENA_STATE.stealthEvents[arenaIndex] = {
                    type = "destroyed",
                    time = GetTime()
                }
                ARENA_STATE.lastStealthTime = GetTime()
                ARENA_STATE.stealthProtection = true
                C_Timer.After(2.0, function()
                    ARENA_STATE.stealthProtection = false
                end)
            end


            OmniBar_UpdateAllBorders(self)
            OmniBar_Position(self)
            return
        elseif updateType == "seen" then
            if self.settings.showUnused and not OmniBar.arenaInitialized then
                C_Timer.After(0.2, function()
                    ForceArenaIconInitialization(self)
                end)
            end


            OmniBar_UpdateAllBorders(self)
            OmniBar_Position(self)
            return
        end


        if ARENA_STATE.inActiveCombat and ShouldPreventReset() then
            return
        end


        if (not self.settings.showUnused) then return end

        if unit == self.settings.trackUnit then
            OmniBar_Refresh(self)
            return
        end


        if self.settings.trackUnit == "ENEMY" then
            if UnitExists(unit) then
                local _, class = UnitClass(unit)
                if class then
                    local i = tonumber(unit:match("%d+$"))
                    if i and (not self.detected[i]) then
                        self.detected[i] = class
                        OmniBar_AddIconsByClass(self, class, i)
                    end
                end
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if self.disabled then return end
        if self.settings.trackUnit == "GROUP" or self.settings.trackUnit:match("^party") then
            OmniBar_Refresh(self)
        end
    elseif event == "PVP_MATCH_ACTIVE" then
        if self.zone == "arena" then
            self.inArena = true
            ARENA_STATE.inArena = true
            ARENA_STATE.inPrep = false
            ARENA_STATE.inActiveCombat = true


            if self.settings.showUnused then
                C_Timer.After(0.5, function()
                    ForceArenaIconInitialization(self)
                end)
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_REGEN_DISABLED" then
        if self.disabled then return end

        local unit = (event == "PLAYER_TARGET_CHANGED" and "target") or (event == "PLAYER_FOCUS_CHANGED" and "focus")
        if unit and unit:upper() == self.settings.trackUnit then
            OmniBar_Refresh(self)
        end


        OmniBar_UpdateAllBorders(self)


        if self.inArena then return end


        if self.zone == "arena" then return end


        if self.settings.trackUnit ~= "ENEMY" then return end


        if (not self.settings.showUnused) or
            (not self.adaptive) or
            (not UnitIsHostile("target"))
        then
            return
        end





        local guid = UnitGUID("target")
        local _, class = UnitClass("target")
        if class and UnitIsPlayer("target") then
            if self.detected[guid] then return end
            self.detected[guid] = class
            OmniBar_AddIconsByClass(self, class, nil, self.specs[GetUnitName("target", true)])
        end
    end
end

function OmniBar_AddArenaIcons(self, arenaIndex, specID, class)
    if not class or not specID then return end


    for spellID, spell in pairs(addon.Cooldowns) do
        if OmniBar_IsSpellEnabled(self, spellID) and spell.class == "GENERAL" then
            OmniBar_AddIcon(self, { spellID = spellID, sourceGUID = arenaIndex, specID = specID })
        end
    end


    for spellID, spell in pairs(addon.Cooldowns) do
        if OmniBar_IsSpellEnabled(self, spellID) and
            spell.class == class and
            not spell.specID
        then
            OmniBar_AddIcon(self, { spellID = spellID, sourceGUID = arenaIndex, specID = specID })
        end
    end


    for spellID, spell in pairs(addon.Cooldowns) do
        if OmniBar_IsSpellEnabled(self, spellID) and
            spell.class == class and
            spell.specID
        then
            for i = 1, #spell.specID do
                if spell.specID[i] == specID then
                    OmniBar_AddIcon(self, { spellID = spellID, sourceGUID = arenaIndex, specID = specID })
                    break
                end
            end
        end
    end
end

function OmniBar_EnsureArenaIconsInitialized(self)
    if not self.inArena or not self.settings.showUnused then return end


    local hasVisibleIcons = false
    for _, icon in ipairs(self.active) do
        if icon:IsVisible() then
            hasVisibleIcons = true
            break
        end
    end


    if not hasVisibleIcons then
        ForceArenaIconInitialization(self)
    end
end

function OmniBar_LoadSettings(self)
    self.container:SetScale(self.settings.size / BASE_ICON_SIZE)

    OmniBar_LoadPosition(self)
    OmniBar_ResetIcons(self)
    OmniBar_UpdateIcons(self)
    OmniBar_Center(self)
end

function OmniBar_SavePosition(self, set)
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
    local frameStrata = self:GetFrameStrata()
    relativeTo = relativeTo and relativeTo:GetName() or "UIParent"
    if set then
        if set.point then point = set.point end
        if set.relativeTo then relativeTo = set.relativeTo end
        if set.relativePoint then relativePoint = set.relativePoint end
        if set.xOfs then xOfs = set.xOfs end
        if set.yOfs then yOfs = set.yOfs end
        if set.frameStrata then frameStrata = set.frameStrata end
    end

    if (not self.settings.position) then
        self.settings.position = {}
    end
    self.settings.position.point = point
    self.settings.position.relativeTo = relativeTo
    self.settings.position.relativePoint = relativePoint
    self.settings.position.xOfs = xOfs
    self.settings.position.yOfs = yOfs
    self.settings.position.frameStrata = frameStrata
end

function OmniBar_ResetPosition(self)
    self.settings.position.relativeTo = "UIParent"
    self.settings.position.relativePoint = "CENTER"
    self.settings.position.xOfs = 0
    self.settings.position.yOfs = 0
    OmniBar_LoadPosition(self)
end

function OmniBar:IsValidSpec(specID)
    if not specID or specID == 0 then return false end
    local _, name = GetSpecializationInfoByID(specID)
    return name ~= nil
end

function OmniBar_LoadPosition(self)
    self:ClearAllPoints()
    if self.settings.position then
        local point = self.settings.position.point or "CENTER"
        self.anchor:ClearAllPoints()
        self.anchor:SetPoint(point, self, point, 0, 0)
        local relativeTo = self.settings.position.relativeTo or "UIParent"
        if (not _G[relativeTo]) then
            OmniBar_ResetPosition(self)
            return
        end
        local relativePoint = self.settings.position.relativePoint or "CENTER"
        local xOfs = self.settings.position.xOfs or 0
        local yOfs = self.settings.position.yOfs or 0
        self:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        if (not self.settings.position.frameStrata) then self.settings.position.frameStrata = "MEDIUM" end
        self:SetFrameStrata(self.settings.position.frameStrata)
    else
        self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        OmniBar_SavePosition(self)
    end
end

function OmniBar_IsSpellEnabled(self, spellID)
    if (not spellID) then return end

    if (not self.settings.spells) then return addon.Cooldowns[spellID].default end

    return self.settings.spells[spellID]
end

function OmniBar:GetSpellTexture(spellID)
    spellID = tonumber(spellID)
    return (addon.Cooldowns[spellID] and addon.Cooldowns[spellID].icon) or GetSpellTexture(spellID)
end

function OmniBar_SpecUpdated(self, event, name)
    if self.disabled then return end
    if self.settings.trackUnit == "GROUP" or UnitIsUnit(self.settings.trackUnit, name) then
        OmniBar_Refresh(self)
    end
end

function OmniBar:GetSpecs()
    if (not GetSpecializationInfo) then return end
    if (not self.specs[PLAYER_NAME]) then
        self.specs[PLAYER_NAME] = GetSpecializationInfo(GetSpecialization())
        self:SendMessage("OmniBar_SpecUpdated", PLAYER_NAME)
    end
    if self.lastInspect and GetTime() - self.lastInspect < 3 then
        return
    end
    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, class = GetRaidRosterInfo(i)
        if name and (not self.specs[name]) and (not UnitIsUnit("player", name)) and CanInspect(name) then
            self.inspectUnit = name
            self.lastInspect = GetTime()
            self:RegisterEvent("INSPECT_READY")
            NotifyInspect(name)
            return
        end
    end
end

function OmniBar:INSPECT_READY(event, guid)
    if (not self.inspectUnit) then return end
    local unit = self.inspectUnit
    self.inspectUnit = nil
    self:UnregisterEvent("INSPECT_READY")
    if (UnitGUID(unit) ~= guid) then
        ClearInspectPlayer()
        self:GetSpecs()
        return
    end
    self.specs[unit] = GetInspectSpecialization(unit)
    self:SendMessage("OmniBar_SpecUpdated", unit)
    ClearInspectPlayer()
    self:GetSpecs()
end

function OmniBar_IsUnitEnabled(self, info)
    if (not info.timestamp) then return true end
    if info.test then return true end

    local guid = info.sourceGUID
    if guid == nil then return end

    local name = info.ownerName or info.sourceName

    local isHostile = IsSourceHostile(info.sourceFlags)

    if self.settings.trackUnit == "ENEMY" and isHostile then
        return true
    end

    local isPlayer = UnitIsUnit("player", name)

    if self.settings.trackUnit == "PLAYER" and isPlayer then
        return true
    end

    if self.settings.trackUnit == "TARGET" and (UnitGUID("target") == guid or GetUnitName("target", true) == name) then
        return true
    end

    if self.settings.trackUnit == "FOCUS" and (UnitGUID("focus") == guid or GetUnitName("focus", true) == name) then
        return true
    end

    if self.settings.trackUnit == "GROUP" and (not isPlayer) and (UnitInParty(name) or UnitInRaid(name)) then
        return true
    end

    for i = 1, MAX_ARENA_SIZE do
        local unit = "arena" .. i
        if (i == guid or UnitGUID(unit) == guid) and self.settings.trackUnit == unit:lower() then
            return true
        end
    end

    for i = 1, 4 do
        local unit = "party" .. i
        if (i == guid or UnitGUID(unit) == guid) and self.settings.trackUnit == unit:lower() then
            return true
        end
    end
end

function OmniBar_Center(self)
    local parentWidth = UIParent:GetWidth()
    local clamp = self.settings.center and (1 - parentWidth) / 2 or 0
    self:SetClampRectInsets(clamp, -clamp, 0, 0)
    clamp = self.settings.center and (self.anchor:GetWidth() - parentWidth) / 2 or 0
    self.anchor:SetClampRectInsets(clamp, -clamp, 0, 0)
end

function OmniBar_CooldownFinish(self, force)
    local icon = self:GetParent()
    if icon.cooldown and icon.cooldown:GetCooldownTimes() > 0 and (not force) then return end

    local maxCharges = addon.Cooldowns[icon.spellID] and addon.Cooldowns[icon.spellID].charges
    if maxCharges and icon.charges ~= nil then
        if icon.charges < maxCharges then
            icon.charges = icon.charges + 1
            icon.Count:SetText(icon.charges)


            local bar = icon:GetParent():GetParent()


            if icon.charges < maxCharges then
                OmniBar_StartCooldown(icon:GetParent():GetParent(), icon, GetTime())


                if icon.charges == 0 then
                    icon:SetAlpha(bar.settings.usedAlpha or 1)
                else
                    icon:SetAlpha(bar.settings.unusedAlpha or 1)
                end
                return
            else
                icon:SetAlpha(bar.settings.unusedAlpha or 1)
            end
        end
    end

    local bar = icon:GetParent():GetParent()
    OmniBar_StopAnimation(self, icon)
    if bar.frozenOrder and bar.frozenOrder[icon] then
        local currentOrder = bar.frozenOrder[icon]
        bar.frozenOrder[icon] = nil


        C_Timer.After(0.1, function()
            if bar.frozenOrder then
                bar.frozenOrder[icon] = currentOrder
            end
        end)
    end

    if (not bar.settings.showUnused) then
        icon:Hide()
    else
        if icon.TargetTexture:GetAlpha() == 0 and
            icon.FocusTexture:GetAlpha() == 0 then
            icon:SetAlpha(bar.settings.unusedAlpha or 1)
        end
    end
    if bar.settings.sortMethod == "cooldown" and bar.settings.showUnused then
        OmniBar_UpdateCooldownSort(bar)
    end
    bar:StopMovingOrSizing()
    OmniBar_Position(bar)
end

function OmniBar_ReplaySpellCasts(self)
    if self.disabled then return end

    local now = GetTime()

    for name, _ in pairs(self.spellCasts) do
        for k, v in pairs(self.spellCasts[name]) do
            if now >= v.expires then
                self.spellCasts[name][k] = nil
            else
                OmniBar_AddIcon(self, self.spellCasts[name][k])
            end
        end
    end
end

local function OmniBar_UnitClassAndSpec(self)
    local unit = self.settings.trackUnit
    if unit == "ENEMY" or unit == "GROUP" then return end
    local _, class = UnitClass(unit)
    local specID = self.specs[GetUnitName(unit, true)]
    return class, specID
end

function OmniBar_ResetIcons(self)
    if ShouldPreventReset() and self.inArena then
        OmniBar_UpdateAllBorders(self)
        return
    end


    local cooldownStates = SaveCooldownStates(self)



    for i = 1, self.numIcons do
        if self.icons[i].MasqueGroup then
            self.icons[i].MasqueGroup = nil
        end
        self.icons[i].TargetTexture:SetAlpha(0)
        self.icons[i].FocusTexture:SetAlpha(0)
        self.icons[i].flash:SetAlpha(0)
        self.icons[i].NewItemTexture:SetAlpha(0)
        self.icons[i].cooldown:SetCooldown(0, 0)
        self.icons[i].cooldown:Hide()
        self.icons[i]:Hide()
    end
    wipe(self.active)

    if self.disabled then return end

    if self.settings.showUnused then
        local inInstance, instanceType = IsInInstance()
        local isArena = instanceType == "arena"

        if isArena and self.arenaSpecMap then
            return
        end


        if self.settings.trackUnit == "ENEMY" then
            if (not self.adaptive) then
                for spellID, _ in pairs(addon.Cooldowns) do
                    if OmniBar_IsSpellEnabled(self, spellID) then
                        OmniBar_AddIcon(self, { spellID = spellID })
                    end
                end
            end
        elseif self.settings.trackUnit == "GROUP" then
            for i = 1, GetNumGroupMembers() do
                local name, _, _, _, _, class = GetRaidRosterInfo(i)
                local guid = UnitGUID(name)
                if class and (not UnitIsUnit("player", name)) then
                    OmniBar_AddIconsByClass(self, class, UnitGUID(name), self.specs[name])
                end
            end
        else
            local class, specID = OmniBar_UnitClassAndSpec(self)
            if class and UnitIsPlayer(self.settings.trackUnit) then
                OmniBar_AddIconsByClass(self, class, nil, specID)
            end
        end
    end


    if self.inArena then
        RestoreCooldownStates(self, cooldownStates)
    end

    OmniBar_Position(self)
end

function OmniBar_StartCooldown(self, icon, start)
    icon.cooldown:SetCooldown(start, icon.duration)
    icon.cooldown.finish = start + icon.duration
    icon.cooldown:SetSwipeColor(0, 0, 0, self.settings.swipeAlpha or 0.65)
    icon.cooldown:SetScript("OnUpdate", function(cooldown, elapsed)
        cooldown.elapsed = (cooldown.elapsed or 0) + elapsed
        if cooldown.elapsed >= 0.5 then
            cooldown.elapsed = 0

            if self.settings.sortMethod == "cooldown" and self.settings.showUnused then
                OmniBar_UpdateCooldownSort(self)
            end
        end
    end)
    icon:SetAlpha(self.settings.usedAlpha or 1)
end

function OmniBar_AddIcon(self, info)
    if (not OmniBar_IsUnitEnabled(self, info)) then return end
    if (not OmniBar_IsSpellEnabled(self, info.spellID)) then return end

    local icon, duplicate


    for i = 1, #self.active do
        if self.active[i].spellID == info.spellID then
            duplicate = true

            if info.timestamp or self.zone ~= "arena" then
                if (not self.active[i].sourceGUID) then
                    duplicate = nil
                    icon = self.active[i]
                    break
                end


                if info.sourceGUID and IconIsUnit(self.active[i].sourceGUID, info.sourceGUID) then
                    duplicate = nil
                    icon = self.active[i]
                    break
                end
            end
        end
    end


    if (not icon) then
        if #self.active >= self.settings.maxIcons then return end
        if (not self.settings.multiple) and duplicate then return end
        for i = 1, #self.icons do
            if (not self.icons[i]:IsVisible()) then
                icon = self.icons[i]
                icon.specID = nil
                break
            end
        end
    end


    if (not icon) then return end

    icon.class = addon.Cooldowns[info.spellID].class
    icon.sourceGUID = info.sourceGUID
    icon.sourceName = info.ownerName or info.sourceName
    icon.specID = info.specID and info.specID or self.specs[icon.sourceName]
    icon.icon:SetTexture(addon.Cooldowns[info.spellID].icon)
    icon.spellID = info.spellID
    icon.timestamp = info.test and GetTime() or info.timestamp
    icon.duration = info.test and math.random(5, 30) or GetCooldownDuration(addon.Cooldowns[info.spellID], icon.specID)
    icon.added = GetTime()



    local isArena = IsInInstance() and select(1, GetInstanceInfo()) == "arena"
    local isStableSortMethod = self.settings.sortMethod == "player" or self.settings.sortMethod == "spec"

    if self.frozenOrder and InCombatLockdown() and isArena and isStableSortMethod then
        local maxOrder = 0
        for _, order in pairs(self.frozenOrder) do
            maxOrder = math.max(maxOrder, order)
        end
        self.frozenOrder[icon] = maxOrder + 1
    end


    local maxCharges = addon.Cooldowns[info.spellID].charges or 1
    if info.charges then
        if icon:IsVisible() and icon.charges then
            if icon.charges > 0 then
                icon.charges = icon.charges - 1
                icon.Count:SetText(icon.charges)
                OmniBar_StartAnimation(self, icon)

                if not icon.cooldown.finish or icon.cooldown.finish - GetTime() <= 1 then
                    OmniBar_StartCooldown(self, icon, GetTime())
                end
                return icon
            end
        else
            icon.charges = maxCharges - 1
            icon.Count:SetText(icon.charges)
        end
    else
        icon.charges = nil
        icon.Count:SetText(nil)
    end

    if self.settings.names then
        local name = info.test and "Name" or icon.sourceName
        icon.Name:SetText(name)
    end


    if Masque then
        icon.MasqueGroup = Masque:Group("OmniBar", info.spellName)
        icon.MasqueGroup:AddButton(icon, {
            FloatingBG = false,
            Icon = icon.icon,
            Cooldown = icon.cooldown,
            Flash = false,
            Pushed = false,
            Normal = icon:GetNormalTexture(),
            Disabled = false,
            Checked = false,
            Border = _G[icon:GetName() .. "Border"],
            AutoCastable = false,
            Highlight = false,
            Hotkey = false,
            Count = false,
            Name = false,
            Duration = false,
            AutoCast = false,
        })
    end

    icon:Show()

    if (icon.timestamp) then
        OmniBar_StartCooldown(self, icon, icon.timestamp)
        if (GetTime() == icon.timestamp) then OmniBar_StartAnimation(self, icon) end
    end


    self.forceResort = true

    return icon
end

function OmniBar_UpdateIcons(self)
    for i = 1, self.numIcons do
        self.icons[i].cooldown:SetHideCountdownNumbers(not self.settings.cooldownCount and true or false)
        self.icons[i].cooldown.noCooldownCount = (not self.settings.cooldownCount)


        self.icons[i].cooldown:SetSwipeColor(0, 0, 0, self.settings.swipeAlpha or 0.65)



        OmniBar_SetPixelBorder(self.icons[i], self.settings.border, 1, 0, 0, 0)


        local isUsed = IsIconUsed(self.icons[i])
        if not isUsed then
            self.icons[i]:SetAlpha(self.settings.unusedAlpha or 1)
        else
            self.icons[i]:SetAlpha(self.settings.usedAlpha or 1)
        end


        if self.icons[i].MasqueGroup then self.icons[i].MasqueGroup:ReSkin() end
    end
end

function OmniBar_Test(self)
    if (not self) then return end
    self.disabled = nil
    OmniBar_ResetIcons(self)
    if self.settings.spells then
        for k, v in pairs(self.settings.spells) do
            OmniBar_AddIcon(self, { spellID = k, test = true })
        end
    else
        for k, v in pairs(addon.Cooldowns) do
            if v.default then
                OmniBar_AddIcon(self, { spellID = k, test = true })
            end
        end
    end
end

function OmniBar_Position(self)
    local numActive = #self.active
    if numActive == 0 then
        OmniBar_ShowAnchor(self)
        return
    end

    if self.settings.sortMethod or self.forceResort then
        OmniBar_SortIcons(self)
        self.forceResort = nil
    elseif self.settings.showUnused then
        table.sort(self.active, function(a, b)
            local x, y = a.ownerName or a.sourceName or "", b.ownerName or b.sourceName or ""
            local aClass, bClass = a.class or 0, b.class or 0
            if aClass == bClass then
                if self.settings.trackUnit ~= "ENEMY" and self.settings.trackUnit ~= "GROUP" then
                    return a.spellID < b.spellID
                end
                if x < y then return true end
                if x == y then return a.spellID < b.spellID end
            end
            return CLASS_ORDER[aClass] < CLASS_ORDER[bClass]
        end)
    else
        table.sort(self.active,
            function(a, b) return a.added == b.added and a.spellID < b.spellID or a.added < b.added end)
    end

    local count, rows = 0, 1
    local grow = self.settings.growUpward and 1 or -1
    local padding = self.settings.padding and self.settings.padding or 0
    for i = 1, numActive do
        if self.settings.locked then
            self.active[i]:EnableMouse(false)
        else
            self.active[i]:EnableMouse(true)
        end
        self.active[i]:ClearAllPoints()
        local columns = self.settings.columns and self.settings.columns > 0 and self.settings.columns < numActive and
            self.settings.columns or numActive
        if i > 1 then
            count = count + 1
            if count >= columns then
                if self.settings.align == "CENTER" then
                    self.active[i]:SetPoint("CENTER", self.anchor, "CENTER", (-BASE_ICON_SIZE - padding) * (columns - 1) /
                    2, (BASE_ICON_SIZE + padding) * rows * grow)
                else
                    self.active[i]:SetPoint(self.settings.align, self.anchor, self.settings.align, 0,
                        (BASE_ICON_SIZE + padding) * rows * grow)
                end

                count = 0
                rows = rows + 1
            else
                if self.settings.align == "RIGHT" then
                    self.active[i]:SetPoint("TOPRIGHT", self.active[i - 1], "TOPLEFT", -1 * padding, 0)
                else
                    self.active[i]:SetPoint("TOPLEFT", self.active[i - 1], "TOPRIGHT", padding, 0)
                end
            end
        else
            if self.settings.align == "CENTER" then
                self.active[i]:SetPoint("CENTER", self.anchor, "CENTER", (-BASE_ICON_SIZE - padding) * (columns - 1) / 2,
                    0)
            else
                self.active[i]:SetPoint(self.settings.align, self.anchor, self.settings.align, 0, 0)
            end
        end
    end
    OmniBar_ShowAnchor(self)
end

function OmniBar:Test()
    for key, _ in pairs(self.db.profile.bars) do
        OmniBar_Test(_G[key])
    end
end

function OmniBar:IsSpecValid(specID)
    if not specID or specID == 0 then return false end

    local _, name = GetSpecializationInfoByID(specID)
    return name ~= nil
end

function OmniBar_SetPixelBorder(icon, show, edgeSize, r, g, b)
    if not show then
        icon.borderTop:Hide()
        icon.borderBottom:Hide()
        icon.borderLeft:Hide()
        icon.borderRight:Hide()
        icon.icon:SetTexCoord(0, 1, 0, 1)
        return
    end

    edgeSize = edgeSize or 1
    r = r or 0
    g = g or 0
    b = b or 0

    icon.borderTop:ClearAllPoints()
    icon.borderTop:SetPoint("TOPLEFT", icon, "TOPLEFT")
    icon.borderTop:SetPoint("BOTTOMRIGHT", icon, "TOPRIGHT", 0, -edgeSize)
    icon.borderTop:SetColorTexture(r, g, b)
    icon.borderTop:Show()

    icon.borderBottom:ClearAllPoints()
    icon.borderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT")
    icon.borderBottom:SetPoint("TOPRIGHT", icon, "BOTTOMRIGHT", 0, edgeSize)
    icon.borderBottom:SetColorTexture(r, g, b)
    icon.borderBottom:Show()

    icon.borderRight:ClearAllPoints()
    icon.borderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, -edgeSize)
    icon.borderRight:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", -edgeSize, edgeSize)
    icon.borderRight:SetColorTexture(r, g, b)
    icon.borderRight:Show()

    icon.borderLeft:ClearAllPoints()
    icon.borderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, -edgeSize)
    icon.borderLeft:SetPoint("BOTTOMRIGHT", icon, "BOTTOMLEFT", edgeSize, edgeSize)
    icon.borderLeft:SetColorTexture(r, g, b)
    icon.borderLeft:Show()

    icon.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

SLASH_OmniBar1 = "/ob"
SLASH_OmniBar2 = "/omnibar"
SlashCmdList.OmniBar = function()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(addonName)
    else
        InterfaceOptionsFrame_OpenToCategory(addonName)
        InterfaceOptionsFrame_OpenToCategory(addonName)
    end
end
