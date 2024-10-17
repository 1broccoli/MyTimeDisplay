-- main frame
local frame = CreateFrame("Frame", "MyTimeDisplayFrame", UIParent, "BackdropTemplate")
frame:SetSize(150, 60)  -- Frame size (width, height)
frame:SetPoint("CENTER") -- Default position
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)  -- Background color (black with transparency)
frame:SetBackdropBorderColor(0, 0, 0)  -- Border color (black)

-- Make the frame moveable
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- Font string to display the information
local timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
timeText:SetPoint("CENTER", frame, "CENTER", 0, 0)

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

-- Update the time and date
local function UpdateTime()
    -- Get server time
    local serverHour, serverMinute = GetGameTime()

    -- Get local time using timestamps
    local localTimeTable = date("*t")  -- Table containing local date and time info
    local localHour = localTimeTable.hour
    local localMinute = localTimeTable.min

    -- Get day name, day number, and abbreviated month
    local dayName = date("%A")  -- Full day name (e.g., "Wednesday")
    local dayNumber = tonumber(date("%d"))  -- Day number (e.g., 16)
    local daySuffix = GetDaySuffix(dayNumber)  -- Get the correct suffix
    local monthColor = GetMonthColor()  -- Get gemstone color for the month
    local monthAbbr = date("%b")  -- Abbreviated month (e.g., "Oct")

    -- Convert to 12-hour time format
    local localTime = ConvertTo12Hour(localHour, localMinute)
    local serverTime = ConvertTo12Hour(serverHour, serverMinute)

	-- Format the display text with colors
	local text = string.format(
    "|cff00ff00Local|r: %s\n|cffffd700Server|r: %s\n%s%s |cffffffff%d|r %s\n|cffffffff%s|r", 
    localTime, serverTime, monthColor, monthAbbr, dayNumber, daySuffix, dayName
	)

    -- Update the font string with the new text
    timeText:SetText(text)
end

-- Set a repeating timer to update the time every second
frame:SetScript("OnUpdate", function(self, elapsed)
    self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
    if self.timeSinceLastUpdate >= 1 then  -- Update every 1 second
        UpdateTime()
        self.timeSinceLastUpdate = 0
    end
end)
