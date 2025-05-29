if not(GetLocale() == "ruRU") then
    return
end

local ADDON_NAME, CooldownDone = ...

local L = CooldownDone.Locale
--Translator ZamestoTV
L["addonName"] = "Cooldown Done"
L["UnknownSpell"] = "Неизвестное заклинание"
L["UnknownItem"] = "Неизвестный предмет"
L["UnknownAura"] = "Неизвестная аура"
L["Ready"] = "готово"
L["ReadyTooltip"] = "Текст готовности навыка"
L["Expired"] = "истек"
L["ExpiredTooltip"] = "Текст окончания баффа"
L["Gained"] = "Получено"
L["GainedTooltip"] = "Текст получения баффа"
L["BuffList"] = "Баффы"
L["AbilityList"] = "Способности"
L["PleaseEnterID"] = "Пожалуйста, введите ID"
L["IDNotFound"] = "Не найдено, пожалуйста, введите правильный ID"
L["IDExists"] = "Уже существует"
L["CustomName"] = "Пользовательское имя\nИли ID звукового файла\nИли: Interface\\AddOns\\SomeAddOn\\SomeFile.ogg"
L["AuraExpired"] = "Бафф истек"
L["AuraGained"] = "Бафф получен"
L["EnableTooltip"] = "Включить/отключить функциональность плагина без перезагрузки интерфейса"
L["Debug"] = "Отладка"
L["DebugTooltip"] = "Включить/отключить отладочную информацию"
L["VoiceTooltip"] = "Выберите голос для использования"
L["VoiceSpeed"] = "Скорость речи"
L["Test"] = "Тест"
L["ClickToTest"] = "Нажмите для тестирования"
L["SpellName"] = "Название заклинания"
L["AbilityListTip"] = "Совет: Пожалуйста, перезагрузите игру после изменения талантов/изучения заклинаний/смены талантов/смены специализации!"
L["BuffListTip"] = "Совет: Пожалуйста, перезагрузите игру после удаления данных о баффах!"
L["SpellList"] = "Заклинания"
L["EquippedItemList"] = "Экипированные предметы"
L["AddBuff"] = "Добавить бафф"
L["AddBuffTooltip"] = "Введите ID, затем нажмите кнопку"
L["ERR_PlaySoundFile"] = "Ошибка воспроизведения звукового файла"
