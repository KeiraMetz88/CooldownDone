local ADDON_NAME, CooldownDone = ...

local LibBlzSettings = LibStub("LibBlzSettings-1.0")
local CONTROL_TYPE = LibBlzSettings.CONTROL_TYPE
local SETTING_TYPE = LibBlzSettings.SETTING_TYPE

CooldownDone.category = nil
local CATEGORY_NAME_AURA = "BUFF列表"

-- Matches a similar function reused in multiple places
local function EnumerateTaintedKeysTable(tableToIterate)
    local pairsIterator, enumerateTable, initialIteratorKey = securecallfunction(pairs, tableToIterate);
    local function IteratorFunction(tbl, key)
        return securecallfunction(pairsIterator, tbl, key);
    end

    return IteratorFunction, enumerateTable, initialIteratorKey;
end

function CooldownDone:addAura(control)
    local auraID = tonumber(control.Editbox:GetText())
    if not auraID or auraID <= 0 then
        print("|cffff0000请输入ID|r")
        return
    end
    local auraName = C_Spell.GetSpellName(auraID)
    if not auraName then
        print("|cffff0000未找到，请输入正确的ID|r")
        return
    end
    if self.auras[auraID] then
        print(string.format("|cffff0000%s-%s已经存在|r", auraID, auraName))
        return
    end
    local key = string.format("CooldownDone.aura.%s.name", auraID)
    CooldownDoneCharDB[key] = ""
    self.auras[auraID] = {
        id = auraID,
        name = auraName,
        texture = C_Spell.GetSpellTexture(auraID)
    }
    local name = self.auras[auraID].name .. "(" .. tostring(self.auras[auraID].id) .. ")" .. "|T" .. self.auras[auraID].texture .. ":14:14:1:0|t"
    local dataTbl = {
        controlType = "EDITBOX_AND_BUTTON",
        settingType = SETTING_TYPE.ADDON_VARIABLE,
        name = name,
        key = key,
        default = "",
        editboxTooltip = "自定义BUFF名称",
        button = {
            buttonText = "移除",
            OnButtonClick = function(control)
                self:removeAura(control)
            end,
        },
    }
    for _, subCategory in ipairs(CooldownDone.category:GetSubcategories()) do
        if subCategory:GetName() == CATEGORY_NAME_AURA then
            local layout = SettingsPanel:GetLayout(subCategory)
            local _, initializer = CDDSettingsEditboxAndButtonBuildFunction(ADDON_NAME, subCategory, layout, dataTbl, CooldownDoneCharDB)
            initializer.LibBlzSettingsData = {}
            local newInitializers = {}
            for k, v in EnumerateTaintedKeysTable(layout:GetInitializers()) do
                if v.data.name == "BUFF获得" then
                    table.insert(newInitializers, initializer)
                end
                if v ~= initializer then
                    table.insert(newInitializers, v)
                end
            end
            layout.initializers = newInitializers
            SettingsPanel:DisplayLayout(layout)
            break
        end
    end
end

function CooldownDone:addAddedAura(control)
    local auraID = tonumber(control.Editbox:GetText())
    if not auraID or auraID <= 0 then
        print("|cffff0000请输入ID|r")
        return
    end
    local auraName = C_Spell.GetSpellName(auraID)
    if not auraName then
        print("|cffff0000未找到，请输入正确的ID|r")
        return
    end
    if self.addedAuras[auraID] then
        print(string.format("|cffff0000%s-%s已经存在|r", auraID, auraName))
        return
    end
    local key = string.format("CooldownDone.addedaura.%s.name", auraID)
    CooldownDoneCharDB[key] = ""
    self.addedAuras[auraID] = {
        id = auraID,
        name = auraName,
        texture = C_Spell.GetSpellTexture(auraID)
    }
    local name = self.addedAuras[auraID].name .. "(" .. tostring(self.addedAuras[auraID].id) .. ")" .. "|T" .. self.addedAuras[auraID].texture .. ":14:14:1:0|t"
    local dataTbl = {
        controlType = "EDITBOX_AND_BUTTON",
        settingType = SETTING_TYPE.ADDON_VARIABLE,
        name = name,
        key = key,
        default = "",
        editboxTooltip = "自定义BUFF名称",
        button = {
            buttonText = "移除",
            OnButtonClick = function(control)
                self:removeAddedAura(control)
            end,
        },
    }
    for _, subCategory in ipairs(CooldownDone.category:GetSubcategories()) do
        if subCategory:GetName() == CATEGORY_NAME_AURA then
            local layout = SettingsPanel:GetLayout(subCategory)
            local _, initializer = CDDSettingsEditboxAndButtonBuildFunction(ADDON_NAME, subCategory, layout, dataTbl, CooldownDoneCharDB)
            initializer.LibBlzSettingsData = {}
            SettingsPanel:DisplayLayout(layout)
            break
        end
    end
end

