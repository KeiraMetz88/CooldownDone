local ADDON_NAME, CooldownDone = ...

CooldownDone.spellBookSpells = {}
CooldownDone.equippedItemSpells = {}
CooldownDone.auras = {}
CooldownDone.addedAuras = {}
CooldownDone.cooldownFrames = {}
CooldownDone.Locale = {}
local L = CooldownDone.Locale

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
                        name = C_Spell.GetSpellName(spellID) or L["UnknownSpell"],
                        texture = C_Spell.GetSpellTexture(spellID)
                    }
                end
            end
        end
    end
    table.sort(self.spellBookSpells, function(a, b) return a.name:lower() < b.name:lower() end)
end

function CooldownDone:getAuras()
    table.wipe(self.auras)
    table.wipe(self.addedAuras)
    local auraID
    for k, v in pairs(CooldownDoneCharDB) do
        auraID = k:match("CooldownDone.aura.([%d]+).name")
        if auraID and tonumber(auraID) > 0 then
            auraID = tonumber(auraID)
            if not self.auras[auraID] then
                self.auras[auraID] = {
                    id = auraID,
                    name = C_Spell.GetSpellName(auraID) or L["UnknownAura"],
                    texture = C_Spell.GetSpellTexture(auraID)
                }
            end
        end
        auraID = k:match("CooldownDone.addedaura.([%d]+).name")
        if auraID and tonumber(auraID) > 0 then
            auraID = tonumber(auraID)
            if not self.addedAuras[auraID] then
                self.addedAuras[auraID] = {
                    id = auraID,
                    name = C_Spell.GetSpellName(auraID) or L["UnknownAura"],
                    texture = C_Spell.GetSpellTexture(auraID)
                }
            end
        end
    end
end

function CooldownDone:getEquippedItemSpells(prepareSettings)
    table.wipe(self.equippedItemSpells)
    local itemIDs = {}
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            table.insert(itemIDs, {itemID = itemID, from = "equipped"})
        end
    end
    for containerIndex = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slotIndex = 1, C_Container.GetContainerNumSlots(containerIndex) do
            itemID = C_Container.GetContainerItemID(containerIndex, slotIndex)
            if itemID then
                table.insert(itemIDs, {itemID = itemID, from = "container"})
            end
        end
    end
    local itemLoadCount = 0
    for _, itemID in ipairs(itemIDs) do
        local item = Item:CreateFromItemID(itemID.itemID)
        item:ContinueOnItemLoad(function()
            local spellName, spellID = C_Item.GetItemSpell(itemID.itemID)
            if spellID and spellName and not (itemID.from == "container" and not C_Item.IsEquippableItem(itemID.itemID)) and not self.equippedItemSpells[spellID] then
                local sName = C_Spell.GetSpellName(spellID) or spellName
                local iName = item:GetItemName()  or sName
                self.equippedItemSpells[spellID] = {
                    id = spellID,
                    name = sName,
                    texture = C_Spell.GetSpellTexture(spellID),
                    itemID = itemID.itemID,
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

function CooldownDone:speakTTS(text, typeStr)
    if not text then return end
    if not CooldownDoneDB or not CooldownDoneDB["CooldownDone.enable"] then return end
    local ttsVoiceID = CooldownDoneDB and CooldownDoneDB["CooldownDone.ttsVoiceID"] or 0
    local ttsRate = CooldownDoneDB and CooldownDoneDB["CooldownDone.ttsRate"] or 0
    local ttsVolume = CooldownDoneDB and CooldownDoneDB["CooldownDone.ttsVolume"] or 100
    local textPrepend = ""
    local textAppend = CooldownDoneDB and CooldownDoneDB["CooldownDone.doneStr"] or L["Ready"]
    if typeStr == "over" then
        textAppend = CooldownDoneDB and CooldownDoneDB["CooldownDone.overStr"] or L["Expired"]
    end
    if typeStr == "added" then
        textPrepend = CooldownDoneDB and CooldownDoneDB["CooldownDone.addedStr"] or L["Gained"]
        textAppend = ""
    end
    self:debug("speakTTS: " .. text .. textAppend)
    C_VoiceChat.SpeakText(ttsVoiceID, textPrepend .. " " .. text .. " " .. textAppend, Enum.VoiceTtsDestination.LocalPlayback, ttsRate, ttsVolume)
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
                        name = C_Spell.GetSpellName(spellID) or L["UnknownSpell"]
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
            name = C_Spell.GetSpellName(spellID) or L["UnknownSpell"]
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

CooldownDone.trackingAuras = {}
function CooldownDone:UNIT_AURA(updateInfo)
    if not CooldownDoneDB or not CooldownDoneDB["CooldownDone.enable"] then return end
    local key
    if updateInfo.addedAuras ~= nil then
        for _, addedAura in ipairs(updateInfo.addedAuras) do
            key = string.format("CooldownDone.aura.%s.name", addedAura.spellId)
            if CooldownDoneCharDB and CooldownDoneCharDB[key] ~= nil and not self.trackingAuras[addedAura.auraInstanceID] then
                self.trackingAuras[addedAura.auraInstanceID] = addedAura
            end
            key = string.format("CooldownDone.addedaura.%s.name", addedAura.spellId)
            if CooldownDoneCharDB and CooldownDoneCharDB[key] ~= nil then
                local name = CooldownDoneCharDB[key] ~= "" and CooldownDoneCharDB[key] or addedAura.name
                self:speakTTS(name, "added")
            end
        end
    end
    if updateInfo.updatedAuraInstanceIDs ~= nil then
        for _, updatedAuraInstanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", updatedAuraInstanceID)
            if aura then
                key = string.format("CooldownDone.aura.%s.name", aura.spellId)
                if CooldownDoneCharDB and CooldownDoneCharDB[key] ~= nil and not self.trackingAuras[updatedAuraInstanceID] then
                    self.trackingAuras[updatedAuraInstanceID] = aura
                end
            end
        end
    end
    if updateInfo.removedAuraInstanceIDs ~= nil then
        for _, removedAuraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
            if self.trackingAuras[removedAuraInstanceID] then
                key = string.format("CooldownDone.aura.%s.name", self.trackingAuras[removedAuraInstanceID].spellId)
                if CooldownDoneCharDB and CooldownDoneCharDB[key] ~= nil then
                    local name = CooldownDoneCharDB[key] ~= "" and CooldownDoneCharDB[key] or self.trackingAuras[removedAuraInstanceID].name
                    self:speakTTS(name, "over")
                end
                self.trackingAuras[removedAuraInstanceID] = nil
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
frame:RegisterUnitEvent("UNIT_AURA", "player")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addOnName = ...
        if addOnName == ADDON_NAME then
            CooldownDone:debug(event)
            prepareDB()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function()
            CooldownDone:debug(event)
            CooldownDone:getPlayerSpellBookSpells()
            CooldownDone:getAuras()
            CooldownDone:getEquippedItemSpells(true)
        end)
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
    elseif event == "UNIT_AURA" then
        local unitTarget, updateInfo = ...
        if unitTarget == "player" then
            CooldownDone:UNIT_AURA(updateInfo)
        end
    end
end)
