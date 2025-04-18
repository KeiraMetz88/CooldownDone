local ADDON_NAME, CooldownDone = ...

CooldownDone.spellBookSpells = {}
CooldownDone.equippedItemSpells = {}
CooldownDone.cooldownFrames = {}

local function prepareDB()
    CooldownDoneDB = (type(CooldownDoneDB) == "table" and CooldownDoneDB) or {}
    CooldownDoneCharDB = (type(CooldownDoneCharDB) == "table" and CooldownDoneCharDB) or {}
end

function CooldownDone:debug(val)
    if not CooldownDoneDB or not CooldownDoneDB["CooldownDone.debug"] then return end
    print("CDD(" .. GetTime() .. "): " .. val)
end

function CooldownDone:getPlayerSpellBookSpells()
    table.wipe(self.spellBookSpells)
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
            if info and not info.isPassive and not info.isOffSpec and info.itemType == Enum.SpellBookItemType.Spell and info.name then
                local spellID = info.spellID or info.actionID
                if spellID and spellID > 0 and not excludedSpells[spellID] and not self.spellBookSpells[spellID] then
                    self.spellBookSpells[spellID] = {
                        id = spellID,
                        name = C_Spell.GetSpellName(spellID) or "未知法术",
                        texture = C_Spell.GetSpellTexture(spellID)
                    }
                end
            end
        end
    end
    table.sort(self.spellBookSpells, function(a, b) return a.name:lower() < b.name:lower() end)
end

function CooldownDone:getEquippedItemSpells(prepareSettings)
    table.wipe(self.equippedItemSpells)
    local itemIDs = {}
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            table.insert(itemIDs, itemID)
        end
    end
    local itemLoadCount = 0
    for _, itemID in ipairs(itemIDs) do
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function()
            local spellName, spellID = C_Item.GetItemSpell(itemID)
            if spellID and spellName and not self.equippedItemSpells[spellID] then
                local sName = C_Spell.GetSpellName(spellID) or spellName
                local iName = item:GetItemName()  or sName
                self.equippedItemSpells[spellID] = {
                    id = spellID,
                    name = sName,
                    texture = C_Spell.GetSpellTexture(spellID),
                    itemID = itemID,
                    itemName = iName,
                    itemTexture = item:GetItemIcon()
                }
            end
            itemLoadCount = itemLoadCount + 1
            if itemLoadCount >= #itemIDs then
                table.sort(self.equippedItemSpells, function(a, b) return a.name:lower() < b.name:lower() end)
                if prepareSettings then
                    self:prepareSettings()
                end
            end
        end)
    end
    if #itemIDs == 0 and prepareSettings then
        self:prepareSettings()
    end
end

function CooldownDone:speakTTS(text)
    if not text then return end
    if not CooldownDoneDB or not CooldownDoneDB["CooldownDone.enable"] then return end
    local ttsVoiceID = CooldownDoneDB and CooldownDoneDB["CooldownDone.ttsVoiceID"] or 0
    local ttsRate = CooldownDoneDB and CooldownDoneDB["CooldownDone.ttsRate"] or 0
    local ttsVolume = CooldownDoneDB and CooldownDoneDB["CooldownDone.ttsVolume"] or 100
    local textAppend = CooldownDoneDB and CooldownDoneDB["CooldownDone.doneStr"] or "就绪"
    self:debug("speakTTS: " .. text .. textAppend)
    C_VoiceChat.SpeakText(ttsVoiceID, text .. textAppend, Enum.VoiceTtsDestination.LocalPlayback, ttsRate, ttsVolume)
end

