-- Initialize Saved Variables with defaults if they do not exist
MyTimeDisplayData = MyTimeDisplayData or {
    sliders = {frameOpacity = 80}, -- Default opacity value
    checkboxes = {true, true, true, true, true}, -- Default checkbox states
    position = {point = "CENTER", relativeTo = nil, relativePoint = "CENTER", xOfs = 0, yOfs = 0}, -- Default position
    frameSize = {width = 150, height = 60} -- Default frame size
}

-- Function to initialize settings with default valuest if missing
local function InitializeSettings()
    local defaults = {
        sliders = {frameOpacity = 80},
        checkboxes = {true, true, true, true, true},
        position = {point = "CENTER", relativeTo = nil, relativePoint = "CENTER", xOfs = 0, yOfs = 0},
        frameSize = {width = 150, height = 60}
    }

    for key, value in pairs(defaults) do
        if MyTimeDisplayData[key] == nil then
            MyTimeDisplayData[key] = value
        else
            for subKey, subValue in pairs(value) do
                if MyTimeDisplayData[key][subKey] == nil then
                    MyTimeDisplayData[key][subKey] = subValue
                end
            end
        end
    end
end

-- Helper function to convert 24-hour time to 12-hour format with AM/PM
local function ConvertTo12Hour(hour, minute)
    local suffix = "AM"
    if hour >= 12 then
        suffix = "PM"
        if hour > 12 then hour = hour - 12 end
    elseif hour == 0 then
        hour = 12
    end
    return string.format("%d:%02d %s", hour, minute, suffix)
end

-- Helper function to get the correct suffix for a day number
local function GetDaySuffix(day)
    local suffix = "th"
    if day % 10 == 1 and day ~= 11 then
        suffix = "st"
    elseif day % 10 == 2 and day ~= 12 then
        suffix = "nd"
    elseif day % 10 == 3 and day ~= 13 then
        suffix = "rd"
    end
    return suffix
end

-- Gemstone-based colors for each month
local monthColors = {
    Jan = "|cffb93a3a", -- Garnet (deep red)
    Feb = "|cffa987c5", -- Amethyst (purple)
    Mar = "|cff77ddbb", -- Aquamarine (light teal)
    Apr = "|cffe1e1e1", -- Diamond (white/silver)
    May = "|cff00a86b", -- Emerald (green)
    Jun = "|cfffde8a8", -- Pearl (cream)
    Jul = "|cffff0000", -- Ruby (red)
    Aug = "|cfff5bd1f", -- Peridot (lime green)
    Sep = "|cff0f52ba", -- Sapphire (deep blue)
    Oct = "|cfffc8eac", -- Opal/Pink Tourmaline (pink)
    Nov = "|cffda9100", -- Topaz (orange)
    Dec = "|cff00bfff"  -- Blue Topaz (sky blue)
}

-- Helper function to get the gemstone color for the current month
local function GetMonthColor()
    local monthAbbr = date("%b")  -- Abbreviated month (e.g., "Oct")
    return monthColors[monthAbbr] or "|cffffffff"  -- Default to white if not found
end

-- Main frame for time display
local frame = CreateFrame("Frame", "MyTimeDisplayFrame", UIParent, "BackdropTemplate")
frame:SetSize(150, 60)  -- Frame size (width, height)
frame:SetPoint("CENTER") -- Default position
frame:SetClampedToScreen(true)
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)  -- Background color (black with transparency)
frame:SetBackdropBorderColor(0, 0, 0)  -- Border color (black)

-- Make the frame movable
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    MyTimeDisplayData.position.point = point
    MyTimeDisplayData.position.relativePoint = relativePoint
    MyTimeDisplayData.position.xOfs = xOfs or 0
    MyTimeDisplayData.position.yOfs = yOfs or 0
end)

-- Font string to display the information
local timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
timeText:SetPoint("CENTER", frame, "CENTER", 0, 0)

-- Settings frame for time display options
local TimeDisplaySettingsFrame = CreateFrame("Frame", "TimeDisplaySettingsFrame", UIParent, "BackdropTemplate")
TimeDisplaySettingsFrame:SetSize(180, 250) -- Adjusted size
TimeDisplaySettingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Centered initially
TimeDisplaySettingsFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 4, edgeSize = 8,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TimeDisplaySettingsFrame:SetBackdropColor(0, 0, 0, 0.8)
TimeDisplaySettingsFrame:SetBackdropBorderColor(0, 0, 0)
TimeDisplaySettingsFrame:Hide()