function CooldownDone:removeAura(control)
    local initializer = control:GetElementData()
    local key = initializer.data.key
    local auraID = key:match("CooldownDone.aura.([%d]+).name")
    auraID = tonumber(auraID)
    if not auraID or auraID <= 0 then
        print("|cffff0000数据错误|r")
        return
    end
    local key = string.format("CooldownDone.aura.%s.name", auraID)
    CooldownDoneCharDB[key] = nil
    self.auras[auraID] = nil
    for _, subCategory in ipairs(CooldownDone.category:GetSubcategories()) do
        if subCategory:GetName() == CATEGORY_NAME_AURA then
            local layout = SettingsPanel:GetLayout(subCategory)
            local newInitializers = {}
            for k, v in EnumerateTaintedKeysTable(layout:GetInitializers()) do
                if initializer ~= v then
                    table.insert(newInitializers, v)
                end
            end
            layout.initializers = newInitializers
            SettingsPanel:DisplayLayout(layout)
            break
        end
    end
end

function CooldownDone:removeAddedAura(control)
    local initializer = control:GetElementData()
    local key = initializer.data.key
    local auraID = key:match("CooldownDone.addedaura.([%d]+).name")
    auraID = tonumber(auraID)
    if not auraID or auraID <= 0 then
        print("|cffff0000数据错误|r")
        return
    end
    local key = string.format("CooldownDone.addedaura.%s.name", auraID)
    CooldownDoneCharDB[key] = nil
    self.addedAuras[auraID] = nil
    for _, subCategory in ipairs(CooldownDone.category:GetSubcategories()) do
        if subCategory:GetName() == CATEGORY_NAME_AURA then
            local layout = SettingsPanel:GetLayout(subCategory)
            local newInitializers = {}
            for k, v in EnumerateTaintedKeysTable(layout:GetInitializers()) do
                if initializer ~= v then
                    table.insert(newInitializers, v)
                end
            end
            layout.initializers = newInitializers
            SettingsPanel:DisplayLayout(layout)
            break
        end
    end
end

