-- Addon initialization (AceAddon)
local MyTimeDisplay = LibStub("AceAddon-3.0"):NewAddon("MyTimeDisplay", "AceEvent-3.0", "AceConsole-3.0")

-- Optional LibSharedMedia-3.0
local LSM = LibStub("LibSharedMedia-3.0", true)
local AceDBOptions = LibStub("AceDBOptions-3.0", true)
local LDB = LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub("LibDBIcon-1.0", true)

-- Layout timer tracking
local layoutTimer = nil

-- Defaults (SavedVariables)
local defaults = {
    profile = {
        sliders = {frameOpacity = 80, frameScale = 1.0},
        checkboxes = {true, true, true, true, true},
        position = {point = "CENTER", relativeTo = nil, relativePoint = "CENTER", xOfs = 0, yOfs = 0},
        frameSize = {width = 150, height = 60},
        showBackdrop = true,
        font = "Friz Quadrata TT",
        fontSize = 12,
        fontOutline = "OUTLINE",
        horizontalLayout = false,
        lockFrame = false,
        minimap = { hide = false },
        useCustomTextColor = false,
        customTextColor = {r = 1, g = 1, b = 1, a = 1},
        textAlignment = "CENTER",
        backdropTexture = "UI-Tooltip-Background",
        borderTexture = "UI-Tooltip-Border",
        useAbbreviatedTimeLabels = false,
        spacing = { vertical = 3, horizontal = 10 },
        padding = { vertical = 5, horizontal = 10 },
        backdropColors = {
            backgroundColor = {r = 0, g = 0, b = 0},
            borderColor = {r = 1, g = 1, b = 1},
            borderOpacity = 0.8,
        },
    }
}

-- Helper function to apply backdrop textures from LibSharedMedia
function MyTimeDisplay:ApplyBackdropTextures()
    if not self.frame then return end
    local frame = self.frame
    -- Defaults
    local bgTexture = "Interface/Tooltips/UI-Tooltip-Background"
    local borderTexture = "Interface/Tooltips/UI-Tooltip-Border"
    -- Resolve stored textures via LibSharedMedia
    if self.db and self.db.profile then
        local storedBg = self.db.profile.backdropTexture
        local storedBorder = self.db.profile.borderTexture
        if storedBg and storedBg ~= "" and LSM then
            bgTexture = LSM:Fetch("background", storedBg) or bgTexture
        end
        if storedBorder and storedBorder ~= "" and LSM then
            borderTexture = LSM:Fetch("border", storedBorder) or borderTexture
        end
    end
    -- Opacity
    local opacity = (self.db and self.db.profile and self.db.profile.sliders and (self.db.profile.sliders.frameOpacity / 100)) or 0.8
    -- Colors
    local colors = (self.db and self.db.profile and self.db.profile.backdropColors) or defaults.profile.backdropColors
    local bgColor = colors.backgroundColor or {r = 0, g = 0, b = 0}
    local borderColor = colors.borderColor or {r = 1, g = 1, b = 1}
    local borderOpacity = colors.borderOpacity or 0.8
    local showBorder = (self.db and self.db.profile and self.db.profile.checkboxes and self.db.profile.checkboxes[5]) or false
    -- Apply backdrop
    frame:SetBackdrop({
        bgFile = bgTexture,
        edgeFile = showBorder and borderTexture or nil,
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, opacity)
    if showBorder then
        frame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderOpacity)
    end
end

-- RGB (0–1) to WoW color code
local function RGBToColorCode(r, g, b)
    local rHex = string.format("%02X", math.floor(r * 255))
    local gHex = string.format("%02X", math.floor(g * 255))
    local bHex = string.format("%02X", math.floor(b * 255))
    return string.format("|cff%s%s%s", rHex, gHex, bHex)
end

-- Convert 24-hour time to 12-hour (AM/PM)
local function ConvertTo12Hour(hour, minute, second, showSeconds)
    local suffix = "AM"
    if hour >= 12 then
        suffix = "PM"
        if hour > 12 then hour = hour - 12 end
    elseif hour == 0 then
        hour = 12
    end
    if showSeconds then
        return string.format("%d:%02d:%02d %s", hour, minute, second or 0, suffix)
    else
        return string.format("%d:%02d %s", hour, minute, suffix)
    end
end

-- Day suffix for ordinal dates
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

-- Month gemstone colors
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

-- Resolve month color (optional)
local function GetMonthColor(useColors)
    if not useColors then return "" end
    local monthAbbr = date("%b")  -- Abbreviated month (e.g., "Oct")
    return monthColors[monthAbbr] or "|cffffffff"  -- Default to white if not found
end

-- Main display frame
local frame = CreateFrame("Frame", "MyTimeDisplayFrame", UIParent, "BackdropTemplate")
frame:SetSize(150, 60)  -- Frame size (width, height)
frame:SetPoint("CENTER") -- Default position
frame:SetClampedToScreen(true)

-- Expose frame on addon
MyTimeDisplay.frame = frame
-- Initial backdrop (updated on enable)
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)  -- Background color (black with transparency)
frame:SetBackdropBorderColor(0, 0, 0)  -- Border color (black)

-- Mouse + drag handling
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.position) then return end
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    MyTimeDisplay.db.profile.position.point = point
    MyTimeDisplay.db.profile.position.relativePoint = relativePoint
    MyTimeDisplay.db.profile.position.xOfs = xOfs or 0
    MyTimeDisplay.db.profile.position.yOfs = yOfs or 0
end)

-- Font strings (local/server/date)
local localTimeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
localTimeText:SetPoint("CENTER", frame, "CENTER", 0, 0)

local serverTimeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
serverTimeText:SetPoint("CENTER", frame, "CENTER", 0, -15)