-- Make the settings frame movable
TimeDisplaySettingsFrame:EnableMouse(true)
TimeDisplaySettingsFrame:SetMovable(true)
TimeDisplaySettingsFrame:RegisterForDrag("LeftButton")
TimeDisplaySettingsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
TimeDisplaySettingsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- Title text for settings frame
local settingsTitle = TimeDisplaySettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
settingsTitle:SetPoint("TOP", TimeDisplaySettingsFrame, "TOP", 0, -10)
settingsTitle:SetText("|cff00ff00Settings|r")

-- Close button for the settings frame
local closeButton = CreateFrame("Button", nil, TimeDisplaySettingsFrame)
closeButton:SetSize(24, 24)
closeButton:SetPoint("TOPRIGHT", TimeDisplaySettingsFrame, "TOPRIGHT", -5, -5)
closeButton:SetNormalTexture("Interface\\AddOns\\MyTimeDisplay\\close.png")

closeButton:EnableMouse(true)
closeButton:SetScript("OnEnter", function(self)
    self:GetNormalTexture():SetVertexColor(1, 0, 0) -- Red color on highlight
end)
closeButton:SetScript("OnLeave", function(self)
    self:GetNormalTexture():SetVertexColor(1, 1, 1) -- Reset color
end)
closeButton:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        self:GetNormalTexture():SetVertexColor(1, 0, 0) -- Red color when pressed
        TimeDisplaySettingsFrame:Hide()
    end
end)

TimeDisplaySettingsFrame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        self:Hide()
    end
end)

