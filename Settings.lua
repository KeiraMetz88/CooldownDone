local ADDON_NAME, CooldownDone = ...

function CooldownDone:prepareSettings()
    local LibBlzSettings = LibStub("LibBlzSettings-1.0")
    local CONTROL_TYPE = LibBlzSettings.CONTROL_TYPE
    local SETTING_TYPE = LibBlzSettings.SETTING_TYPE

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
                controlType = CONTROL_TYPE.EDITBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = "就绪",
                tooltip = "就绪的文本",
                key = "CooldownDone.doneStr",
                default = "就绪",
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
                module = "spells",
                name = "技能列表",
                database = CooldownDoneCharDB,
                settings = {},
            }
        }
    }

    if #self.spellBookSpells > 0 then
        table.insert(settings.subCategorys[1].settings, {
            controlType = CONTROL_TYPE.SECTION_HEADER,
            name = "法术列表",
        })
        for _, spell in ipairs(self.spellBookSpells) do
            local keyCheckbox = string.format("CooldownDone.spell.%s.enable", spell.id)
            local keyEditbox = string.format("CooldownDone.spell.%s.name", spell.id)
            table.insert(settings.subCategorys[1].settings, {
                controlType = CONTROL_TYPE.CHECKBOX_AND_EDITBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = spell.name .. "|T"..spell.texture..":14:14:1:0|t",
                tooltip = "启用/禁用",
                key = keyCheckbox,
                default = false,
                editbox = {
                    controlType = CONTROL_TYPE.EDITBOX,
                    settingType = SETTING_TYPE.ADDON_VARIABLE,
                    name = spell.name .. "|T"..spell.texture..":14:14:1:0|t",
                    tooltip = "自定义技能名称",
                    key = keyEditbox,
                    default = "",
                },
            })
        end
    end
    if #self.equippedItemSpells > 0 then
        table.insert(settings.subCategorys[1].settings, {
            controlType = CONTROL_TYPE.SECTION_HEADER,
            name = "装备列表",
        })
        for _, spell in ipairs(self.equippedItemSpells) do
            local keyCheckbox = string.format("CooldownDone.spell.%s.enable", spell.id)
            local keyEditbox = string.format("CooldownDone.spell.%s.name", spell.id)
            table.insert(settings.subCategorys[1].settings, {
                controlType = CONTROL_TYPE.CHECKBOX_AND_EDITBOX,
                settingType = SETTING_TYPE.ADDON_VARIABLE,
                name = spell.name .. "|T"..spell.texture..":14:14:1:0|t",
                tooltip = "启用/禁用",
                key = keyCheckbox,
                default = false,
                editbox = {
                    controlType = CONTROL_TYPE.EDITBOX,
                    settingType = SETTING_TYPE.ADDON_VARIABLE,
                    name = spell.name .. "|T"..spell.texture..":14:14:1:0|t",
                    tooltip = "自定义装备名称",
                    key = keyEditbox,
                    default = "",
                },
            })
        end
    end

    LibBlzSettings:RegisterVerticalSettingsTable(ADDON_NAME, settings, CooldownDoneDB, true)
end
