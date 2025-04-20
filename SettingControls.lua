CDDSettingsEditboxMixin = CreateFromMixins(CallbackRegistryMixin, DefaultTooltipMixin);
CDDSettingsEditboxMixin:GenerateCallbackEvents(
    {
        "OnValueChanged",
    }
);

function CDDSettingsEditboxMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self);
    DefaultTooltipMixin.OnLoad(self);
    self.tooltipXOffset = 0;
end

function CDDSettingsEditboxMixin:Init(value, initTooltip)
    self:SetValue(value);
    self:SetTooltipFunc(initTooltip);

    self:SetScript("OnTextChanged", function(editbox, userInput)
        self:TriggerEvent(CDDSettingsEditboxMixin.Event.OnValueChanged, editbox:GetText());
    end);
end

function CDDSettingsEditboxMixin:Release()
    self:SetScript("OnTextChanged", nil);
end

function CDDSettingsEditboxMixin:SetValue(value)
    self:SetText(value);
end

CDDSettingsEditboxControlMixin = CreateFromMixins(SettingsControlMixin);

function CDDSettingsEditboxControlMixin:OnLoad()
    SettingsControlMixin.OnLoad(self);

    self.Editbox = CreateFrame("EditBox", nil, self, "CDDSettingsEditboxTemplate");
    self.Editbox:SetPoint("LEFT", self, "CENTER", -72, 0);
end

function CDDSettingsEditboxControlMixin:Init(initializer)
    SettingsControlMixin.Init(self, initializer);

    local setting = self:GetSetting();
    local initTooltip = GenerateClosure(Settings.InitTooltip, initializer:GetName(), initializer:GetTooltip());
    self.Editbox:Init(setting:GetValue(), initTooltip);
    self.cbrHandles:RegisterCallback(self.Editbox, CDDSettingsEditboxMixin.Event.OnValueChanged, self.OnEditboxValueChanged, self);
    self:EvaluateState();
end

function CDDSettingsEditboxControlMixin:OnSettingValueChanged(setting, value)
    SettingsControlMixin.OnSettingValueChanged(self, setting, value);
end

function CDDSettingsEditboxControlMixin:OnEditboxValueChanged(value)
    self:GetSetting():SetValue(value);
end

function CDDSettingsEditboxControlMixin:EvaluateState()
    SettingsListElementMixin.EvaluateState(self);
    local enabled = SettingsControlMixin.IsEnabled(self);
    self.Editbox:SetEnabled(enabled);
    self:DisplayEnabled(enabled);
end

function CDDSettingsEditboxControlMixin:Release()
    self.Editbox:Release();
    SettingsControlMixin.Release(self);
end

CDDSettingsCheckboxEditboxControlMixin = CreateFromMixins(SettingsListElementMixin);

function CDDSettingsCheckboxEditboxControlMixin:OnLoad()
    SettingsListElementMixin.OnLoad(self);

    self.Checkbox = CreateFrame("CheckButton", nil, self, "SettingsCheckboxTemplate");
    self.Checkbox:SetPoint("LEFT", self, "CENTER", -80, 0);

    self.Control = CreateFrame("EditBox", nil, self, "CDDSettingsEditboxTemplate");
    self.Control:SetPoint("LEFT", self.Checkbox, "RIGHT", 10, 0);
    self.Control:SetWidth(200);

    Mixin(self.Control, DefaultTooltipMixin);

    self.Tooltip:SetScript("OnMouseUp", function()
        if self.Checkbox:IsEnabled() then
            self.Checkbox:Click();
        end
    end);
end

function CDDSettingsCheckboxEditboxControlMixin:Init(initializer)
    SettingsListElementMixin.Init(self, initializer);

    local cbSetting = initializer.data.cbSetting;
    local cbLabel = initializer.data.cbLabel;
    local cbTooltip = initializer.data.cbTooltip;
    local editboxSetting = initializer.data.editboxSetting;
    local editboxLabel = initializer.data.editboxLabel;
    local editboxTooltip = initializer.data.editboxTooltip;

    local initCheckboxTooltip = GenerateClosure(Settings.InitTooltip, cbLabel, cbTooltip);
    self:SetTooltipFunc(initCheckboxTooltip);

    self.Checkbox:Init(cbSetting:GetValue(), initCheckboxTooltip);
    self.cbrHandles:RegisterCallback(self.Checkbox, SettingsCheckboxMixin.Event.OnValueChanged, self.OnCheckboxValueChanged, self);

    local initEditboxTooltip = GenerateClosure(Settings.InitTooltip, editboxLabel, editboxTooltip);
    self.Control:Init(editboxSetting:GetValue(), initEditboxTooltip);
    self.cbrHandles:RegisterCallback(self.Control, CDDSettingsEditboxMixin.Event.OnValueChanged, self.OnEditboxValueChanged, self);
    self.Control:SetEnabled(cbSetting:GetValue());
end

function CDDSettingsCheckboxEditboxControlMixin:OnCheckboxValueChanged(value)
    local initializer = self:GetElementData();
    local cbSetting = initializer.data.cbSetting;
    cbSetting:SetValue(value);
    if value then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
    end

    self.Control:SetEnabled(value);
end

function CDDSettingsCheckboxEditboxControlMixin:OnEditboxValueChanged(value)
    local initializer = self:GetElementData();
    local editboxSetting = initializer.data.editboxSetting;
    editboxSetting:SetValue(value);
end

CDDSettingsEditboxButtonControlMixin = CreateFromMixins(SettingsListElementMixin);

function CDDSettingsEditboxButtonControlMixin:OnLoad()
    SettingsListElementMixin.OnLoad(self);

    self.Editbox = CreateFrame("EditBox", nil, self, "CDDSettingsEditboxTemplate");
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
        self.cbrHandles:RegisterCallback(self.Editbox, CDDSettingsEditboxMixin.Event.OnValueChanged, self.OnEditboxValueChanged, self);
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

CDDSettingsListSectionLabelMixin = CreateFromMixins();

function CDDSettingsListSectionLabelMixin:Init(initializer)
    local data = initializer:GetData();
    self.Title:SetText(data.name);
    self.Title:SetWidth(self:GetWidth() - 7)
    self:SetHeight(self.Title:GetStringHeight() + 10)
end