function CooldownDone:prepareSettings()
    local voiceIDOptions = {}
    local voiceIDDefault = nil
    local ttsVoices = C_VoiceChat.GetTtsVoices()
    for index, voice in ipairs(ttsVoices) do
        if voiceIDDefault == nil then
            voiceIDDefault = voice.voiceID
        end
        table.insert(voiceIDOptions, {
            value = voice.voiceID,
            name = voice.name,
            tooltip = voice.name,
        })
    end
    local settings = {
        name = "CD就绪",
        settings = {
            {
                controlType = CONTROL_TYPE.CHECKBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = "启用",
                tooltip = "启用/禁用插件功能，无需重载界面",
                key = "CooldownDone.enable",
                default = true,
            },
            {
                controlType = CONTROL_TYPE.CHECKBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = "调试",
                tooltip = "启用/禁用调试信息",
                key = "CooldownDone.debug",
                default = false,
            },
            {
                controlType = CONTROL_TYPE.EDITBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = "就绪",
                tooltip = "技能就绪的文本",
                key = "CooldownDone.doneStr",
                default = "就绪",
            },
            {
                controlType = CONTROL_TYPE.EDITBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = "获得",
                tooltip = "获得BUFF的文本",
                key = "CooldownDone.addedStr",
                default = "获得",
            },
            {
                controlType = CONTROL_TYPE.EDITBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = "结束",
                tooltip = "BUFF结束的文本",
                key = "CooldownDone.overStr",
                default = "结束",
            },
            {
                controlType = CONTROL_TYPE.DROPDOWN,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = "语音",
                tooltip = "选择使用的语音",
                key = "CooldownDone.ttsVoiceID",
                default = voiceIDDefault,
                options = voiceIDOptions,
            },
            {
                controlType = CONTROL_TYPE.SLIDER,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = "语速",
                key = "CooldownDone.ttsRate",
                minValue = TEXTTOSPEECH_RATE_MIN,
                maxValue = TEXTTOSPEECH_RATE_MAX,
                step = 1,
                default = 0,
            },
            {
                controlType = CONTROL_TYPE.SLIDER,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = "音量",
                key = "CooldownDone.ttsVolume",
                minValue = TEXTTOSPEECH_VOLUME_MIN,
                maxValue = TEXTTOSPEECH_VOLUME_MAX,
                step = 1,
                default = 100,
            },
            {
                controlType = CONTROL_TYPE.BUTTON,
                name = "测试",
                buttonText = "点击测试",
                execute = function()
                    CooldownDone:speakTTS("技能名")
                end,
            },
        },
        subCategorys = {
            {
                name = "技能列表",
                database = CooldownDoneCharDB,
                settings = {
                    {
                        controlType = "LABEL",
                        name = "提示：修改天赋/习得法术/切换天赋/切换专精等操作请reload！",
                    },
                },
            },
            {
                name = CATEGORY_NAME_AURA,
                database = CooldownDoneCharDB,
                settings = {
                    {
                        controlType = "LABEL",
                        name = "提示：移除BUFF数据后请务必reload！",
                    },
                },
            }
        }
    }

    table.insert(settings.subCategorys[1].settings, {
        controlType = CONTROL_TYPE.SECTION_HEADER,
        name = "法术列表",
    })
    for _, spell in pairs(self.spellBookSpells) do
        local keyCheckbox = string.format("CooldownDone.spell.%s.enable", spell.id)
        local keyEditbox = string.format("CooldownDone.spell.%s.name", spell.id)
        local name = spell.name .. "(" .. tostring(spell.id) .. ")" .. "|T" .. spell.texture .. ":14:14:1:0|t"
        table.insert(settings.subCategorys[1].settings, {
            controlType = CONTROL_TYPE.CHECKBOX_AND_EDITBOX,
            settingType = SETTING_TYPE.ADDON_VARIABLE,
            name = name,
            tooltip = "启用/禁用",
            key = keyCheckbox,
            default = false,
            editbox = {
                controlType = CONTROL_TYPE.EDITBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = name,
                tooltip = "自定义技能名称",
                key = keyEditbox,
                default = "",
            },
        })
    end
    table.insert(settings.subCategorys[1].settings, {
        controlType = CONTROL_TYPE.SECTION_HEADER,
        name = "装备列表",
    })
    for _, spell in pairs(self.equippedItemSpells) do
        local keyCheckbox = string.format("CooldownDone.spell.%s.enable", spell.id)
        local keyEditbox = string.format("CooldownDone.spell.%s.name", spell.id)
        local itemName = spell.itemName .."(" .. tostring(spell.itemID)..")" .. "|T" .. spell.itemTexture .. ":14:14:1:0|t"
        local spellName = spell.name .."(" .. tostring(spell.id)..")" .. "|T" .. spell.texture .. ":14:14:1:0|t"
        table.insert(settings.subCategorys[1].settings, {
            controlType = CONTROL_TYPE.CHECKBOX_AND_EDITBOX,
            settingType = SETTING_TYPE.ADDON_VARIABLE,
            name = itemName,
            tooltip = spellName .. "\n启用/禁用",
            key = keyCheckbox,
            default = false,
            editbox = {
                controlType = CONTROL_TYPE.EDITBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = itemName,
                tooltip = spellName .. "\n自定义装备名称",
                key = keyEditbox,
                default = "",
            },
        })
    end

    table.insert(settings.subCategorys[2].settings, {
        controlType = CONTROL_TYPE.SECTION_HEADER,
        name = "BUFF结束",
    })
    table.insert(settings.subCategorys[2].settings, {
        controlType = "EDITBOX_AND_BUTTON",
        name = "添加BUFF ID",
        tooltip = "输入BUFF ID后点击添加按钮",
        button = {
            buttonText = "添加",
            OnButtonClick = function(control)
                self:addAura(control)
             end,
        },
    })
    for _, aura in pairs(self.auras) do
        local keyEditbox = string.format("CooldownDone.aura.%s.name", aura.id)
        local name = aura.name .. "(" .. tostring(aura.id) .. ")" .. "|T" .. aura.texture .. ":14:14:1:0|t"
        table.insert(settings.subCategorys[2].settings, {
            controlType = "EDITBOX_AND_BUTTON",
            settingType = SETTING_TYPE.ADDON_VARIABLE,
            name = name,
            key = keyEditbox,
            default = "",
            editboxTooltip = "自定义BUFF名称",
            button = {
                buttonText = "移除",
                OnButtonClick = function(control)
                    self:removeAura(control)
                end,
            },
        })
    end
    table.insert(settings.subCategorys[2].settings, {
        controlType = CONTROL_TYPE.SECTION_HEADER,
        name = "BUFF获得",
    })
    table.insert(settings.subCategorys[2].settings, {
        controlType = "EDITBOX_AND_BUTTON",
        name = "添加BUFF ID",
        tooltip = "输入BUFF ID后点击添加按钮",
        button = {
            buttonText = "添加",
            OnButtonClick = function(control)
                self:addAddedAura(control)
             end,
        },
    })
    for _, aura in pairs(self.addedAuras) do
        local keyEditbox = string.format("CooldownDone.addedaura.%s.name", aura.id)
        local name = aura.name .. "(" .. tostring(aura.id) .. ")" .. "|T" .. aura.texture .. ":14:14:1:0|t"
        table.insert(settings.subCategorys[2].settings, {
            controlType = "EDITBOX_AND_BUTTON",
            settingType = SETTING_TYPE.ADDON_VARIABLE,
            name = name,
            key = keyEditbox,
            default = "",
            editboxTooltip = "自定义BUFF名称",
            button = {
                buttonText = "移除",
                OnButtonClick = function(control)
                    self:removeAddedAura(control)
                end,
            },
        })
    end

    CooldownDone.category, _ = LibBlzSettings:RegisterVerticalSettingsTable(ADDON_NAME, settings, CooldownDoneDB, true)

    _G.SLASH_COOLDOWNDONE1 = "/cdd";
    _G.SlashCmdList["COOLDOWNDONE"] = function()
        Settings.OpenToCategory(CooldownDone.category:GetID())
    end
end