local dateText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
dateText:SetPoint("CENTER", frame, "CENTER", 0, -30)

local timeText = localTimeText

-- Update time/date and apply layout
local function UpdateTime()
    if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
    
    local showLocalTime = MyTimeDisplay.db.profile.checkboxes[1]
    local showServerTime = MyTimeDisplay.db.profile.checkboxes[2]
    local showDateInfo = MyTimeDisplay.db.profile.checkboxes[3]
    local use12HourFormat = MyTimeDisplay.db.profile.checkboxes[4]
    local showSeconds = MyTimeDisplay.db.profile.checkboxes[6]
    local useMonthColors = MyTimeDisplay.db.profile.checkboxes[7]
    local abbreviateDays = MyTimeDisplay.db.profile.checkboxes[8]

    local serverHour, serverMinute = GetGameTime()
    local localTimeTable = date("*t")
    local localHour = localTimeTable.hour
    local localMinute = localTimeTable.min
    local localSecond = localTimeTable.sec
    local localTime = showLocalTime and (use12HourFormat and ConvertTo12Hour(localHour, localMinute, localSecond, showSeconds) or (showSeconds and string.format("%02d:%02d:%02d", localHour, localMinute, localSecond) or string.format("%02d:%02d", localHour, localMinute))) or ""
    local serverTime = showServerTime and (use12HourFormat and ConvertTo12Hour(serverHour, serverMinute, 0, false) or string.format("%02d:%02d", serverHour, serverMinute)) or ""

    -- Determine time labels based on abbreviation setting
    local localLabel = ""
    local serverLabel = ""
    if showLocalTime then
        local timeLabel = (MyTimeDisplay.db.profile.useAbbreviatedTimeLabels and "L" or "Local")
        localLabel = string.format("|cff00ff00%s|r: %s", timeLabel, localTime)
    end
    if showServerTime then
        local timeLabel = (MyTimeDisplay.db.profile.useAbbreviatedTimeLabels and "S" or "Server")
        serverLabel = string.format("|cffffd700%s|r: %s", timeLabel, serverTime)
    end

    local dateStr = ""
    if showDateInfo then
        local dayName = abbreviateDays and date("%a") or date("%A")  -- %a for abbreviated (Wed), %A for full (Wednesday)
        local dayNumber = tonumber(date("%d"))
        local daySuffix = GetDaySuffix(dayNumber)
        local monthColor = GetMonthColor(useMonthColors)
        local monthAbbr = date("%b")
        dateStr = string.format("%s%s |cffffffff%d|r%s |cffffffff%s|r", monthColor, monthAbbr, dayNumber, daySuffix, dayName)
    end

    -- Apply custom text color if enabled
    local useCustomTextColor = MyTimeDisplay.db.profile.useCustomTextColor
    local customColor = ""
    if useCustomTextColor then
        local textColor = MyTimeDisplay.db.profile.customTextColor
        customColor = RGBToColorCode(textColor.r, textColor.g, textColor.b)
    end

    if useCustomTextColor then
        localLabel = localLabel:gsub("|cff[0-9a-fA-F]+", customColor):gsub("|r", "|r")
        serverLabel = serverLabel:gsub("|cff[0-9a-fA-F]+", customColor):gsub("|r", "|r")
        dateStr = dateStr:gsub("|cff[0-9a-fA-F]+", customColor):gsub("|r", "|r")
    end

    -- Apply font settings to all font strings
    local fontName = MyTimeDisplay.db.profile.font or defaults.profile.font
    local fontSize = MyTimeDisplay.db.profile.fontSize or defaults.profile.fontSize
    local outline = MyTimeDisplay.db.profile.fontOutline or defaults.profile.fontOutline
    
    -- Get the actual font path from SharedMedia or use fallback
    local fontPath = "Fonts/FRIZQT__.TTF"
    if LSM then
        local lsmFont = LSM:Fetch("font", fontName)
        if lsmFont then
            fontPath = lsmFont
        end
    end
    
    -- Apply font to all font strings
    localTimeText:SetFont(fontPath, fontSize, outline)
    serverTimeText:SetFont(fontPath, fontSize, outline)
    dateText:SetFont(fontPath, fontSize, outline)
    
    -- Set text content
    localTimeText:SetText(localLabel)
    serverTimeText:SetText(serverLabel)
    dateText:SetText(dateStr)
    
    -- Update layout based on horizontal setting
    MyTimeDisplay:UpdateLayout()
end

-- Vertical layout
local function UpdateLayoutVertical()
    if layoutTimer then
        MyTimeDisplay:CancelTimer(layoutTimer)
        layoutTimer = nil
    end
    
    local spacing = (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.spacing and MyTimeDisplay.db.profile.spacing.vertical) or defaults.profile.spacing.vertical
    local padding = (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.padding and MyTimeDisplay.db.profile.padding.vertical) or defaults.profile.padding.vertical
    
    local yPos = -padding
    local visibleCount = 0
    
    -- Count visible elements first
    if localTimeText:GetText() ~= "" then visibleCount = visibleCount + 1 end
    if serverTimeText:GetText() ~= "" then visibleCount = visibleCount + 1 end
    if dateText:GetText() ~= "" then visibleCount = visibleCount + 1 end
    
    local currentIdx = 0
    
    if localTimeText:GetText() ~= "" then
        currentIdx = currentIdx + 1
        localTimeText:ClearAllPoints()
        localTimeText:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, yPos)
        localTimeText:Show()
        yPos = yPos - (localTimeText:GetStringHeight() or (select(2, localTimeText:GetFont()) or 12))
        if currentIdx < visibleCount then
            yPos = yPos - spacing
        end
    else
        localTimeText:Hide()
        localTimeText:ClearAllPoints()
    end
    
    if serverTimeText:GetText() ~= "" then
        currentIdx = currentIdx + 1
        serverTimeText:ClearAllPoints()
        serverTimeText:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, yPos)
        serverTimeText:Show()
        yPos = yPos - (serverTimeText:GetStringHeight() or (select(2, serverTimeText:GetFont()) or 12))
        if currentIdx < visibleCount then
            yPos = yPos - spacing
        end
    else
        serverTimeText:Hide()
        serverTimeText:ClearAllPoints()
    end
    
    if dateText:GetText() ~= "" then
        currentIdx = currentIdx + 1
        dateText:ClearAllPoints()
        dateText:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, yPos)
        dateText:Show()
    else
        dateText:Hide()
        dateText:ClearAllPoints()
    end
    
    -- Calculate and set frame size
    MyTimeDisplay:CalculateFrameSizeVertical()