function CooldownDone:UNIT_SPELLCAST_SUCCEEDED(spellID, immediately)
    if not CooldownDoneDB or not CooldownDoneDB["CooldownDone.enable"] then return end
    local key = string.format("CooldownDone.spell.%s.enable", spellID)
    if not CooldownDoneCharDB or not CooldownDoneCharDB[key] then return end

    local function setCooldown(spellID)
        -- Check if spell is item-spell
        local isEquippedItemSpell = false
        local startTime, duration, isEnabled, modRate
        local name = ""
        for _, spell in pairs(self.equippedItemSpells) do
            if tonumber(spellID) == tonumber(spell.id) then
                isEquippedItemSpell = true
                startTime, duration = C_Item.GetItemCooldown(spell.itemID)
                isEnabled = true
                modRate = 1
                name = spell.itemName
                break
            end
        end
        if not isEquippedItemSpell then
            -- If spell charge-based and has charges available, do not track cd
            local chargeInfo = C_Spell.GetSpellCharges(spellID)
            if chargeInfo then
                if chargeInfo.currentCharges == chargeInfo.maxCharges or chargeInfo.currentCharges > 0 then
                    if self.cooldownFrames[spellID] and self.cooldownFrames[spellID]:GetScript("OnCooldownDone") then
                        name = C_Spell.GetSpellName(spellID) or "未知法术"
                        local keyName = string.format("CooldownDone.spell.%s.name", spellID)
                        if CooldownDoneCharDB and CooldownDoneCharDB[keyName] and CooldownDoneCharDB[keyName] ~= "" then
                            name = CooldownDoneCharDB[keyName]
                        end
                        self:speakTTS(name)
                        self.cooldownFrames[spellID]:SetScript("OnCooldownDone", nil)
                    end
                    return
                end
            end
            local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID) or {startTime = 0, duration = 0, isEnabled = false, modRate = 0}
            startTime, duration, isEnabled, modRate = spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.isEnabled, spellCooldownInfo.modRate
            name = C_Spell.GetSpellName(spellID) or "未知法术"
        end
        local keyName = string.format("CooldownDone.spell.%s.name", spellID)
        if CooldownDoneCharDB and CooldownDoneCharDB[keyName] and CooldownDoneCharDB[keyName] ~= "" then
            name = CooldownDoneCharDB[keyName]
        end
        if startTime and startTime > 0 and duration and duration > 0 then
            self:debug("Cooldown: spellID-" .. spellID .. ", startTime-" .. startTime .. ", duration-" .. duration .. ", isEnabled-" .. (isEnabled and "1" or "0"))
            self.cooldownFrames[spellID] = self.cooldownFrames[spellID] or CreateFrame("Cooldown", nil)
            self.cooldownFrames[spellID].CooldownDoneTTSName = name
            self.cooldownFrames[spellID].CooldownDoneTTSIsEnabled = isEnabled
            self.cooldownFrames[spellID]:SetCooldown(startTime, duration, modRate)
            self.cooldownFrames[spellID]:SetScript("OnCooldownDone", function()
                if self.cooldownFrames[spellID].CooldownDoneTTSIsEnabled then
                    self:speakTTS(self.cooldownFrames[spellID].CooldownDoneTTSName)
                    self.cooldownFrames[spellID]:SetScript("OnCooldownDone", nil)
                end
            end)
        end
        if startTime == 0 and duration == 0 and self.cooldownFrames[spellID] and self.cooldownFrames[spellID]:GetScript("OnCooldownDone") then
            self:debug("Cooldown: spellID-" .. spellID .. ", startTime-" .. startTime .. ", duration-" .. duration .. ", isEnabled-" .. (isEnabled and "1" or "0"))
            self.cooldownFrames[spellID].CooldownDoneTTSName = name
            self.cooldownFrames[spellID].CooldownDoneTTSIsEnabled = isEnabled
            self.cooldownFrames[spellID]:SetCooldown(startTime, duration, modRate)
            self:speakTTS(self.cooldownFrames[spellID].CooldownDoneTTSName)
            self.cooldownFrames[spellID]:SetScript("OnCooldownDone", nil)
        end
    end

    if immediately then
        setCooldown(spellID)
    else
        -- C_Spell.GetSpellCooldown here now may return duration=GCD time, so we check it later
        C_Timer.After(1.6, function()
            setCooldown(spellID)
        end)
    end
end

-- https://warcraft.wiki.gg/wiki/SPELL_UPDATE_COOLDOWN
-- Patch 11.1.5 (2025-04-22): Added spellID, baseSpellID arguments.
function CooldownDone:SPELL_UPDATE_COOLDOWN()
    if not CooldownDoneCharDB then return end
    for k, v in pairs(CooldownDoneCharDB) do
        if v then
            local spellID = k:match("CooldownDone.spell.([%d]+).enable")
            if spellID and tonumber(spellID) > 0 then
                spellID = tonumber(spellID)
                if self.cooldownFrames[spellID] then
                    if self.cooldownFrames[spellID]:GetScript("OnCooldownDone") then
                        self:UNIT_SPELLCAST_SUCCEEDED(spellID, true)
                    end
                end
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addOnName = ...
        if addOnName == ADDON_NAME then
            CooldownDone:debug(event)
            prepareDB()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CooldownDone:debug(event)
        CooldownDone:getPlayerSpellBookSpells()
        CooldownDone:getEquippedItemSpells(true)
        --CooldownDone:prepareSettings()
        -- https://warcraft.wiki.gg/wiki/PLAYER_ENTERING_WORLD
        -- Fires when the player logs in, /reloads the UI or zones between map instances. Basically whenever the loading screen appears.
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        CooldownDone:getEquippedItemSpells(false)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...
        if unitTarget == "player" then
            CooldownDone:UNIT_SPELLCAST_SUCCEEDED(spellID, false)
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        CooldownDone:debug(event)
        CooldownDone:SPELL_UPDATE_COOLDOWN()
    end
end)
