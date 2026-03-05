-- Options panel for PintaWorldQuests

local addonName, AddonTable = ...

-- ---------------------------------------------------------------------------
-- Layout helpers
-- ---------------------------------------------------------------------------

local INDENT = 16
local SECTION_GAP = 14  -- gap above section header
local AFTER_HEADER = 8  -- gap below section header before first control
local ROW_CHECK = 28
local ROW_SLIDER = 58

local function sectionHeader(parent, label, yOffset)
    local fs = parent:CreateFontString(nil, "overlay", "GameFontNormal")
    fs:SetPoint("TOPLEFT", INDENT, yOffset)
    fs:SetText(label)
    local line = parent:CreateTexture(nil, "BACKGROUND")
    line:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 6, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -INDENT, 0)
    return yOffset - AFTER_HEADER
end

local function checkbox(parent, label, yOffset)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", INDENT, yOffset)
    cb.Text:SetText(label)
    cb.Text:SetFontObject("GameFontHighlightSmall")
    return cb, yOffset - ROW_CHECK
end

local function slider(parent, label, min, max, step, yOffset)
    local lbl = parent:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    lbl:SetPoint("TOPLEFT", INDENT, yOffset)
    lbl:SetText(label)

    local sl = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -6)
    sl:SetWidth(200)
    sl:SetMinMaxValues(min, max)
    sl:SetValueStep(step)
    sl:SetObeyStepOnDrag(true)

    local valText = sl:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    valText:SetPoint("LEFT", sl, "RIGHT", 10, 0)

    return sl, valText, yOffset - ROW_SLIDER
end