end

-- Horizontal layout
local function UpdateLayoutHorizontal()
    if layoutTimer then
        MyTimeDisplay:CancelTimer(layoutTimer)
        layoutTimer = nil
    end
    
    local spacing = (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.spacing and MyTimeDisplay.db.profile.spacing.horizontal) or defaults.profile.spacing.horizontal
    local padding = (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.padding and MyTimeDisplay.db.profile.padding.horizontal) or defaults.profile.padding.horizontal
    local xPos = padding
    local visibleCount = 0
    
    -- Count visible elements first
    if localTimeText:GetText() ~= "" then visibleCount = visibleCount + 1 end
    if serverTimeText:GetText() ~= "" then visibleCount = visibleCount + 1 end
    if dateText:GetText() ~= "" then visibleCount = visibleCount + 1 end
    
    local currentIdx = 0
    
    if localTimeText:GetText() ~= "" then
        currentIdx = currentIdx + 1
        localTimeText:ClearAllPoints()
        localTimeText:SetPoint("LEFT", frame, "LEFT", xPos, 0)
        localTimeText:Show()
        xPos = xPos + (localTimeText:GetStringWidth() or 0)
        if currentIdx < visibleCount then
            xPos = xPos + spacing
        end
    else
        localTimeText:Hide()
        localTimeText:ClearAllPoints()
    end
    
    if serverTimeText:GetText() ~= "" then
        currentIdx = currentIdx + 1
        serverTimeText:ClearAllPoints()
        serverTimeText:SetPoint("LEFT", frame, "LEFT", xPos, 0)
        serverTimeText:Show()
        xPos = xPos + (serverTimeText:GetStringWidth() or 0)
        if currentIdx < visibleCount then
            xPos = xPos + spacing
        end
    else
        serverTimeText:Hide()
        serverTimeText:ClearAllPoints()
    end
    
    if dateText:GetText() ~= "" then
        currentIdx = currentIdx + 1
        dateText:ClearAllPoints()
        dateText:SetPoint("LEFT", frame, "LEFT", xPos, 0)
        dateText:Show()
    else
        dateText:Hide()
        dateText:ClearAllPoints()
    end
    
    -- Calculate and set frame size
    MyTimeDisplay:CalculateFrameSizeHorizontal()
end

-- Frame size (vertical)
function MyTimeDisplay:CalculateFrameSizeVertical()
    local spacing = (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.spacing and MyTimeDisplay.db.profile.spacing.vertical) or defaults.profile.spacing.vertical
    local padding = (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.padding and MyTimeDisplay.db.profile.padding.vertical) or defaults.profile.padding.vertical
    
    -- Gather visible elements
    local elements = {}
    if localTimeText:IsShown() then table.insert(elements, localTimeText) end
    if serverTimeText:IsShown() then table.insert(elements, serverTimeText) end
    if dateText:IsShown() then table.insert(elements, dateText) end
    
    if #elements == 0 then
        frame:SetSize(50, 20)
        return
    end
    
    -- Compute max width and total height from actual font metrics
    local maxWidth = 0
    local totalHeight = padding * 2
    for i, el in ipairs(elements) do
        local w = el:GetStringWidth() or 0
        local h = el:GetStringHeight() or (select(2, el:GetFont()) or 12)
        maxWidth = math.max(maxWidth, w)
        totalHeight = totalHeight + h
        if i < #elements then
            totalHeight = totalHeight + spacing
        end
    end
    
    local width = math.max(30, maxWidth + (padding * 2))
    frame:SetSize(width, totalHeight)
end

-- Frame size (horizontal)
function MyTimeDisplay:CalculateFrameSizeHorizontal()
    local spacing = (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.spacing and MyTimeDisplay.db.profile.spacing.horizontal) or defaults.profile.spacing.horizontal
    local padding = (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.padding and MyTimeDisplay.db.profile.padding.horizontal) or defaults.profile.padding.horizontal
    
    -- Gather visible elements
    local elements = {}
    if localTimeText:IsShown() then table.insert(elements, localTimeText) end
    if serverTimeText:IsShown() then table.insert(elements, serverTimeText) end
    if dateText:IsShown() then table.insert(elements, dateText) end
    
    if #elements == 0 then
        frame:SetSize(50, 20)
        return
    end
    
    -- Compute total width and max height from actual font metrics
    local totalWidth = padding * 2
    local maxHeight = 0
    for i, el in ipairs(elements) do
        local w = el:GetStringWidth() or 0
        local h = el:GetStringHeight() or (select(2, el:GetFont()) or 12)
        totalWidth = totalWidth + w
        maxHeight = math.max(maxHeight, h)
        if i < #elements then
            totalWidth = totalWidth + spacing
        end
    end
    
    local height = maxHeight + (padding * 2)
    frame:SetSize(totalWidth, height)
end

-- Main frame tooltip
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

-- Toggle the settings panel on right-click
frame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        LibStub("AceConfigDialog-3.0"):Open("MyTimeDisplay")
    end
