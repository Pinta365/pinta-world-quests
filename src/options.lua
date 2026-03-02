-- Options panel for PintaWorldQuests

local addonName, AddonTable = ...

local function initOptionsPanel()
    local parent = (Settings and Settings.RegisterCanvasLayoutCategory) and UIParent or nil
    local optionsPanel = CreateFrame("Frame", "PintaWorldQuestsOptionsPanel", parent)
    optionsPanel.name = "Pinta World Quests"

    local header = optionsPanel:CreateFontString(nil, "overlay", "GameFontHighlightLarge")
    header:SetPoint("topleft", 16, -16)
    header:SetText("Pinta World Quests")

    local yOffset = -50

    local debugCheckbox = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    debugCheckbox:SetPoint("topleft", 16, yOffset)
    debugCheckbox.Text:SetText("Show Debug Messages")
    debugCheckbox.Text:SetFontObject("GameFontHighlightSmall")
    debugCheckbox:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.debug = self:GetChecked()
    end)
    optionsPanel.debugCheckbox = debugCheckbox
    yOffset = yOffset - 40

    local compactCheckbox = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    compactCheckbox:SetPoint("topleft", 16, yOffset)
    compactCheckbox.Text:SetText("Compact map overlay (no slot info)")
    compactCheckbox.Text:SetFontObject("GameFontHighlightSmall")
    compactCheckbox:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.compactMode = self:GetChecked()
        if AddonTable.refreshMapPanel then AddonTable.refreshMapPanel() end
    end)
    optionsPanel.compactCheckbox = compactCheckbox
    yOffset = yOffset - 50

    local scaleLabel = optionsPanel:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    scaleLabel:SetPoint("topleft", 16, yOffset)
    scaleLabel:SetText("List scale")

    local scaleSlider = CreateFrame("Slider", nil, optionsPanel, "OptionsSliderTemplate")
    scaleSlider:SetPoint("topleft", scaleLabel, "bottomleft", 0, -8)
    scaleSlider:SetWidth(200)
    scaleSlider:SetMinMaxValues(50, 150)
    scaleSlider:SetValueStep(5)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetValue((PintaWorldQuestsDB.listScale or 1.0) * 100)

    local scaleValueText = scaleSlider:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    scaleValueText:SetPoint("LEFT", scaleSlider, "RIGHT", 10, 0)

    local function UpdateScaleValue()
        scaleValueText:SetText(string.format("%d%%", scaleSlider:GetValue()))
    end
    UpdateScaleValue()

    scaleSlider:SetScript("OnValueChanged", function(self, value)
        PintaWorldQuestsDB.listScale = value / 100
        UpdateScaleValue()
        if AddonTable.mainFrame then AddonTable.mainFrame:SetScale(value / 100) end
    end)

    optionsPanel.scaleSlider = scaleSlider
    optionsPanel.scaleValueText = scaleValueText
    yOffset = yOffset - 80

    local opacityLabel = optionsPanel:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    opacityLabel:SetPoint("topleft", 16, yOffset)
    opacityLabel:SetText("Background opacity")

    local opacitySlider = CreateFrame("Slider", nil, optionsPanel, "OptionsSliderTemplate")
    opacitySlider:SetPoint("topleft", opacityLabel, "bottomleft", 0, -8)
    opacitySlider:SetWidth(200)
    opacitySlider:SetMinMaxValues(0, 100)
    opacitySlider:SetValueStep(5)
    opacitySlider:SetObeyStepOnDrag(true)
    opacitySlider:SetValue((PintaWorldQuestsDB.backgroundOpacity or 0.8) * 100)

    local opacityValueText = opacitySlider:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    opacityValueText:SetPoint("LEFT", opacitySlider, "RIGHT", 10, 0)

    local function UpdateOpacityValue()
        opacityValueText:SetText(string.format("%d%%", opacitySlider:GetValue()))
    end
    UpdateOpacityValue()

    opacitySlider:SetScript("OnValueChanged", function(self, value)
        PintaWorldQuestsDB.backgroundOpacity = value / 100
        UpdateOpacityValue()
        if AddonTable.mainFrame then
            AddonTable.mainFrame:SetBackdropColor(0.04, 0.03, 0.07, value / 100)
        end
    end)

    optionsPanel.opacitySlider = opacitySlider
    optionsPanel.opacityValueText = opacityValueText
    yOffset = yOffset - 80

    local mapPanelLabel = optionsPanel:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    mapPanelLabel:SetPoint("topleft", 16, yOffset)
    mapPanelLabel:SetText("In-map quest list")
    yOffset = yOffset - 26

    local rightSideCheckbox = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    rightSideCheckbox:SetPoint("topleft", 16, yOffset)
    rightSideCheckbox.Text:SetText("Show on right side of map")
    rightSideCheckbox.Text:SetFontObject("GameFontHighlightSmall")
    rightSideCheckbox:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.mapPanelSide = self:GetChecked() and "right" or "left"
        if AddonTable.applyMapPanelSide then AddonTable.applyMapPanelSide() end
    end)
    optionsPanel.rightSideCheckbox = rightSideCheckbox
    yOffset = yOffset - 50

    local resetBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 22)
    resetBtn:SetPoint("topleft", 16, yOffset)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("PINTAWQ_RESET_CONFIRM")
    end)

    local function RefreshOptions()
        if optionsPanel.debugCheckbox then
            optionsPanel.debugCheckbox:SetChecked(PintaWorldQuestsDB.debug == true)
        end
        if optionsPanel.scaleSlider then
            local scale = (PintaWorldQuestsDB.listScale or 1.0) * 100
            optionsPanel.scaleSlider:SetValue(scale)
            if optionsPanel.scaleValueText then
                optionsPanel.scaleValueText:SetText(string.format("%d%%", scale))
            end
        end
        if optionsPanel.opacitySlider then
            local opacity = (PintaWorldQuestsDB.backgroundOpacity or 0.8) * 100
            optionsPanel.opacitySlider:SetValue(opacity)
            if optionsPanel.opacityValueText then
                optionsPanel.opacityValueText:SetText(string.format("%d%%", opacity))
            end
        end
        if optionsPanel.compactCheckbox then
            optionsPanel.compactCheckbox:SetChecked(PintaWorldQuestsDB.compactMode == true)
        end
        if optionsPanel.rightSideCheckbox then
            optionsPanel.rightSideCheckbox:SetChecked(PintaWorldQuestsDB.mapPanelSide == "right")
        end
    end

    optionsPanel:SetScript("OnShow", RefreshOptions)
    RefreshOptions()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
        Settings.RegisterAddOnCategory(category)
        AddonTable.settingsCategory = category
    else
        InterfaceOptions_AddCategory(optionsPanel)
        AddonTable.optionsPanel = optionsPanel
    end
end

AddonTable.initOptionsPanel = initOptionsPanel