-- Simple dropdown built from UIDropDownMenu
local function dropdown(parent, items, yOffset, width, xPos)
    width = width or 160
    xPos  = xPos  or INDENT
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", xPos - 15, yOffset)
    UIDropDownMenu_SetWidth(dd, width)

    dd.items = items

    local function initialize(self, level)
        for _, item in ipairs(self.items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text     = item.label
            info.value    = item.label
            info.func     = function(btn)
                UIDropDownMenu_SetSelectedValue(self, btn.value)
                if self.onChange then self.onChange(btn.value) end
            end
            info.checked  = false
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(dd, initialize)
    return dd, yOffset - 36
end

-- ---------------------------------------------------------------------------
-- Build panel
-- ---------------------------------------------------------------------------

local function initOptionsPanel()
    local parent = (Settings and Settings.RegisterCanvasLayoutCategory) and UIParent or nil
    local panel = CreateFrame("Frame", "PintaWorldQuestsOptionsPanel", parent)
    panel.name = "Pinta World Quests"

    local header = panel:CreateFontString(nil, "overlay", "GameFontHighlightLarge")
    header:SetPoint("TOPLEFT", INDENT, -INDENT)
    header:SetText("Pinta World Quests")

    local y = -46

    -- -----------------------------------------------------------------------
    -- Section: Display
    -- -----------------------------------------------------------------------
    y = sectionHeader(panel, "Display", y - SECTION_GAP)

    local compactCb
    compactCb, y = checkbox(panel, "Compact map overlay (no slot info)", y)
    compactCb:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.compactMode = self:GetChecked()
        if AddonTable.refreshMapPanel then AddonTable.refreshMapPanel() end
    end)
    panel.compactCheckbox = compactCb

    local extTooltipCb
    extTooltipCb, y = checkbox(panel, "Extended tooltips (objectives + item stats)", y)
    extTooltipCb:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.extendedTooltips = self:GetChecked()
    end)
    panel.extendedTooltipCheckbox = extTooltipCb

    local skinPinsCb
    skinPinsCb, y = checkbox(panel, "Replace quest pin icons with reward icons", y)
    skinPinsCb:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.skinQuestPins = self:GetChecked()
    end)
    panel.skinPinsCheckbox = skinPinsCb

    local scaleSl, scaleVal
    scaleSl, scaleVal, y = slider(panel, "List scale", 50, 150, 5, y)
    scaleSl:SetScript("OnValueChanged", function(self, value)
        PintaWorldQuestsDB.listScale = value / 100
        scaleVal:SetText(string.format("%d%%", value))
        if AddonTable.mainFrame then AddonTable.mainFrame:SetScale(value / 100) end
    end)
    panel.scaleSlider    = scaleSl
    panel.scaleValueText = scaleVal

    local opacitySl, opacityVal
    opacitySl, opacityVal, y = slider(panel, "Background opacity", 0, 100, 5, y)
    opacitySl:SetScript("OnValueChanged", function(self, value)
        PintaWorldQuestsDB.backgroundOpacity = value / 100
        opacityVal:SetText(string.format("%d%%", value))
        if AddonTable.mainFrame then
            AddonTable.mainFrame:SetBackdropColor(0.04, 0.03, 0.07, value / 100)
        end
    end)
    panel.opacitySlider    = opacitySl
    panel.opacityValueText = opacityVal

    -- -----------------------------------------------------------------------
    -- Section: Map panel
    -- -----------------------------------------------------------------------
    y = sectionHeader(panel, "Map panel", y - SECTION_GAP)

    local rightSideCb
    rightSideCb, y = checkbox(panel, "Show on right side of map", y)
    rightSideCb:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.mapPanelSide = self:GetChecked() and "right" or "left"
        if AddonTable.applyMapPanelSide then AddonTable.applyMapPanelSide() end
    end)
    panel.rightSideCheckbox = rightSideCb

    -- -----------------------------------------------------------------------
    -- Section: Expiry alerts  (two-column layout)
    -- -----------------------------------------------------------------------
    y = sectionHeader(panel, "Expiry alerts", y - SECTION_GAP)

    local alertEnabledCb
    alertEnabledCb, y = checkbox(panel, "Enable expiry alerts", y)
    panel.alertEnabledCheckbox = alertEnabledCb

    local RIGHT_COL = 210
    local y_left = y
    local y_right = y + 8
    local updateAlertSubControls

    -- LEFT COLUMN: alert scope radios

    local scopeLabel = panel:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    scopeLabel:SetPoint("TOPLEFT", INDENT, y_left)
    scopeLabel:SetText("Alert scope")
    y_left = y_left - 20

    local radioAll = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
    radioAll:SetPoint("TOPLEFT", INDENT, y_left)
    radioAll.text:SetText("All known quests")
    radioAll.text:SetFontObject("GameFontHighlightSmall")
    y_left = y_left - 24

    local radioCurrent = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
    radioCurrent:SetPoint("TOPLEFT", INDENT, y_left)
    radioCurrent.text:SetText("Expansion filter")
    radioCurrent.text:SetFontObject("GameFontHighlightSmall")
    y_left = y_left - 10

    radioAll:SetScript("OnClick", function(self)
        self:SetChecked(true)
        radioCurrent:SetChecked(false)
        PintaWorldQuestsDB.alertScope = "all"
    end)
    radioCurrent:SetScript("OnClick", function(self)
        self:SetChecked(true)
        radioAll:SetChecked(false)
        PintaWorldQuestsDB.alertScope = "filter"
    end)

    -- RIGHT COLUMN: threshold dropdown, play sound, sound dropdown

    local threshLabel = panel:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    threshLabel:SetPoint("TOPLEFT", RIGHT_COL, y_right)
    threshLabel:SetText("Alert threshold")
    y_right = y_right - 14

    local THRESHOLDS = {
        { label = "15 minutes", value = 900  },
        { label = "30 minutes", value = 1800 },
        { label = "45 minutes", value = 2700 },
        { label = "60 minutes", value = 3600 },
    }
    local threshDD
    threshDD, y_right = dropdown(panel, THRESHOLDS, y_right, 130, RIGHT_COL)
    threshDD.onChange = function(label)
        for _, t in ipairs(THRESHOLDS) do
            if t.label == label then
                PintaWorldQuestsDB.alertThreshold = t.value
                break
            end
        end
    end
    panel.alertThresholdDropdown = threshDD

    local playSoundCb = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    playSoundCb:SetPoint("TOPLEFT", RIGHT_COL, y_right)
    playSoundCb.Text:SetText("Play sound")
    playSoundCb.Text:SetFontObject("GameFontHighlightSmall")
    y_right = y_right - ROW_CHECK
    panel.playSoundCheckbox = playSoundCb

    local soundLabel = panel:CreateFontString(nil, "overlay", "GameFontHighlightSmall")
    soundLabel:SetPoint("TOPLEFT", RIGHT_COL, y_right)
    soundLabel:SetText("Sound")
    y_right = y_right - 14

    local soundItems = {}
    for _, s in ipairs(AddonTable.ALERT_SOUNDS) do
        soundItems[#soundItems + 1] = { label = s.label }
    end
    local soundDD
    soundDD, y_right = dropdown(panel, soundItems, y_right, 130, RIGHT_COL)
    soundDD.onChange = function(label)
        PintaWorldQuestsDB.alertSound = label
        local channel = PintaWorldQuestsDB.alertChannel or "Master"
        for _, s in ipairs(AddonTable.ALERT_SOUNDS) do
            if s.label == label and s.soundKit then
                PlaySound(s.soundKit, channel)
                break
            end
        end
        updateAlertSubControls()
    end
    panel.alertSoundDropdown = soundDD

    local CHANNELS = {
        { label = "Master"   },
        { label = "SFX"      },
        { label = "Music"    },
        { label = "Ambience" },
        { label = "Dialog"   },
    }
    local channelDD
    channelDD, y_right = dropdown(panel, CHANNELS, y_right, 130, RIGHT_COL)
    channelDD.onChange = function(label)
        PintaWorldQuestsDB.alertChannel = label
        local soundLabel = PintaWorldQuestsDB.alertSound
        if soundLabel then
            for _, s in ipairs(AddonTable.ALERT_SOUNDS) do
                if s.label == soundLabel and s.soundKit then
                    PlaySound(s.soundKit, label)
                    break
                end
            end
        end
    end
    panel.alertChannelDropdown = channelDD

    y = math.min(y_left, y_right)

    updateAlertSubControls = function()
        local alertOn = alertEnabledCb:GetChecked()
        local soundOn = alertOn and playSoundCb:GetChecked()
        threshLabel:SetAlpha(alertOn and 1 or 0.4)
        scopeLabel:SetAlpha(alertOn and 1 or 0.4)
        soundLabel:SetAlpha(soundOn and 1 or 0.4)
        radioAll:SetEnabled(alertOn)
        radioCurrent:SetEnabled(alertOn)
        if alertOn then
            UIDropDownMenu_EnableDropDown(threshDD)
        else
            UIDropDownMenu_DisableDropDown(threshDD)
        end
        local raidWarning = soundOn and UIDropDownMenu_GetSelectedValue(soundDD) == "Raid Warning"
        if soundOn then
            UIDropDownMenu_EnableDropDown(soundDD)
        else
            UIDropDownMenu_DisableDropDown(soundDD)
        end
        if soundOn and not raidWarning then
            UIDropDownMenu_EnableDropDown(channelDD)
        else
            UIDropDownMenu_DisableDropDown(channelDD)
        end
    end

    alertEnabledCb:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.alertEnabled = self:GetChecked()
        updateAlertSubControls()
    end)
    playSoundCb:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.alertSound = self:GetChecked() and
            (UIDropDownMenu_GetSelectedValue(soundDD) or "Raid Warning") or nil
        updateAlertSubControls()
    end)

    -- -----------------------------------------------------------------------
    -- Section: Advanced
    -- -----------------------------------------------------------------------
    y = sectionHeader(panel, "Advanced", y - SECTION_GAP)

    local debugCb
    debugCb, y = checkbox(panel, "Show debug messages", y)
    debugCb:SetScript("OnClick", function(self)
        PintaWorldQuestsDB.debug = self:GetChecked()
    end)
    panel.debugCheckbox = debugCb

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 22)
    resetBtn:SetPoint("TOPLEFT", INDENT, y)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("PINTAWQ_RESET_CONFIRM")
    end)

    -- -----------------------------------------------------------------------
    -- Refresh
    -- -----------------------------------------------------------------------
    local function RefreshOptions()
        debugCb:SetChecked(PintaWorldQuestsDB.debug == true)
        compactCb:SetChecked(PintaWorldQuestsDB.compactMode == true)
        extTooltipCb:SetChecked(PintaWorldQuestsDB.extendedTooltips == true)
        skinPinsCb:SetChecked(PintaWorldQuestsDB.skinQuestPins ~= false)
        rightSideCb:SetChecked(PintaWorldQuestsDB.mapPanelSide == "right")

        local scale = (PintaWorldQuestsDB.listScale or 1.0) * 100
        scaleSl:SetValue(scale)
        scaleVal:SetText(string.format("%d%%", scale))

        local opacity = (PintaWorldQuestsDB.backgroundOpacity or 0.8) * 100
        opacitySl:SetValue(opacity)
        opacityVal:SetText(string.format("%d%%", opacity))

        -- Alerts
        alertEnabledCb:SetChecked(PintaWorldQuestsDB.alertEnabled ~= false)

        local thresh = PintaWorldQuestsDB.alertThreshold or 1800
        for _, t in ipairs(THRESHOLDS) do
            if t.value == thresh then
                UIDropDownMenu_SetSelectedValue(threshDD, t.label)
                UIDropDownMenu_SetText(threshDD, t.label)
                break
            end
        end

        local scope = PintaWorldQuestsDB.alertScope or "all"
        radioAll:SetChecked(scope == "all")
        radioCurrent:SetChecked(scope == "filter")

        local soundVal = PintaWorldQuestsDB.alertSound
        playSoundCb:SetChecked(soundVal ~= nil)
        if soundVal then
            UIDropDownMenu_SetSelectedValue(soundDD, soundVal)
            UIDropDownMenu_SetText(soundDD, soundVal)
        else
            UIDropDownMenu_SetText(soundDD, "None")
        end

        local channelVal = PintaWorldQuestsDB.alertChannel or "Master"
        UIDropDownMenu_SetSelectedValue(channelDD, channelVal)
        UIDropDownMenu_SetText(channelDD, channelVal)

        updateAlertSubControls()
    end

    panel:SetScript("OnShow", RefreshOptions)
    RefreshOptions()

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        AddonTable.settingsCategory = category
    else
        InterfaceOptions_AddCategory(panel)
        AddonTable.optionsPanel = panel
    end
end

AddonTable.initOptionsPanel = initOptionsPanel