end)

-- Set a repeating timer to update the time every second
frame:SetScript("OnUpdate", function(self, elapsed)
    self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
    if self.timeSinceLastUpdate >= 1 then
        UpdateTime()
        self.timeSinceLastUpdate = 0
    end
end)

-- Font utilities
function MyTimeDisplay:SetFontString(fs)
    if not fs then return end
    local fontPath = LSM and LSM:Fetch("font", self.db.profile.font) or "Fonts\\FRIZQT__.TTF"
    local fontSize = self.db.profile.fontSize or 12
    local outlineFlag = self.db.profile.fontOutline or ""
    fs:SetFont(fontPath, fontSize, outlineFlag)
end

function MyTimeDisplay:UpdateAllFonts()
    if not (localTimeText and serverTimeText and dateText) then return end
    self:SetFontString(localTimeText)
    self:SetFontString(serverTimeText)
    self:SetFontString(dateText)
    self:ApplyBackdropTextures()  -- Reapply backdrop textures
    UpdateTime()  -- Recalculate layout with new font size
end

-- Apply lock/move state
function MyTimeDisplay:ApplyLockState()
    local locked = (self.db and self.db.profile and self.db.profile.lockFrame) or false
    if locked then
        frame:SetMovable(false)
        frame:SetScript("OnDragStart", function(_) end)
    else
        frame:SetMovable(true)
        frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    end
end

-- (removed: unused status text helper)

function MyTimeDisplay:PopulateMinimapTooltip(tt)
    if not tt then return end
    tt:AddLine("MyTimeDisplay")
    tt:AddLine("Left-click: Open settings", 1, 1, 1)
    tt:AddLine("Right-click: Lock/Unlock frame", 1, 1, 1)
    local locked = (self.db and self.db.profile and self.db.profile.lockFrame) or false
    tt:AddLine("Frame: " .. (locked and "|cff00ff00Locked|r" or "|cffff0000Unlocked|r"))
end

function MyTimeDisplay:RefreshMinimapTooltip()
    local button = _G["LibDBIcon10_MyTimeDisplay"]
    if GameTooltip and GameTooltip:IsShown() and button and GameTooltip:IsOwned(button) then
        -- Force a full redraw to ensure updated lines while hovering
        GameTooltip:Hide()
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        self:PopulateMinimapTooltip(GameTooltip)
        GameTooltip:Show()
    end
end

-- Minimap launcher (LDB + LibDBIcon)
function MyTimeDisplay:SetupMinimap()
    if not LDB or not DBIcon then return end
    if not self._ldbObject then
        self._ldbObject = LDB:NewDataObject("MyTimeDisplay", {
            type = "launcher",
            text = "MyTimeDisplay",
            icon = "Interface/Icons/INV_Misc_PocketWatch_01",
            OnClick = function(_, button)
                if button == "LeftButton" then
                    LibStub("AceConfigDialog-3.0"):Open("MyTimeDisplay")
                elseif button == "RightButton" then
                    self.db.profile.lockFrame = not self.db.profile.lockFrame
                    self:ApplyLockState()
                    self:RefreshMinimapTooltip()
                    if self.db.profile.lockFrame then
                        self:Print("Frame locked.")
                    else
                        self:Print("Frame unlocked.")
                    end
                end
            end,
            OnTooltipShow = function(tt)
                MyTimeDisplay:PopulateMinimapTooltip(tt)
            end,
        })
    end
    DBIcon:Register("MyTimeDisplay", self._ldbObject, self.db.profile.minimap)
    if self.db.profile.minimap and self.db.profile.minimap.hide then
        DBIcon:Hide("MyTimeDisplay")
    else
        DBIcon:Show("MyTimeDisplay")
    end
end

-- OnInitialize
function MyTimeDisplay:OnInitialize()
    -- Initialize database with per-character profiles
    self.db = LibStub("AceDB-3.0"):New("MyTimeDisplayDB", defaults)
    
    -- Ensure profile structure is initialized
    if not self.db.profile.sliders then
        self.db.profile.sliders = {frameOpacity = 80, frameScale = 1.0}
    end
    if not self.db.profile.checkboxes then
        self.db.profile.checkboxes = {true, true, true, true, true, false, true, true}
    end
    if not self.db.profile.font then
        self.db.profile.font = defaults.profile.font
    end
    if not self.db.profile.fontSize then
        self.db.profile.fontSize = defaults.profile.fontSize
    end
    if not self.db.profile.fontOutline then
        self.db.profile.fontOutline = defaults.profile.fontOutline
    end
    if self.db.profile.horizontalLayout == nil then
        self.db.profile.horizontalLayout = defaults.profile.horizontalLayout
    end
    if not self.db.profile.backdropTexture then
        self.db.profile.backdropTexture = defaults.profile.backdropTexture
    end
    if not self.db.profile.borderTexture then
        self.db.profile.borderTexture = defaults.profile.borderTexture
    end
    if not self.db.profile.backdropColors then
        self.db.profile.backdropColors = {
            backgroundColor = {r = 0, g = 0, b = 0},
            borderColor = {r = 1, g = 1, b = 1},
            borderOpacity = 0.8,
        }
    end
    if not self.db.profile.spacing then
        self.db.profile.spacing = { vertical = defaults.profile.spacing.vertical, horizontal = defaults.profile.spacing.horizontal }
    end
    if not self.db.profile.padding then
        self.db.profile.padding = { vertical = defaults.profile.padding.vertical, horizontal = defaults.profile.padding.horizontal }
    end
    if self.db.profile.lockFrame == nil then
        self.db.profile.lockFrame = defaults.profile.lockFrame
    end
    if not self.db.profile.minimap then
        self.db.profile.minimap = { hide = defaults.profile.minimap.hide }
    end