-- Function to create a checkbox
local function CreateCheckbox(parent, label, yOffset, tooltip, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    checkbox.Text:SetText(label)
    checkbox.tooltip = tooltip
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    checkbox:SetScript("OnClick", function(self)
        if self:GetChecked() then
            self.Text:SetTextColor(1, 1, 0) -- Yellow
            if onClick then onClick(true) end
        else
            self.Text:SetTextColor(0.5, 0.5, 0.5) -- Gray
            if onClick then onClick(false) end
        end
        MyTimeDisplayData.checkboxes[self:GetID()] = self:GetChecked() -- Save state
    end)
    -- Set initial color
    checkbox:SetChecked(false)
    checkbox.Text:SetTextColor(0.5, 0.5, 0.5) -- Gray
    return checkbox
end

-- Update the time and date based on selected options
local function UpdateTime()
    local showLocalTime = MyTimeDisplayData.checkboxes[1]
    local showServerTime = MyTimeDisplayData.checkboxes[2]
    local showDateInfo = MyTimeDisplayData.checkboxes[3]
    local use12HourFormat = MyTimeDisplayData.checkboxes[4]

    local serverHour, serverMinute = GetGameTime()
    local localTimeTable = date("*t")
    local localHour = localTimeTable.hour
    local localMinute = localTimeTable.min

    local localTime = showLocalTime and (use12HourFormat and ConvertTo12Hour(localHour, localMinute) or string.format("%02d:%02d", localHour, localMinute)) or ""
    local serverTime = showServerTime and (use12HourFormat and ConvertTo12Hour(serverHour, serverMinute) or string.format("%02d:%02d", serverHour, serverMinute)) or ""

    local localLabel = showLocalTime and string.format("|cff00ff00Local|r: %s", localTime) or ""
    local serverLabel = showServerTime and string.format("|cffffd700Server|r: %s", serverTime) or ""

    local dateText = ""
    if showDateInfo then
        local dayName = date("%A")
        local dayNumber = tonumber(date("%d"))
        local daySuffix = GetDaySuffix(dayNumber)
        local monthColor = GetMonthColor()
        local monthAbbr = date("%b")
        dateText = string.format("%s%s |cffffffff%d|r%s |cffffffff%s|r", monthColor, monthAbbr, dayNumber, daySuffix, dayName)
    end

    local text = string.format("%s\n%s\n%s", localLabel, serverLabel, dateText)
    timeText:SetText(text)

    C_Timer.After(0.01, function()
        local textWidth = timeText:GetStringWidth() + 15
        local textHeight = timeText:GetStringHeight() + 10
        frame:SetSize(textWidth, textHeight)
    end)
end

-- Table to store checkboxes
local checkboxes = {}

-- Function to create and initialize checkboxes
local function CreateAndInitializeCheckboxes()
    local labels = {
        "Show Local Time",
        "Show Server Time",
        "Show Date Info",
        "Use 12-Hour Format",
        "Show Backdrop"
    }
    local tooltips = {
        "Toggle the display of local time",
        "Toggle the display of server time",
        "Toggle the display of date information",
        "Toggle the use of 12-hour time format",
        "Toggle the display of the backdrop"
    }
    local yOffset = -40

    for i = 1, #labels do
        local checkbox = CreateCheckbox(TimeDisplaySettingsFrame, labels[i], yOffset, tooltips[i], function(checked)
            MyTimeDisplayData.checkboxes[i] = checked
            if i == 5 then
                frame:SetBackdropBorderColor(0, 0, 0, checked and 1 or 0)
            else
                UpdateTime()
            end
        end)
        checkbox:SetID(i)
        checkboxes[i] = checkbox
        yOffset = yOffset - 20
    end
end

-- Create and initialize checkboxes
CreateAndInitializeCheckboxes()

-- Create opacity slider
local opacitySlider = CreateFrame("Slider", "FrameOpacitySlider", TimeDisplaySettingsFrame, "OptionsSliderTemplate")
opacitySlider:SetPoint("TOPLEFT", 10, -160)
opacitySlider:SetMinMaxValues(0, 100)
opacitySlider:SetValueStep(1)
opacitySlider:SetValue(MyTimeDisplayData.sliders.frameOpacity)
opacitySlider:SetScript("OnValueChanged", function(self, value)
    frame:SetBackdropColor(0, 0, 0, value / 100)
    MyTimeDisplayData.sliders.frameOpacity = value
end)
_G[opacitySlider:GetName() .. 'Low']:SetText('  0')
_G[opacitySlider:GetName() .. 'High']:SetText('100')
_G[opacitySlider:GetName() .. 'Text']:SetText('Background Opacity')

-- Function to save current settings
local function SaveSettings()
    MyTimeDisplayData.sliders.frameOpacity = opacitySlider:GetValue()
    for i = 1, 5 do
        MyTimeDisplayData.checkboxes[i] = checkboxes[i]:GetChecked()
    end
    -- Save the backdrop state
    MyTimeDisplayData.showBackdrop = checkboxes[5]:GetChecked()
end

-- Create save button for the settings frame
local saveButton = CreateFrame("Button", nil, TimeDisplaySettingsFrame, "UIPanelButtonTemplate")
saveButton:SetSize(80, 22)
saveButton:SetPoint("BOTTOM", TimeDisplaySettingsFrame, "BOTTOM", 0, 10)
saveButton:SetText("Save")
saveButton:SetScript("OnClick", function()
    SaveSettings()
    TimeDisplaySettingsFrame:Hide()
end)

-- Function to load saved settings into checkboxes and slider
local function LoadCheckboxStates()
    for i = 1, 5 do
        checkboxes[i]:SetChecked(MyTimeDisplayData.checkboxes[i])
        if checkboxes[i]:GetChecked() then
            checkboxes[i].Text:SetTextColor(1, 1, 0) -- Yellow
        else
            checkboxes[i].Text:SetTextColor(0.5, 0.5, 0.5) -- Gray
        end
    end
    opacitySlider:SetValue(MyTimeDisplayData.sliders.frameOpacity)
    frame:SetBackdropColor(0, 0, 0, MyTimeDisplayData.sliders.frameOpacity / 100)
    -- Load the backdrop state
    frame:SetBackdropBorderColor(0, 0, 0, MyTimeDisplayData.showBackdrop and 1 or 0)
end

-- Event handler to load saved settings
local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MyTimeDisplay" then
        InitializeSettings()  -- Initialize settings only once
        LoadCheckboxStates()  -- Load the saved checkbox states
        -- Restore frame position
        if MyTimeDisplayData and MyTimeDisplayData.position then
            local pos = MyTimeDisplayData.position
            self:ClearAllPoints()
            self:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.xOfs or 0, pos.yOfs or 0)
        end
        UpdateTime()
    elseif event == "PLAYER_LOGOUT" then
        SaveSettings()  -- Save current settings
    end
end

-- Register events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", OnEvent)

-- Tooltip for the main frame
frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(date("%A, %B %d, %Y"))
    GameTooltip:AddLine(date("%I:%M %p"))
    GameTooltip:AddLine("Right-click for settings", 1, 1, 1)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Toggle the settings frame on right-click
frame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        TimeDisplaySettingsFrame:SetShown(not TimeDisplaySettingsFrame:IsShown())
        LoadCheckboxStates() -- Ensure the settings are loaded when the frame is shown
    end
end)

-- Initialize settings
InitializeSettings()

-- Load the saved settings
LoadCheckboxStates()

-- Set a repeating timer to update the time every second
frame:SetScript("OnUpdate", function(self, elapsed)
    self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
    if self.timeSinceLastUpdate >= 1 then  -- Update every 1 second
        UpdateTime()
        self.timeSinceLastUpdate = 0
    end
end)
