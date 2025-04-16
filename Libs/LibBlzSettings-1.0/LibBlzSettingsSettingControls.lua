LibBlzSettingsEditboxMixin = CreateFromMixins(CallbackRegistryMixin, DefaultTooltipMixin);
LibBlzSettingsEditboxMixin:GenerateCallbackEvents(
    {
        "OnValueChanged",
    }
);

function LibBlzSettingsEditboxMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self);
    DefaultTooltipMixin.OnLoad(self);
    self.tooltipXOffset = 0;
end

function LibBlzSettingsEditboxMixin:Init(value, initTooltip)
    self:SetValue(value);
    self:SetTooltipFunc(initTooltip);

    self:SetScript("OnTextChanged", function(editbox, userInput)
        self:TriggerEvent(LibBlzSettingsEditboxMixin.Event.OnValueChanged, editbox:GetText());
    end);
end

function LibBlzSettingsEditboxMixin:Release()
    self:SetScript("OnTextChanged", nil);
end

function LibBlzSettingsEditboxMixin:SetValue(value)
    self:SetText(value);
end

LibBlzSettingsEditboxControlMixin = CreateFromMixins(SettingsControlMixin);

function LibBlzSettingsEditboxControlMixin:OnLoad()
    SettingsControlMixin.OnLoad(self);

    self.Editbox = CreateFrame("EditBox", nil, self, "LibBlzSettingsEditboxTemplate");
    self.Editbox:SetPoint("LEFT", self, "CENTER", -80, 0);
end

function LibBlzSettingsEditboxControlMixin:Init(initializer)
    SettingsControlMixin.Init(self, initializer);

    local setting = self:GetSetting();
    local initTooltip = GenerateClosure(Settings.InitTooltip, initializer:GetName(), initializer:GetTooltip());
    self.Editbox:Init(setting:GetValue(), initTooltip);
    self.cbrHandles:RegisterCallback(self.Editbox, LibBlzSettingsEditboxMixin.Event.OnValueChanged, self.OnEditboxValueChanged, self);
    self:EvaluateState();
end

function LibBlzSettingsEditboxControlMixin:OnSettingValueChanged(setting, value)
    SettingsControlMixin.OnSettingValueChanged(self, setting, value);
end

function LibBlzSettingsEditboxControlMixin:OnEditboxValueChanged(value)
    self:GetSetting():SetValue(value);
end

function LibBlzSettingsEditboxControlMixin:EvaluateState()
    SettingsListElementMixin.EvaluateState(self);
    local enabled = SettingsControlMixin.IsEnabled(self);
    self.Editbox:SetEnabled(enabled);
    self:DisplayEnabled(enabled);
end

function LibBlzSettingsEditboxControlMixin:Release()
    self.Editbox:Release();
    SettingsControlMixin.Release(self);
end

LibBlzSettingsCheckboxEditboxControlMixin = CreateFromMixins(SettingsListElementMixin);

function LibBlzSettingsCheckboxEditboxControlMixin:OnLoad()
    SettingsListElementMixin.OnLoad(self);

    self.Checkbox = CreateFrame("CheckButton", nil, self, "SettingsCheckboxTemplate");
    self.Checkbox:SetPoint("LEFT", self, "CENTER", -80, 0);

    self.Control = CreateFrame("EditBox", nil, self, "LibBlzSettingsEditboxTemplate");
    self.Control:SetPoint("LEFT", self.Checkbox, "RIGHT", 10, 0);
    self.Control:SetWidth(200);

    Mixin(self.Control, DefaultTooltipMixin);

    self.Tooltip:SetScript("OnMouseUp", function()
        if self.Checkbox:IsEnabled() then
            self.Checkbox:Click();
        end
    end);
end

function LibBlzSettingsCheckboxEditboxControlMixin:Init(initializer)
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
    self.cbrHandles:RegisterCallback(self.Control, LibBlzSettingsEditboxMixin.Event.OnValueChanged, self.OnEditboxValueChanged, self);
    self.Control:SetEnabled(cbSetting:GetValue());
end

function LibBlzSettingsCheckboxEditboxControlMixin:OnCheckboxValueChanged(value)
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

function LibBlzSettingsCheckboxEditboxControlMixin:OnEditboxValueChanged(value)
    local initializer = self:GetElementData();
    local editboxSetting = initializer.data.editboxSetting;
    editboxSetting:SetValue(value);
end

function LibBlzSettingsCheckboxEditboxControlMixin:Release()
    self.Checkbox:Release();
    SettingsListElementMixin.Release(self);
end
