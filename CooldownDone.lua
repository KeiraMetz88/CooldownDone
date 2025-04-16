local ADDON_NAME = ...

local CooldownDone = {}
CooldownDone.spells = {}
CooldownDone.cooldownFrames = {}

local function prepareDB()
    CooldownDoneDB = (type(CooldownDoneDB) == "table" and CooldownDoneDB) or {}
end

function CooldownDone:getPlayerSpellBookSpells()
    local excludedSpells = {
        [6603] = true,
        [382499] = true,
        [125439] = true,
        [83958] = true,
        [382501] = true,
    }
    local spells, seen = {}, {}
    local numSkillLines = C_SpellBook.GetNumSpellBookSkillLines()
    for i = 1, numSkillLines do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
        local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
        for j = offset+1, offset+numSlots do
            local info = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
            if info and info.actionID and info.actionID > 0 and not info.isPassive and not info.isOffSpec and not info.isPet and info.name and not excludedSpells[info.actionID] and not self.spells[info.actionID] then
                local s = C_Spell.GetSpellInfo(info.actionID)
                if s and s.name then
                    table.insert(self.spells, {
                        id = info.actionID,
                        name = s.name,
                        texture = C_Spell.GetSpellTexture(info.actionID)
                    })
                end
            end
        end
    end
end

function CooldownDone:getEquippedItemSpells()
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            local spellName, spellID = C_Item.GetItemSpell(itemID)
            if spellID and spellName and not self.spells[spellID] then
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                local sName = spellInfo and spellInfo.name or spellName
                table.insert(self.spells, {
                    id = spellID,
                    name = sName,
                    texture = C_Item.GetItemIconByID(itemID)
                })
            end
        end
    end
end

function CooldownDone:speakTTS(text)
    C_VoiceChat.SpeakText(2, text, Enum.VoiceTtsDestination.QueuedLocalPlayback, 0, 100)
end

function CooldownDone:trackCooldownDone(spellID)
    local key = string.format("CooldownDone.spell.%s.enable", spellID)
    --print(CooldownDoneDB[key])
    if not CooldownDoneDB or not CooldownDoneDB[key] then return end
    C_Timer.After(2, function()
        local spellCooldownInfo  = C_Spell.GetSpellCooldown(spellID) or {startTime=0,duration=0,isEnabled=false,modRate=1}
        --print(spellID,spellCooldownInfo.startTime,spellCooldownInfo.duration,spellCooldownInfo.isEnabled,spellCooldownInfo.modRate)
        if spellCooldownInfo.startTime > 0 and spellCooldownInfo.duration > 0 then
            self.cooldownFrames[spellID] = self.cooldownFrames[spellID] or CreateFrame("Cooldown", nil)
            self.cooldownFrames[spellID]:SetCooldown(spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.modRate)
            self.cooldownFrames[spellID]:SetScript("OnCooldownDone",function()
                --print(GetTime(),"OnCooldownDone")
                local name = C_Spell.GetSpellName(spellID) or "未知法术"
                self:speakTTS(name .. "就绪")
                self.cooldownFrames[spellID]:SetScript("OnCooldownDone", nil);
            end)
        end
    end)
end

function CooldownDone:prepareSettings()
    local LibBlzSettings = LibStub("LibBlzSettings-1.0")
    local CONTROL_TYPE = LibBlzSettings.CONTROL_TYPE
    local SETTING_TYPE = LibBlzSettings.SETTING_TYPE
    local settings = {
        name = "CD就绪",
        settings = {
        }
    }
    for _, spell in ipairs(self.spells) do
        local key = string.format("CooldownDone.spell.%s.enable", spell.id)
        table.insert(settings.settings, {
            controlType = CONTROL_TYPE.CHECKBOX,
            settingType = SETTING_TYPE.ADDON_VARIABLE,
            name = spell.name .. "|T"..spell.texture..":15:15:1:0|t",
            tooltip = spell.name,
            key = key,
            default = false
        })
    end
    LibBlzSettings:RegisterVerticalSettingsTable(ADDON_NAME, settings, CooldownDoneDB, true)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addOnName = ...
        if addOnName == ADDON_NAME then
            prepareDB()
			self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CooldownDone:getPlayerSpellBookSpells()
        CooldownDone:getEquippedItemSpells()
        table.sort(CooldownDone.spells, function(a, b) return a.name:lower() < b.name:lower() end)
        CooldownDone:prepareSettings()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...
        if unitTarget == "player" then
            CooldownDone:trackCooldownDone(spellID)
        end
    end
end)