end

local options = {
    name = "MyTimeDisplay",
    handler = MyTimeDisplay,
    type = "group",
    childGroups = "tab",
    args = {
        display = {
            name = "Display",
            type = "group",
            order = 1,
            args = {
                localTime = {
                    name = "Show Local Time",
                    desc = "Toggle the display of local time",
                    type = "toggle",
                    get = function()
                        return (MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[1]) or false
                    end,
                    set = function(info, value)
                        if not MyTimeDisplay.db.profile.checkboxes then MyTimeDisplay.db.profile.checkboxes = {} end
                        MyTimeDisplay.db.profile.checkboxes[1] = value
                        UpdateTime()
                    end,
                    order = 1,
                },
                serverTime = {
                    name = "Show Server Time",
                    desc = "Toggle the display of server time",
                    type = "toggle",
                    get = function()
                        return (MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[2]) or false
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.checkboxes then MyTimeDisplay.db.profile.checkboxes = {} end
                        MyTimeDisplay.db.profile.checkboxes[2] = value
                        UpdateTime()
                    end,
                    order = 2,
                },
                dateInfo = {
                    name = "Show Date Info",
                    desc = "Toggle the display of date information",
                    type = "toggle",
                    get = function()
                        return (MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[3]) or false
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.checkboxes then MyTimeDisplay.db.profile.checkboxes = {} end
                        MyTimeDisplay.db.profile.checkboxes[3] = value
                        UpdateTime()
                    end,
                    order = 3,
                },
                format12Hour = {
                    name = "Use 12-Hour Format",
                    desc = "Toggle the use of 12-hour time format",
                    type = "toggle",
                    get = function()
                        return (MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[4]) or false
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.checkboxes then MyTimeDisplay.db.profile.checkboxes = {} end
                        MyTimeDisplay.db.profile.checkboxes[4] = value
                        UpdateTime()
                    end,
                    order = 4,
                },
                showSeconds = {
                    name = "Show Seconds",
                    desc = "Toggle the display of seconds in the time",
                    type = "toggle",
                    get = function()
                        return (MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[6]) or false
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.checkboxes then MyTimeDisplay.db.profile.checkboxes = {} end
                        MyTimeDisplay.db.profile.checkboxes[6] = value
                        UpdateTime()
                    end,
                    order = 5,
                },
                useAbbreviatedTimeLabels = {
                    name = "Abbreviate Time Labels",
                    desc = "Use 'L' for Local and 'S' for Server",
                    type = "toggle",
                    get = function()
                        return MyTimeDisplay.db.profile.useAbbreviatedTimeLabels or false
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        MyTimeDisplay.db.profile.useAbbreviatedTimeLabels = value
                        UpdateTime()
                    end,
                    order = 6,
                },
                useMonthColors = {
                    name = "Use Month Colors",
                    desc = "Toggle colored month names (gemstone colors)",
                    type = "toggle",
                    get = function()
                        return (MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[7]) or false
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.checkboxes then MyTimeDisplay.db.profile.checkboxes = {} end
                        MyTimeDisplay.db.profile.checkboxes[7] = value
                        UpdateTime()
                    end,
                    order = 7,
                },
                abbreviateDays = {
                    name = "Abbreviate Day Names",
                    desc = "Toggle abbreviated day names (Wed vs Wednesday)",
                    type = "toggle",
                    get = function()
                        return (MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[8]) or false
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.checkboxes then MyTimeDisplay.db.profile.checkboxes = {} end
                        MyTimeDisplay.db.profile.checkboxes[8] = value
                        UpdateTime()
                    end,
                    order = 8,
                },
                useCustomTextColor = {
                    name = "Use Custom Text Color",
                    desc = "Toggle custom text color for all text elements",
                    type = "toggle",
                    get = function()
                        return MyTimeDisplay.db.profile.useCustomTextColor or false
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        MyTimeDisplay.db.profile.useCustomTextColor = value
                        UpdateTime()
                    end,
                    order = 9,
                },
                customTextColor = {
                    name = "Text Color",
                    desc = "Select a custom color for all text (when enabled)",
                    type = "color",
                    hasAlpha = false,
                    get = function()
                        local color = MyTimeDisplay.db.profile.customTextColor or defaults.profile.customTextColor
                        return color.r, color.g, color.b
                    end,
                    set = function(info, r, g, b)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.customTextColor then MyTimeDisplay.db.profile.customTextColor = {} end
                        MyTimeDisplay.db.profile.customTextColor.r = r
                        MyTimeDisplay.db.profile.customTextColor.g = g
                        MyTimeDisplay.db.profile.customTextColor.b = b
                        UpdateTime()
                    end,
                    order = 10,
                    disabled = function() return not MyTimeDisplay.db.profile.useCustomTextColor end,
                },
            },
        },
        appearance = {
            name = "Appearance",
            type = "group",
            order = 2,
            args = {
                fontSelection = {
                    name = "Font",
                    desc = "Choose the font for the display",
                    type = "select",
                    dialogControl = "LSM30_Font",
                    values = LSM and LSM:HashTable("font") or {},
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.font end
                        if not MyTimeDisplay.db.profile then return defaults.profile.font end
                        return MyTimeDisplay.db.profile.font or defaults.profile.font
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        MyTimeDisplay.db.profile.font = value
                        MyTimeDisplay:UpdateAllFonts()
                    end,
                    order = 1,
                },
                fontSize = {
                    name = "Font Size",
                    desc = "Adjust the font size (8 - 32)",
                    type = "range",
                    min = 8,
                    max = 32,
                    step = 1,
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.fontSize end
                        if not MyTimeDisplay.db.profile then return defaults.profile.fontSize end
                        return MyTimeDisplay.db.profile.fontSize or defaults.profile.fontSize
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        MyTimeDisplay.db.profile.fontSize = value
                        MyTimeDisplay:UpdateAllFonts()
                    end,
                    order = 2,
                },
                fontOutline = {
                    name = "Font Outline",
                    desc = "Choose the outline style for the font",
                    type = "select",
                    values = {
                        ["OUTLINE"] = "Outline",
                        ["THICKOUTLINE"] = "Thick Outline",
                        [""] = "None",
                    },
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.fontOutline end
                        if not MyTimeDisplay.db.profile then return defaults.profile.fontOutline end
                        return MyTimeDisplay.db.profile.fontOutline or defaults.profile.fontOutline
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        MyTimeDisplay.db.profile.fontOutline = value
                        MyTimeDisplay:UpdateAllFonts()
                    end,
                    order = 3,
                },
                frameScale = {
                    name = "Frame Scale",
                    desc = "Adjust the size of the time display frame",
                    type = "range",
                    min = 0.5,
                    max = 2.0,
                    step = 0.1,
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.sliders.frameScale end
                        if not MyTimeDisplay.db.profile then return defaults.profile.sliders.frameScale end
                        if not MyTimeDisplay.db.profile.sliders then return defaults.profile.sliders.frameScale end
                        return MyTimeDisplay.db.profile.sliders.frameScale or defaults.profile.sliders.frameScale
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.sliders then MyTimeDisplay.db.profile.sliders = {} end
                        MyTimeDisplay.db.profile.sliders.frameScale = value
                        frame:SetScale(value)
                    end,
                    order = 4,
                },
            },
        },
        layout = {
            name = "Layout",
            type = "group",
            order = 3,
            args = {
                horizontalLayout = {
                    name = "Horizontal Layout",
                    desc = "Switch between horizontal and vertical display layouts",
                    type = "toggle",
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.horizontalLayout end
                        if not MyTimeDisplay.db.profile then return defaults.profile.horizontalLayout end
                        return (MyTimeDisplay.db.profile.horizontalLayout ~= nil) and MyTimeDisplay.db.profile.horizontalLayout or defaults.profile.horizontalLayout
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        MyTimeDisplay.db.profile.horizontalLayout = value
                        MyTimeDisplay:UpdateLayout()
                    end,
                    order = 1,
                },
                textAlignment = {
                    name = "Text Alignment",
                    desc = "Align text to the left, center, or right (vertical layout only)",
                    type = "select",
                    values = {LEFT = "Left", CENTER = "Center", RIGHT = "Right"},
                    get = function()
                        return MyTimeDisplay.db.profile.textAlignment or defaults.profile.textAlignment
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        MyTimeDisplay.db.profile.textAlignment = value
                        MyTimeDisplay:UpdateLayout()
                    end,
                    order = 2,
                    disabled = function() return MyTimeDisplay.db.profile.horizontalLayout end,
                },
                lockFrame = {
                    name = "Lock Frame",
                    desc = "Prevent moving the frame by dragging",
                    type = "toggle",
                    get = function()
                        return MyTimeDisplay.db.profile.lockFrame or false
                    end,
                    set = function(info, value)
                        MyTimeDisplay.db.profile.lockFrame = value
                        MyTimeDisplay:ApplyLockState()
                        MyTimeDisplay:RefreshMinimapTooltip()
                    end,
                    order = 3,
                },
                verticalSpacing = {
                    name = "Vertical Spacing",
                    desc = "Pixels between lines in vertical layout",
                    type = "range",
                    min = 0,
                    max = 100,
                    step = 1,
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.spacing.vertical end
                        if not MyTimeDisplay.db.profile then return defaults.profile.spacing.vertical end
                        if not MyTimeDisplay.db.profile.spacing then return defaults.profile.spacing.vertical end
                        return MyTimeDisplay.db.profile.spacing.vertical or defaults.profile.spacing.vertical
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.spacing then MyTimeDisplay.db.profile.spacing = {} end
                        MyTimeDisplay.db.profile.spacing.vertical = value
                        MyTimeDisplay:UpdateLayout()
                    end,
                    order = 4,
                    disabled = function()
                        return MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.horizontalLayout
                    end,
                },
                horizontalSpacing = {
                    name = "Horizontal Spacing",
                    desc = "Pixels between items in horizontal layout",
                    type = "range",
                    min = 0,
                    max = 100,
                    step = 1,
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.spacing.horizontal end
                        if not MyTimeDisplay.db.profile then return defaults.profile.spacing.horizontal end
                        if not MyTimeDisplay.db.profile.spacing then return defaults.profile.spacing.horizontal end
                        return MyTimeDisplay.db.profile.spacing.horizontal or defaults.profile.spacing.horizontal
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.spacing then MyTimeDisplay.db.profile.spacing = {} end
                        MyTimeDisplay.db.profile.spacing.horizontal = value
                        MyTimeDisplay:UpdateLayout()
                    end,
                    order = 5,
                    disabled = function()
                        return not (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.horizontalLayout)
                    end,
                },
                
                verticalPadding = {
                    name = "Vertical Padding",
                    desc = "Inset at top/bottom in vertical layout",
                    type = "range",
                    min = 0,
                    max = 50,
                    step = 1,
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.padding.vertical end
                        if not MyTimeDisplay.db.profile then return defaults.profile.padding.vertical end
                        if not MyTimeDisplay.db.profile.padding then return defaults.profile.padding.vertical end
                        return MyTimeDisplay.db.profile.padding.vertical or defaults.profile.padding.vertical
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.padding then MyTimeDisplay.db.profile.padding = {} end
                        MyTimeDisplay.db.profile.padding.vertical = value
                        MyTimeDisplay:UpdateLayout()
                    end,
                    order = 7,
                    disabled = function()
                        return MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.horizontalLayout
                    end,
                },
                horizontalPadding = {
                    name = "Horizontal Padding",
                    desc = "Inset at left/right in horizontal layout",
                    type = "range",
                    min = 0,
                    max = 50,
                    step = 1,
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.padding.horizontal end
                        if not MyTimeDisplay.db.profile then return defaults.profile.padding.horizontal end
                        if not MyTimeDisplay.db.profile.padding then return defaults.profile.padding.horizontal end
                        return MyTimeDisplay.db.profile.padding.horizontal or defaults.profile.padding.horizontal
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.padding then MyTimeDisplay.db.profile.padding = {} end
                        MyTimeDisplay.db.profile.padding.horizontal = value
                        MyTimeDisplay:UpdateLayout()
                    end,
                    order = 8,
                    disabled = function()
                        return not (MyTimeDisplay.db and MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.horizontalLayout)
                    end,
                },
            },
        },
        minimap = {
            name = "Minimap",
            type = "group",
            order = 3.5,
            args = {
                showMinimap = {
                    name = "Show Minimap Button",
                    desc = "Toggle showing the minimap launcher",
                    type = "toggle",
                    get = function()
                        return not (MyTimeDisplay.db.profile.minimap and MyTimeDisplay.db.profile.minimap.hide)
                    end,
                    set = function(info, value)
                        if not MyTimeDisplay.db.profile.minimap then MyTimeDisplay.db.profile.minimap = {} end
                        MyTimeDisplay.db.profile.minimap.hide = not value
                        if DBIcon then
                            if value then DBIcon:Show("MyTimeDisplay") else DBIcon:Hide("MyTimeDisplay") end
                        end
                    end,
                    order = 1,
                },
                lockFrameHint = {
                    name = "Minimap right-click locks/unlocks the frame.",
                    type = "description",
                    order = 2,
                },
            },
        },
        backdrop = {
            name = "Backdrop",
            type = "group",
            order = 4,
            args = {
                backdropToggle = {
                    name = "Show Border",
                    desc = "Toggle the display of the border",
                    type = "toggle",
                    get = function()
                        return (MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[5]) or false
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.checkboxes then MyTimeDisplay.db.profile.checkboxes = {} end
                        MyTimeDisplay.db.profile.checkboxes[5] = value
                        MyTimeDisplay:ApplyBackdropTextures()
                    end,
                    order = 1,
                },
                frameOpacity = {
                    name = "Background Opacity",
                    desc = "Adjust the opacity of the background",
                    type = "range",
                    min = 0,
                    max = 100,
                    step = 1,
                    get = function()
                        if not MyTimeDisplay or not MyTimeDisplay.db then return defaults.profile.sliders.frameOpacity end
                        if not MyTimeDisplay.db.profile then return defaults.profile.sliders.frameOpacity end
                        if not MyTimeDisplay.db.profile.sliders then return defaults.profile.sliders.frameOpacity end
                        return MyTimeDisplay.db.profile.sliders.frameOpacity or defaults.profile.sliders.frameOpacity
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.sliders then MyTimeDisplay.db.profile.sliders = {} end
                        MyTimeDisplay.db.profile.sliders.frameOpacity = value
                        MyTimeDisplay:ApplyBackdropTextures()
                    end,
                    order = 2,
                },
                backgroundColor = {
                    name = "Background Color",
                    desc = "Select the background color for the frame",
                    type = "color",
                    hasAlpha = false,
                    get = function()
                        local colors = (MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.backdropColors) or defaults.profile.backdropColors
                        local bgColor = colors.backgroundColor or defaults.profile.backdropColors.backgroundColor
                        return bgColor.r, bgColor.g, bgColor.b
                    end,
                    set = function(info, r, g, b)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.backdropColors then MyTimeDisplay.db.profile.backdropColors = {} end
                        if not MyTimeDisplay.db.profile.backdropColors.backgroundColor then MyTimeDisplay.db.profile.backdropColors.backgroundColor = {} end
                        MyTimeDisplay.db.profile.backdropColors.backgroundColor.r = r
                        MyTimeDisplay.db.profile.backdropColors.backgroundColor.g = g
                        MyTimeDisplay.db.profile.backdropColors.backgroundColor.b = b
                        MyTimeDisplay:ApplyBackdropTextures()
                    end,
                    order = 3,
                },
                borderColor = {
                    name = "Border Color",
                    desc = "Select the border color for the frame",
                    type = "color",
                    hasAlpha = false,
                    get = function()
                        local colors = (MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.backdropColors) or defaults.profile.backdropColors
                        local borderCol = colors.borderColor or defaults.profile.backdropColors.borderColor
                        return borderCol.r, borderCol.g, borderCol.b
                    end,
                    set = function(info, r, g, b)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.backdropColors then MyTimeDisplay.db.profile.backdropColors = {} end
                        if not MyTimeDisplay.db.profile.backdropColors.borderColor then MyTimeDisplay.db.profile.backdropColors.borderColor = {} end
                        MyTimeDisplay.db.profile.backdropColors.borderColor.r = r
                        MyTimeDisplay.db.profile.backdropColors.borderColor.g = g
                        MyTimeDisplay.db.profile.backdropColors.borderColor.b = b
                        MyTimeDisplay:ApplyBackdropTextures()
                    end,
                    order = 4,
                    disabled = function() return not (MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[5]) end,
                },
                borderOpacity = {
                    name = "Border Opacity",
                    desc = "Adjust the opacity of the border",
                    type = "range",
                    min = 0,
                    max = 1,
                    step = 0.05,
                    get = function()
                        local colors = (MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.backdropColors) or defaults.profile.backdropColors
                        return colors.borderOpacity or defaults.profile.backdropColors.borderOpacity
                    end,
                    set = function(info, value)
                        if not (MyTimeDisplay and MyTimeDisplay.db and MyTimeDisplay.db.profile) then return end
                        if not MyTimeDisplay.db.profile.backdropColors then MyTimeDisplay.db.profile.backdropColors = {} end
                        MyTimeDisplay.db.profile.backdropColors.borderOpacity = value
                        MyTimeDisplay:ApplyBackdropTextures()
                    end,
                    order = 5,
                    disabled = function() return not (MyTimeDisplay.db.profile and MyTimeDisplay.db.profile.checkboxes and MyTimeDisplay.db.profile.checkboxes[5]) end,
                },
            },
        },
        advanced = {
            name = "Advanced",
            type = "group",
            order = 98,
            args = {
                reset = {
                    name = "Reset to Defaults",
                    desc = "Reset all settings to their default values",
                    type = "execute",
                    func = function()
                        MyTimeDisplay.db:ResetProfile()
                        MyTimeDisplay.db.profile.sliders = {frameOpacity = 80, frameScale = 1.0}
                        MyTimeDisplay.db.profile.checkboxes = {true, true, true, true, true, false, true, true}
                        MyTimeDisplay.db.profile.backdropColors = {
                            backgroundColor = {r = 0, g = 0, b = 0},
                            borderColor = {r = 1, g = 1, b = 1},
                            borderOpacity = 0.8,
                        }
                        MyTimeDisplay.db.profile.spacing = { vertical = defaults.profile.spacing.vertical, horizontal = defaults.profile.spacing.horizontal }
                        MyTimeDisplay.db.profile.padding = { vertical = defaults.profile.padding.vertical, horizontal = defaults.profile.padding.horizontal }
                        frame:SetScale(1.0)
                        MyTimeDisplay:ApplyBackdropTextures()
                        MyTimeDisplay:UpdateAllFonts()
                    end,
                    order = 1,
                },
            },
        },
        profiles = {
            name = "Profiles",
            type = "group",
            order = 99,
            args = {
                -- Will be populated in OnEnable via AceDBOptions
            },
        },
    },
}

