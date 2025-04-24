local LibBlzSettings = LibStub("LibBlzSettings-1.0")

CDDSettingsEditboxButtonControlMixin = CreateFromMixins(SettingsListElementMixin);

function CDDSettingsEditboxButtonControlMixin:OnLoad()
    SettingsListElementMixin.OnLoad(self);

    self.Editbox = CreateFrame("EditBox", nil, self, "LibBlzSettingsEditboxTemplate");
    self.Editbox:SetPoint("LEFT", self, "CENTER", -80, 0);
    self.Editbox:SetWidth(150);
    
    self.Button = CreateFrame("Button", nil, self, "UIPanelButtonTemplate");
    self.Button:SetWidth(100, 26);
    self.Button:SetPoint("LEFT", self.Editbox, "RIGHT", 5, 0);
    
    Mixin(self.Button, DefaultTooltipMixin);
    DefaultTooltipMixin.OnLoad(self.Button);
end

function CDDSettingsEditboxButtonControlMixin:Init(initializer)
    SettingsListElementMixin.Init(self, initializer);

    local setting = initializer.data.setting;
    local editboxLabel = initializer.data.editboxLabel or initializer.data.name;
    local editboxTooltip = initializer.data.editboxTooltip or initializer.data.tooltip;

    local initEditboxTooltip = GenerateClosure(Settings.InitTooltip, editboxLabel, editboxTooltip);
    self.Editbox:Init(setting and setting:GetValue() or "", initEditboxTooltip);
    if setting then
        self.cbrHandles:RegisterCallback(self.Editbox, LibBlzSettingsEditboxMixin.Event.OnValueChanged, self.OnEditboxValueChanged, self);
    end
    
    self.Button:SetText(initializer.data.buttonText);
    self.Button:SetScript("OnClick", function()
        initializer.data.OnButtonClick(self)
    end);
end

function CDDSettingsEditboxButtonControlMixin:OnEditboxValueChanged(value)
    local initializer = self:GetElementData();
    local setting = initializer.data.setting;
    setting:SetValue(value);
end

function CDDSettingsEditboxButtonControlMixin:Release()
    self.Editbox:Release();
    self.Button:SetScript("OnClick", nil);
    SettingsListElementMixin.Release(self);
end

function CDDSettingsEditboxAndButtonBuildFunction(addOnName, category, layout, dataTbl, database)
    local setting
    if dataTbl.key then
        setting = LibBlzSettings.RegisterSetting(addOnName, category, dataTbl, database, Settings.VarType.String, dataTbl.name)
    end
     local data = {
        key = dataTbl.key,
        name = dataTbl.name,
        tooltip = dataTbl.tooltip,
        setting = setting,
        editboxLabel = dataTbl.editboxLabel,
        editboxTooltip = dataTbl.editboxTooltip,
        buttonText = dataTbl.button.buttonText,
        OnButtonClick = dataTbl.button.OnButtonClick
    }
    local initializer = Settings.CreateSettingInitializer("CDDSettingsEditboxButtonControlTemplate", data)
    if dataTbl.canSearch or dataTbl.canSearch == nil then
        initializer:AddSearchTags(dataTbl.name)
    end
    layout:AddInitializer(initializer)
    return setting, initializer
end

LibBlzSettings.RegisterControl("EDITBOX_AND_BUTTON", function (addOnName, category, layout, dataTbl, database)
    return CDDSettingsEditboxAndButtonBuildFunction(addOnName, category, layout, dataTbl, database)
end, nil, nil)

CDDSettingsListSectionLabelMixin = CreateFromMixins();

function CDDSettingsListSectionLabelMixin:Init(initializer)
    local data = initializer:GetData();
    self.Title:SetText(data.name);
    self.Title:SetWidth(self:GetWidth() - 7)
    self:SetHeight(self.Title:GetStringHeight() + 10)
end

LibBlzSettings.RegisterControl("LABEL", function (addOnName, category, layout, dataTbl, database)
    local initializer = Settings.CreateSettingInitializer("CDDSettingsListSectionLabelTemplate", dataTbl)

    if dataTbl.canSearch or dataTbl.canSearch == nil then
        initializer:AddSearchTags(dataTbl.name)
    end

    layout:AddInitializer(initializer)

    return _, initializer
end, nil, nil)