local ADDON_NAME, CooldownDone = ...

CooldownDone.spellBookSpells = {}
CooldownDone.equippedItemSpells = {}
CooldownDone.cooldownFrames = {}

local function prepareDB()
    CooldownDoneDB = (type(CooldownDoneDB) == "table" and CooldownDoneDB) or {}
    CooldownDoneCharDB = (type(CooldownDoneCharDB) == "table" and CooldownDoneCharDB) or {}
end

function CooldownDone:debug(val)
    UIParentLoadAddOn("Blizzard_DebugTools");
	DevTools_DumpCommand(val);
end

function CooldownDone:getPlayerSpellBookSpells()
    local excludedSpells = {
        [6603] = true,
        [382499] = true,
        [125439] = true,
        [83958] = true,
        [382501] = true,
    }
    local numSkillLines = C_SpellBook.GetNumSpellBookSkillLines()
    for i = 1, numSkillLines do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
        local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
        for j = offset+1, offset+numSlots do
            local info = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
            if info and info.actionID and info.actionID > 0 and not info.isPassive and not info.isOffSpec and not info.isPet and info.name and not excludedSpells[info.actionID] and not self.spellBookSpells[info.actionID] then
                local s = C_Spell.GetSpellInfo(info.actionID)
                if s and s.name then
                    table.insert(self.spellBookSpells, {
                        id = info.actionID,
                        name = s.name,
                        texture = C_Spell.GetSpellTexture(info.actionID)
                    })
                end
            end
        end
    end
    table.sort(CooldownDone.spellBookSpells, function(a, b) return a.name:lower() < b.name:lower() end)
end

function CooldownDone:getEquippedItemSpells()
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            local spellName, spellID = C_Item.GetItemSpell(itemID)
            if spellID and spellName and not self.equippedItemSpells[spellID] then
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                local sName = spellInfo and spellInfo.name or spellName
                table.insert(self.equippedItemSpells, {
                    id = spellID,
                    name = sName,
                    texture = C_Item.GetItemIconByID(itemID)
                })
            end
        end
    end
    table.sort(CooldownDone.equippedItemSpells, function(a, b) return a.name:lower() < b.name:lower() end)
end

function CooldownDone:speakTTS(text)
    if not text then return end
    if not CooldownDoneDB or not CooldownDoneDB["CooldownDone.enable"] then return end
    local ttsVoiceID = CooldownDoneDB and CooldownDoneDB["CooldownDone.ttsVoiceID"] or 2
    local ttsRate = CooldownDoneDB and CooldownDoneDB["CooldownDone.ttsRate"] or 0
    local ttsVolume = CooldownDoneDB and CooldownDoneDB["CooldownDone.ttsVolume"] or 100
    C_VoiceChat.SpeakText(ttsVoiceID, text, Enum.VoiceTtsDestination.QueuedLocalPlayback, ttsRate, ttsVolume)
end

function CooldownDone:trackCooldownDone(spellID)
    if not CooldownDoneDB or not CooldownDoneDB["CooldownDone.enable"] then return end
    local key = string.format("CooldownDone.spell.%s.enable", spellID)
    if not CooldownDoneCharDB or not CooldownDoneCharDB[key] then return end
    C_Timer.After(1.5, function()
        local spellCooldownInfo  = C_Spell.GetSpellCooldown(spellID) or {startTime=0,duration=0,isEnabled=false,modRate=1}
        if spellCooldownInfo.startTime > 0 and spellCooldownInfo.duration > 0 then
            self.cooldownFrames[spellID] = self.cooldownFrames[spellID] or CreateFrame("Cooldown", nil)
            self.cooldownFrames[spellID]:SetCooldown(spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.modRate)
            self.cooldownFrames[spellID]:SetScript("OnCooldownDone",function()
                local name = C_Spell.GetSpellName(spellID) or "未知法术"
                self:speakTTS(name .. "就绪")
                self.cooldownFrames[spellID]:SetScript("OnCooldownDone", nil);
            end)
        end
    end)
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
        CooldownDone:prepareSettings()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...
        if unitTarget == "player" then
            CooldownDone:trackCooldownDone(spellID)
        end
    end
end)