-- Update layout
function MyTimeDisplay:UpdateLayout()
    if self.db.profile.horizontalLayout then
        UpdateLayoutHorizontal()
    else
        UpdateLayoutVertical()
    end
end

-- OnEnable
function MyTimeDisplay:OnEnable()
    -- Ensure profile is properly initialized with saved data
    if not self.db.profile.sliders then
        self.db.profile.sliders = {frameOpacity = 80, frameScale = 1.0}
    end
    if not self.db.profile.checkboxes then
        self.db.profile.checkboxes = {true, true, true, true, true, false, true, true}
    end
    if not self.db.profile.backdropColors then
        self.db.profile.backdropColors = {
            backgroundColor = {r = 0, g = 0, b = 0},
            borderColor = {r = 1, g = 1, b = 1},
            borderOpacity = 0.8,
        }
    end
    if not self.db.profile.spacing then
        self.db.profile.spacing = { vertical = defaults.profile.spacing.vertical, horizontal = defaults.profile.spacing.horizontal }
    end
    if self.db.profile.lockFrame == nil then
        self.db.profile.lockFrame = defaults.profile.lockFrame
    end
    if not self.db.profile.minimap then
        self.db.profile.minimap = { hide = defaults.profile.minimap.hide }
    end
    
    -- Populate Profiles tab using AceDBOptions
    if AceDBOptions and options and options.args and options.args.profiles then
        local profiles = AceDBOptions:GetOptionsTable(self.db)
        if profiles then
            profiles.order = 99
            profiles.name = "Profiles"
            options.args.profiles = profiles
        end
    end
    
    -- Register the options table with AceConfig
    LibStub("AceConfig-3.0"):RegisterOptionsTable("MyTimeDisplay", options)
    local configDialog = LibStub("AceConfigDialog-3.0")
    configDialog:AddToBlizOptions("MyTimeDisplay", "MyTimeDisplay")
    
    -- Ensure backdrop updates when settings dialog is closed
    configDialog:SetDefaultSize("MyTimeDisplay", 600, 500)
    
    -- Initial update to populate text and size frame correctly
    UpdateTime()
    self:ApplyBackdropTextures()
    self:ApplyLockState()
    self:SetupMinimap()
    
    -- Restore frame position
    if self.db.profile and self.db.profile.position then
        local pos = self.db.profile.position
        frame:ClearAllPoints()
        frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.xOfs or 0, pos.yOfs or 0)
    end
    
    -- Apply frame scale
    if self.db.profile and self.db.profile.sliders then
        frame:SetScale(self.db.profile.sliders.frameScale or 1.0)
    else
        frame:SetScale(defaults.profile.sliders.frameScale)
    end
    
    -- Apply backdrop textures
    self:ApplyBackdropTextures()
    
    -- Apply font settings
    self:UpdateAllFonts()
    
    -- Register chat command
    self:RegisterChatCommand("mytd", "HandleChatCommand")
    self:RegisterChatCommand("mytdconfig", "HandleChatCommand")
end

-- Chat command handler
function MyTimeDisplay:HandleChatCommand(input)
    if input == "config" or input == "" then
        LibStub("AceConfigDialog-3.0"):Open("MyTimeDisplay")
    elseif input == "refresh" then
        self:ApplyBackdropTextures()
        self:Print("Backdrop textures refreshed!")
    else
        self:Print("MyTimeDisplay v2.0")
        self:Print("Available commands:")
        self:Print("  /mytd config   - Open settings window")
        self:Print("  /mytdconfig    - Open settings window")
        self:Print("  /mytd refresh  - Refresh backdrop textures")
        self:Print("  /mytd help     - Show this help message")
    end
end
