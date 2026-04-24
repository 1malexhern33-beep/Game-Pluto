-- ================================================
--   SELUWIA — Improved Edition
--   Features: Save logs, filters, mobile, stability
-- ================================================

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clean up old instance
if playerGui:FindFirstChild("SeluwiaUI") then
    playerGui.SeluwiaUI:Destroy()
end

-- ================================================
--   SETTINGS (auto-loaded/saved)
-- ================================================
local SETTINGS_FILE = "seluwia_settings.json"
local LOG_FILE      = "seluwia_logs.txt"

local settings = {
    autoSpeed     = 100,
    filterType    = "All",   -- All / Gamepass / Product / Bulk / Purchase
    showTimestamp = true,
    maxEntries    = 50,      -- cap entries so UI stays fast
}

local function saveSettings()
    pcall(writefile, SETTINGS_FILE, game:GetService("HttpService"):JSONEncode(settings))
end

local function loadSettings()
    local ok, data = pcall(readfile, SETTINGS_FILE)
    if ok and data then
        local ok2, parsed = pcall(function()
            return game:GetService("HttpService"):JSONDecode(data)
        end)
        if ok2 and parsed then
            for k, v in pairs(parsed) do
                settings[k] = v
            end
        end
    end
end
loadSettings()

-- ================================================
--   LOG FILE
-- ================================================
local logLines = {}

local function appendLog(label, id)
    local line = os.date("%Y-%m-%d %H:%M:%S") .. " | " .. label .. " | " .. tostring(id)
    table.insert(logLines, line)
    pcall(writefile, LOG_FILE, table.concat(logLines, "\n"))
end

-- ================================================
--   HELPERS
-- ================================================
local isMobile        = UserInputService.TouchEnabled
local fontSizeScale   = isMobile and 0.85 or 1
local buttonHeight    = isMobile and 40 or 30
local titleBarHeight  = isMobile and 48 or 44
local footerHeight    = isMobile and 48 or 44

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.fromRGB(40, 40, 56)
    s.Thickness = thickness or 1
    return s
end

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ================================================
--   SCREEN GUI
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SeluwiaUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- ================================================
--   MINI BUBBLE (minimize)
-- ================================================
local miniBubble = Instance.new("TextButton", screenGui)
miniBubble.Size = UDim2.new(0, 52, 0, 52)
miniBubble.Position = UDim2.new(0, 16, 0.5, -26)
miniBubble.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
miniBubble.Text = "S"
miniBubble.TextColor3 = Color3.fromRGB(61, 255, 160)
miniBubble.TextSize = 22
miniBubble.Font = Enum.Font.GothamBold
miniBubble.BorderSizePixel = 0
miniBubble.Visible = false
miniBubble.Active = true
miniBubble.Draggable = true
corner(miniBubble, 16)
stroke(miniBubble, Color3.fromRGB(30, 60, 50), 1.5)

-- Pulse bubble
task.spawn(function()
    while screenGui.Parent do
        if miniBubble.Visible then
            TweenService:Create(miniBubble, TweenInfo.new(0.8), {
                BackgroundColor3 = Color3.fromRGB(20, 30, 22)
            }):Play()
            task.wait(0.8)
            TweenService:Create(miniBubble, TweenInfo.new(0.8), {
                BackgroundColor3 = Color3.fromRGB(13, 13, 17)
            }):Play()
            task.wait(0.8)
        else
            task.wait(0.5)
        end
    end
end)

-- ================================================
--   MAIN PANEL
-- ================================================
local panelSize = isMobile
    and UDim2.new(0.92, 0, 0.75, 0)
    or  UDim2.new(0, 760, 0, 520)

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = panelSize
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
panel.BorderSizePixel = 0
panel.Parent = screenGui
corner(panel, 16)
stroke(panel, Color3.fromRGB(30, 30, 42), 1)

if isMobile then
    panel.Position = UDim2.new(0.04, 0, 0.12, 0)
else
    panel.Position = UDim2.new(0.5, -380, 0.5, -260)
end

-- PC resize handle
if not isMobile then
    local rh = Instance.new("Frame", panel)
    rh.Size = UDim2.new(0, 18, 0, 18)
    rh.Position = UDim2.new(1, -18, 1, -18)
    rh.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    rh.BorderSizePixel = 0
    corner(rh, 4)
    stroke(rh, Color3.fromRGB(80, 80, 110), 1)

    local resizing, resizeStart, startSize = false, nil, nil
    rh.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true; resizeStart = input.Position; startSize = panel.AbsoluteSize
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - resizeStart
            panel.Size = UDim2.new(0,
                math.clamp(startSize.X + d.X, 420, 1200), 0,
                math.clamp(startSize.Y + d.Y, 320, 800))
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)
end

-- ================================================
--   TITLE BAR
-- ================================================
local titleBar = Instance.new("Frame", panel)
titleBar.Size = UDim2.new(1, 0, 0, titleBarHeight)
titleBar.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
titleBar.BorderSizePixel = 0
corner(titleBar, 16)
stroke(titleBar, Color3.fromRGB(22, 22, 31), 1)

-- Fix rounded bottom of titlebar
local titleFill = Instance.new("Frame", titleBar)
titleFill.Size = UDim2.new(1, 0, 0, 16)
titleFill.Position = UDim2.new(0, 0, 1, -16)
titleFill.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
titleFill.BorderSizePixel = 0

makeDraggable(panel, titleBar)

-- Live dot
local liveDot = Instance.new("Frame", titleBar)
liveDot.Size = UDim2.new(0, 9, 0, 9)
liveDot.Position = UDim2.new(0, 18, 0.5, -4)
liveDot.BackgroundColor3 = Color3.fromRGB(61, 255, 160)
liveDot.BorderSizePixel = 0
liveDot.ZIndex = 3
corner(liveDot, 999)

task.spawn(function()
    while screenGui.Parent do
        TweenService:Create(liveDot, TweenInfo.new(1), {Size = UDim2.new(0,11,0,11), Position = UDim2.new(0,17,0.5,-5)}):Play()
        task.wait(1)
        TweenService:Create(liveDot, TweenInfo.new(1), {Size = UDim2.new(0,9,0,9), Position = UDim2.new(0,18,0.5,-4)}):Play()
        task.wait(1)
    end
end)

local liveLabel = Instance.new("TextLabel", titleBar)
liveLabel.Size = UDim2.new(0, 44, 0, 20)
liveLabel.Position = UDim2.new(0, 32, 0.5, -10)
liveLabel.BackgroundTransparency = 1
liveLabel.Text = "LIVE"
liveLabel.TextColor3 = Color3.fromRGB(61, 255, 160)
liveLabel.TextSize = 11 * fontSizeScale
liveLabel.Font = Enum.Font.GothamBold
liveLabel.TextXAlignment = Enum.TextXAlignment.Left
liveLabel.ZIndex = 3

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(0, 160, 1, 0)
titleText.Position = UDim2.new(0.5, -80, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "SELUWIA"
titleText.TextColor3 = Color3.fromRGB(210, 210, 228)
titleText.TextSize = 14 * fontSizeScale
titleText.Font = Enum.Font.GothamBold
titleText.ZIndex = 3

-- Minimize button
local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -130, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.ZIndex = 4
corner(minBtn, 8)
stroke(minBtn, Color3.fromRGB(55, 50, 85), 1)

-- Clear button
local clearBtn = Instance.new("TextButton", titleBar)
clearBtn.Size = UDim2.new(0, 70, 0, 28)
clearBtn.Position = UDim2.new(1, -100, 0.5, -14)
clearBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
clearBtn.Text = "✕ Clear"
clearBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
clearBtn.TextSize = 11 * fontSizeScale
clearBtn.Font = Enum.Font.GothamBold
clearBtn.BorderSizePixel = 0
clearBtn.ZIndex = 4
corner(clearBtn, 8)
stroke(clearBtn, Color3.fromRGB(80, 28, 28), 1)

-- ================================================
--   FILTER BAR (below title bar)
-- ================================================
local filterBar = Instance.new("Frame", panel)
filterBar.Size = UDim2.new(1, -12, 0, 30)
filterBar.Position = UDim2.new(0, 6, 0, titleBarHeight + 4)
filterBar.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
filterBar.BorderSizePixel = 0
corner(filterBar, 8)
stroke(filterBar, Color3.fromRGB(28, 28, 40), 1)

local filterLayout = Instance.new("UIListLayout", filterBar)
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
filterLayout.Padding = UDim.new(0, 4)

local filterPad = Instance.new("UIPadding", filterBar)
filterPad.PaddingLeft = UDim.new(0, 6)
filterPad.PaddingRight = UDim.new(0, 6)

local FILTER_TYPES = {"All", "Gamepass", "Product", "Bulk", "Purchase"}
local filterBtns = {}

local function updateFilterBtns()
    for _, btn in pairs(filterBtns) do
        if btn:GetAttribute("FilterType") == settings.filterType then
            btn.BackgroundColor3 = Color3.fromRGB(55, 50, 90)
            btn.TextColor3 = Color3.fromRGB(220, 215, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            btn.TextColor3 = Color3.fromRGB(130, 125, 170)
        end
    end
end

for _, ft in ipairs(FILTER_TYPES) do
    local fb = Instance.new("TextButton", filterBar)
    fb.Size = UDim2.new(0, isMobile and 62 or 72, 1, -6)
    fb.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    fb.Text = ft
    fb.TextColor3 = Color3.fromRGB(130, 125, 170)
    fb.TextSize = 10 * fontSizeScale
    fb.Font = Enum.Font.GothamSemibold
    fb.BorderSizePixel = 0
    fb:SetAttribute("FilterType", ft)
    corner(fb, 6)
    fb.MouseButton1Click:Connect(function()
        settings.filterType = ft
        updateFilterBtns()
        saveSettings()
    end)
    table.insert(filterBtns, fb)
end
updateFilterBtns()

-- ================================================
--   LOG AREA
-- ================================================
local filterBarBottom = titleBarHeight + 4 + 30 + 4

local logArea = Instance.new("ScrollingFrame", panel)
logArea.Name = "LogArea"
logArea.Size = UDim2.new(1, -12, 1, -(filterBarBottom + footerHeight + 10))
logArea.Position = UDim2.new(0, 6, 0, filterBarBottom + 4)
logArea.BackgroundTransparency = 1
logArea.BorderSizePixel = 0
logArea.ScrollBarThickness = isMobile and 5 or 3
logArea.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 90)
logArea.CanvasSize = UDim2.new(0, 0, 0, 0)
logArea.AutomaticCanvasSize = Enum.AutomaticSize.Y

local listLayout = Instance.new("UIListLayout", logArea)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, isMobile and 8 or 6)
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local logPad = Instance.new("UIPadding", logArea)
logPad.PaddingTop = UDim.new(0, 6)
logPad.PaddingBottom = UDim.new(0, 6)
logPad.PaddingLeft = UDim.new(0, 2)
logPad.PaddingRight = UDim.new(0, 2)

-- ================================================
--   FOOTER
-- ================================================
local footer = Instance.new("Frame", panel)
footer.Size = UDim2.new(1, 0, 0, footerHeight)
footer.Position = UDim2.new(0, 0, 1, -footerHeight)
footer.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
footer.BorderSizePixel = 0
corner(footer, 16)

local footerFill = Instance.new("Frame", footer)
footerFill.Size = UDim2.new(1, 0, 0, 16)
footerFill.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
footerFill.BorderSizePixel = 0

local countLabel = Instance.new("TextLabel", footer)
countLabel.Size = UDim2.new(0, 160, 1, 0)
countLabel.Position = UDim2.new(0, 16, 0, 0)
countLabel.BackgroundTransparency = 1
countLabel.Text = "0 events"
countLabel.TextColor3 = Color3.fromRGB(160, 155, 200)
countLabel.TextSize = 11 * fontSizeScale
countLabel.Font = Enum.Font.Gotham
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.ZIndex = 2

-- Save Log button
local saveLogBtn = Instance.new("TextButton", footer)
saveLogBtn.Size = UDim2.new(0, isMobile and 72 or 80, 0, buttonHeight - 4)
saveLogBtn.Position = UDim2.new(1, -(isMobile and 246 or 270), 0.5, -(buttonHeight-4)/2)
saveLogBtn.BackgroundColor3 = Color3.fromRGB(15, 30, 20)
saveLogBtn.Text = "💾 Save"
saveLogBtn.TextColor3 = Color3.fromRGB(61, 255, 160)
saveLogBtn.TextSize = 11 * fontSizeScale
saveLogBtn.Font = Enum.Font.GothamBold
saveLogBtn.BorderSizePixel = 0
saveLogBtn.ZIndex = 2
corner(saveLogBtn, 7)
stroke(saveLogBtn, Color3.fromRGB(30, 80, 55), 1)

local stopAllBtn = Instance.new("TextButton", footer)
stopAllBtn.Size = UDim2.new(0, isMobile and 72 or 78, 0, buttonHeight - 4)
stopAllBtn.Position = UDim2.new(1, -(isMobile and 162 or 180), 0.5, -(buttonHeight-4)/2)
stopAllBtn.BackgroundColor3 = Color3.fromRGB(35, 15, 15)
stopAllBtn.Text = "⏹ Stop All"
stopAllBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
stopAllBtn.TextSize = 11 * fontSizeScale
stopAllBtn.Font = Enum.Font.GothamBold
stopAllBtn.BorderSizePixel = 0
stopAllBtn.ZIndex = 2
corner(stopAllBtn, 7)
stroke(stopAllBtn, Color3.fromRGB(80, 30, 30), 1)

local settingsBtn = Instance.new("TextButton", footer)
settingsBtn.Size = UDim2.new(0, isMobile and 60 or 66, 0, buttonHeight - 4)
settingsBtn.Position = UDim2.new(1, -(isMobile and 80 or 86), 0.5, -(buttonHeight-4)/2)
settingsBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
settingsBtn.Text = "⚙️ SET"
settingsBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
settingsBtn.TextSize = 11 * fontSizeScale
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.BorderSizePixel = 0
settingsBtn.ZIndex = 2
corner(settingsBtn, 7)
stroke(settingsBtn, Color3.fromRGB(55, 50, 85), 1)

-- Close X button
local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -6, 0, -6)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 12, 12)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 10
corner(closeBtn, 999)

-- ================================================
--   EMPTY STATE
-- ================================================
local function makeEmptyLabel()
    local el = Instance.new("TextLabel")
    el.Name = "EmptyState"
    el.Size = UDim2.new(1, 0, 0, 240)
    el.BackgroundTransparency = 1
    el.Text = "Waiting for events…\nAll marketplace events will appear here."
    el.TextColor3 = Color3.fromRGB(100, 100, 140)
    el.TextSize = 13 * fontSizeScale
    el.Font = Enum.Font.Gotham
    el.TextWrapped = true
    el.LayoutOrder = 99999
    el.Parent = logArea
    return el
end

local function setEmpty(show)
    local e = logArea:FindFirstChild("EmptyState")
    if show and not e then makeEmptyLabel()
    elseif not show and e then e:Destroy() end
end

setEmpty(true)

-- ================================================
--   SIGNAL LOGIC
-- ================================================
local eventCount      = 0
local entries         = {}
local suppressCounter = 0
local activeAutoButtons  = {}
local activeSpamButtons  = {}

local function fireFakeSignal(signalType, id)
    suppressCounter = suppressCounter + 1
    pcall(function()
        if signalType == "Product" then
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Gamepass" then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(player, id, true)
        elseif signalType == "Bulk" then
            MarketplaceService:SignalPromptBulkPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Purchase" then
            MarketplaceService:SignalPromptPurchaseFinished(player.UserId, id, true)
        end
    end)
    task.defer(function() suppressCounter = suppressCounter - 1 end)
end

local function stopAllAutoAndSpam()
    for btn, data in pairs(activeAutoButtons) do
        data.active = false
        if data.loop then pcall(task.cancel, data.loop) end
        if btn and btn.Parent then
            btn.Text = "Auto"
            btn.TextColor3 = Color3.fromRGB(170, 165, 220)
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end
    table.clear(activeAutoButtons)
    for btn, data in pairs(activeSpamButtons) do
        data.active = false
        if data.loop then pcall(task.cancel, data.loop) end
        if btn and btn.Parent then
            btn.Text = "Run"
            btn.TextColor3 = Color3.fromRGB(170, 165, 220)
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end
    table.clear(activeSpamButtons)
end

-- ================================================
--   ADD LOG ENTRY
-- ================================================
local TYPE_COLORS = {
    Gamepass = Color3.fromRGB(100, 180, 255),
    Product  = Color3.fromRGB(255, 200, 80),
    Bulk     = Color3.fromRGB(180, 120, 255),
    Purchase = Color3.fromRGB(80, 255, 160),
}

local function addLog(label, id, signalType)
    if suppressCounter > 0 then return end
    -- Apply filter
    if settings.filterType ~= "All" and settings.filterType ~= signalType then return end
    -- Cap entries for performance
    if #entries >= settings.maxEntries then
        local oldest = entries[#entries]
        if oldest and oldest.Parent then oldest:Destroy() end
        table.remove(entries, #entries)
        eventCount = math.max(0, eventCount - 1)
    end

    setEmpty(false)
    appendLog(label, id)

    local entryHeight = isMobile and 60 or 46
    local entry = Instance.new("Frame", logArea)
    entry.Size = UDim2.new(1, -2, 0, entryHeight)
    entry.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
    entry.BorderSizePixel = 0
    entry.LayoutOrder = -(eventCount)
    entry.BackgroundTransparency = 1
    corner(entry, 10)
    stroke(entry, Color3.fromRGB(48, 46, 70), 1)
    TweenService:Create(entry, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()

    -- Color dot per type
    local dot = Instance.new("Frame", entry)
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 12, 0.5, -4)
    dot.BackgroundColor3 = TYPE_COLORS[signalType] or Color3.fromRGB(61, 255, 160)
    dot.BorderSizePixel = 0
    corner(dot, 999)

    local lbl = Instance.new("TextLabel", entry)
    lbl.Size = UDim2.new(0, 74, 1, 0)
    lbl.Position = UDim2.new(0, 26, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(label)
    lbl.TextColor3 = TYPE_COLORS[signalType] or Color3.fromRGB(160, 150, 210)
    lbl.TextSize = 10 * fontSizeScale
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local idEl = Instance.new("TextLabel", entry)
    idEl.Size = UDim2.new(0, 190, 1, 0)
    idEl.Position = UDim2.new(0, 104, 0, 0)
    idEl.BackgroundTransparency = 1
    idEl.Text = tostring(id)
    idEl.TextColor3 = Color3.fromRGB(220, 220, 240)
    idEl.TextSize = 14 * fontSizeScale
    idEl.Font = Enum.Font.GothamBold
    idEl.TextXAlignment = Enum.TextXAlignment.Left
    idEl.TextTruncate = Enum.TextTruncate.AtEnd

    -- Fire count
    local fireCount = 0
    local fireCountLabel = Instance.new("TextLabel", entry)
    fireCountLabel.Size = UDim2.new(0, 60, 1, 0)
    fireCountLabel.Position = UDim2.new(0, 298, 0, 0)
    fireCountLabel.BackgroundTransparency = 1
    fireCountLabel.Text = "×0"
    fireCountLabel.TextColor3 = Color3.fromRGB(120, 115, 160)
    fireCountLabel.TextSize = 10 * fontSizeScale
    fireCountLabel.Font = Enum.Font.Gotham

    if settings.showTimestamp then
        local timeEl = Instance.new("TextLabel", entry)
        timeEl.Size = UDim2.new(0, 60, 1, 0)
        timeEl.Position = UDim2.new(0, 300, 0, 0)
        timeEl.BackgroundTransparency = 1
        timeEl.Text = os.date("%H:%M:%S")
        timeEl.TextColor3 = Color3.fromRGB(100, 95, 140)
        timeEl.TextSize = 10 * fontSizeScale
        timeEl.Font = Enum.Font.Gotham
        fireCountLabel.Position = UDim2.new(0, 362, 0, 0)
    end

    -- Buttons
    local btnFrame = Instance.new("Frame", entry)
    btnFrame.Size = UDim2.new(0, isMobile and 188 or 178, 1, 0)
    btnFrame.Position = UDim2.new(1, -(isMobile and 192 or 182), 0, 0)
    btnFrame.BackgroundTransparency = 1

    local function makeBtn(txt, xOff, w)
        local b = Instance.new("TextButton", btnFrame)
        b.Size = UDim2.new(0, w, 0, buttonHeight - 4)
        b.Position = UDim2.new(0, xOff, 0.5, -(buttonHeight-4)/2)
        b.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        b.Text = txt
        b.TextColor3 = Color3.fromRGB(170, 165, 220)
        b.TextSize = 11 * fontSizeScale
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        corner(b, 7)
        stroke(b, Color3.fromRGB(55, 50, 85), 1)
        return b
    end

    local autoBtn = makeBtn("Auto", 0, 56)
    local copyBtn = makeBtn("Copy", 62, 56)
    local runBtn  = makeBtn("Run",  124, 52)

    -- Copy
    copyBtn.MouseButton1Click:Connect(function()
        pcall(setclipboard, tostring(id))
        copyBtn.Text = "✓"
        copyBtn.TextColor3 = Color3.fromRGB(61, 255, 160)
        task.wait(1.2)
        if copyBtn.Parent then
            copyBtn.Text = "Copy"
            copyBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
        end
    end)

    -- Auto
    local autoActive = false
    local autoLoop   = nil
    local function startAuto()
        if autoActive then return end
        autoActive = true
        autoBtn.Text = "ON"
        autoBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        autoBtn.BackgroundColor3 = Color3.fromRGB(40, 12, 12)
        local delay = settings.autoSpeed > 0 and (1 / settings.autoSpeed) or 0.01
        autoLoop = task.spawn(function()
            while autoActive and autoBtn.Parent do
                fireFakeSignal(signalType, id)
                fireCount = fireCount + 1
                fireCountLabel.Text = "×" .. fireCount
                task.wait(delay)
            end
        end)
        activeAutoButtons[autoBtn] = {active = true, loop = autoLoop}
    end
    local function stopAuto()
        autoActive = false
        if autoLoop then pcall(task.cancel, autoLoop) end
        activeAutoButtons[autoBtn] = nil
        if autoBtn.Parent then
            autoBtn.Text = "Auto"
            autoBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
            autoBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end
    autoBtn.MouseButton1Click:Connect(function()
        if autoActive then stopAuto() else startAuto() end
    end)

    -- Run (tap = single, hold 3s = spam)
    local isSpamming  = false
    local spamLoop    = nil
    local holdStart   = nil
    local holdConn    = nil

    local function startSpam()
        if isSpamming then return end
        isSpamming = true
        runBtn.Text = "SPAM"
        runBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
        runBtn.BackgroundColor3 = Color3.fromRGB(30, 22, 0)
        spamLoop = task.spawn(function()
            while isSpamming and runBtn.Parent do
                fireFakeSignal(signalType, id)
                fireCount = fireCount + 1
                fireCountLabel.Text = "×" .. fireCount
                task.wait(0.05)
            end
        end)
        activeSpamButtons[runBtn] = {active = true, loop = spamLoop}
    end
    local function stopSpam()
        isSpamming = false
        if spamLoop then pcall(task.cancel, spamLoop) end
        activeSpamButtons[runBtn] = nil
        if runBtn.Parent then
            runBtn.Text = "Run"
            runBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
            runBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        end
    end

    runBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if isSpamming then return end
            holdStart = tick()
            holdConn = task.spawn(function()
                while holdStart and (tick() - holdStart) < 3 do task.wait(0.1) end
                if holdStart and not isSpamming then startSpam() end
            end)
        end
    end)
    runBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local held = holdStart and (tick() - holdStart) or 0
            holdStart = nil
            if holdConn then pcall(task.cancel, holdConn) end
            if isSpamming then
                stopSpam()
            elseif held < 3 then
                fireFakeSignal(signalType, id)
                fireCount = fireCount + 1
                fireCountLabel.Text = "×" .. fireCount
                runBtn.Text = "✓"
                runBtn.TextColor3 = Color3.fromRGB(61, 255, 160)
                task.wait(1.2)
                if runBtn.Parent and not isSpamming then
                    runBtn.Text = "Run"
                    runBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
                end
            end
        end
    end)

    -- Cleanup on removal
    entry.AncestryChanged:Connect(function()
        if not entry.Parent then
            if autoActive then stopAuto() end
            if isSpamming then stopSpam() end
            for i, e in ipairs(entries) do
                if e == entry then table.remove(entries, i) break end
            end
        end
    end)

    eventCount = eventCount + 1
    countLabel.Text = eventCount .. (eventCount == 1 and " event" or " events")
    table.insert(entries, 1, entry)
end

-- ================================================
--   CLEAR BUTTON
-- ================================================
clearBtn.MouseButton1Click:Connect(function()
    stopAllAutoAndSpam()
    for _, e in ipairs(entries) do pcall(function() e:Destroy() end) end
    entries = {}
    eventCount = 0
    countLabel.Text = "0 events"
    logLines = {}
    setEmpty(true)
end)

-- ================================================
--   SAVE LOG BUTTON
-- ================================================
saveLogBtn.MouseButton1Click:Connect(function()
    if #logLines == 0 then
        saveLogBtn.Text = "Nothing!"
        task.wait(1.5)
        saveLogBtn.Text = "💾 Save"
        return
    end
    local ok = pcall(writefile, LOG_FILE, table.concat(logLines, "\n"))
    saveLogBtn.Text = ok and "✅ Saved!" or "❌ Failed"
    task.wait(2)
    saveLogBtn.Text = "💾 Save"
end)

-- ================================================
--   STOP ALL
-- ================================================
stopAllBtn.MouseButton1Click:Connect(stopAllAutoAndSpam)

-- ================================================
--   SETTINGS WINDOW
-- ================================================
local settingsOpen = false
local settingsWindow = nil

local function openSettings()
    if settingsOpen then
        if settingsWindow then settingsWindow:Destroy() end
        settingsOpen = false
        return
    end
    settingsOpen = true

    settingsWindow = Instance.new("Frame", screenGui)
    settingsWindow.Size = UDim2.new(0, isMobile and 300 or 340, 0, 260)
    settingsWindow.Position = UDim2.new(0.5, isMobile and -150 or -170, 0.5, -130)
    settingsWindow.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
    settingsWindow.BorderSizePixel = 0
    settingsWindow.ZIndex = 50
    corner(settingsWindow, 12)
    stroke(settingsWindow, Color3.fromRGB(40, 40, 60), 1.5)

    local stb = Instance.new("Frame", settingsWindow)
    stb.Size = UDim2.new(1, 0, 0, 40)
    stb.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    stb.BorderSizePixel = 0
    stb.ZIndex = 51
    corner(stb, 12)

    local stbFill = Instance.new("Frame", stb)
    stbFill.Size = UDim2.new(1, 0, 0, 12)
    stbFill.Position = UDim2.new(0, 0, 1, -12)
    stbFill.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    stbFill.BorderSizePixel = 0
    stbFill.ZIndex = 51

    local stTitle = Instance.new("TextLabel", stb)
    stTitle.Size = UDim2.new(1, -40, 1, 0)
    stTitle.Position = UDim2.new(0, 12, 0, 0)
    stTitle.BackgroundTransparency = 1
    stTitle.Text = "⚙️  Settings"
    stTitle.TextColor3 = Color3.fromRGB(210, 210, 228)
    stTitle.TextSize = 13
    stTitle.Font = Enum.Font.GothamBold
    stTitle.TextXAlignment = Enum.TextXAlignment.Left
    stTitle.ZIndex = 52

    local stClose = Instance.new("TextButton", stb)
    stClose.Size = UDim2.new(0, 26, 0, 26)
    stClose.Position = UDim2.new(1, -32, 0.5, -13)
    stClose.BackgroundColor3 = Color3.fromRGB(35, 12, 12)
    stClose.Text = "X"
    stClose.TextColor3 = Color3.fromRGB(255, 90, 90)
    stClose.TextSize = 13
    stClose.Font = Enum.Font.GothamBold
    stClose.BorderSizePixel = 0
    stClose.ZIndex = 52
    corner(stClose, 8)
    stClose.MouseButton1Click:Connect(function()
        settingsWindow:Destroy()
        settingsOpen = false
    end)

    makeDraggable(settingsWindow, stb)

    -- Speed setting
    local function makeSettingRow(yPos, labelText, value, hint)
        local lbl = Instance.new("TextLabel", settingsWindow)
        lbl.Size = UDim2.new(0, 160, 0, 28)
        lbl.Position = UDim2.new(0, 16, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(170, 165, 220)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 51

        local box = Instance.new("TextBox", settingsWindow)
        box.Size = UDim2.new(0, 100, 0, 28)
        box.Position = UDim2.new(1, -116, 0, yPos)
        box.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        box.Text = tostring(value)
        box.TextColor3 = Color3.fromRGB(210, 210, 228)
        box.TextSize = 12
        box.Font = Enum.Font.Gotham
        box.BorderSizePixel = 0
        box.ZIndex = 51
        corner(box, 6)
        stroke(box, Color3.fromRGB(55, 50, 85), 1)

        if hint then
            local h = Instance.new("TextLabel", settingsWindow)
            h.Size = UDim2.new(1, -32, 0, 16)
            h.Position = UDim2.new(0, 16, 0, yPos + 30)
            h.BackgroundTransparency = 1
            h.Text = hint
            h.TextColor3 = Color3.fromRGB(100, 100, 140)
            h.TextSize = 10
            h.Font = Enum.Font.Gotham
            h.TextXAlignment = Enum.TextXAlignment.Left
            h.ZIndex = 51
        end

        return box
    end

    local speedBox   = makeSettingRow(50,  "Signals / second:",  settings.autoSpeed,  "1 = slowest  |  10000 = fastest  |  Default: 100")
    local maxEntBox  = makeSettingRow(102, "Max log entries:",   settings.maxEntries, "Older entries removed to keep UI fast")

    -- Timestamp toggle
    local tsLabel = Instance.new("TextLabel", settingsWindow)
    tsLabel.Size = UDim2.new(0, 160, 0, 28)
    tsLabel.Position = UDim2.new(0, 16, 0, 152)
    tsLabel.BackgroundTransparency = 1
    tsLabel.Text = "Show timestamps:"
    tsLabel.TextColor3 = Color3.fromRGB(170, 165, 220)
    tsLabel.TextSize = 12
    tsLabel.Font = Enum.Font.Gotham
    tsLabel.TextXAlignment = Enum.TextXAlignment.Left
    tsLabel.ZIndex = 51

    local tsToggle = Instance.new("TextButton", settingsWindow)
    tsToggle.Size = UDim2.new(0, 60, 0, 26)
    tsToggle.Position = UDim2.new(1, -76, 0, 153)
    tsToggle.BorderSizePixel = 0
    tsToggle.TextSize = 11
    tsToggle.Font = Enum.Font.GothamBold
    tsToggle.ZIndex = 51
    corner(tsToggle, 8)

    local function updateTsToggle()
        if settings.showTimestamp then
            tsToggle.Text = "ON"
            tsToggle.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
            tsToggle.TextColor3 = Color3.fromRGB(61, 255, 160)
        else
            tsToggle.Text = "OFF"
            tsToggle.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
            tsToggle.TextColor3 = Color3.fromRGB(170, 165, 220)
        end
    end
    updateTsToggle()
    tsToggle.MouseButton1Click:Connect(function()
        settings.showTimestamp = not settings.showTimestamp
        updateTsToggle()
    end)

    -- Save settings
    local saveBtn = Instance.new("TextButton", settingsWindow)
    saveBtn.Size = UDim2.new(0, 110, 0, 32)
    saveBtn.Position = UDim2.new(0.5, -55, 1, -44)
    saveBtn.BackgroundColor3 = Color3.fromRGB(22, 18, 40)
    saveBtn.Text = "Save Settings"
    saveBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
    saveBtn.TextSize = 12
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.BorderSizePixel = 0
    saveBtn.ZIndex = 51
    corner(saveBtn, 8)
    stroke(saveBtn, Color3.fromRGB(55, 50, 85), 1.5)

    saveBtn.MouseButton1Click:Connect(function()
        local spd = tonumber(speedBox.Text)
        local mx  = tonumber(maxEntBox.Text)
        if spd then settings.autoSpeed  = math.clamp(spd, 1, 10000) end
        if mx  then settings.maxEntries = math.clamp(mx,  10, 200)  end
        saveSettings()
        saveBtn.Text = "✅ Saved!"
        saveBtn.TextColor3 = Color3.fromRGB(61, 255, 160)
        task.wait(1.5)
        if saveBtn.Parent then
            saveBtn.Text = "Save Settings"
            saveBtn.TextColor3 = Color3.fromRGB(170, 165, 220)
        end
    end)
end

settingsBtn.MouseButton1Click:Connect(openSettings)

-- ================================================
--   MINIMIZE / SHOW
-- ================================================
local function hideGui()
    panel.Visible = false
    miniBubble.Visible = true
end

local function showGui()
    panel.Visible = true
    miniBubble.Visible = false
end

minBtn.MouseButton1Click:Connect(hideGui)
closeBtn.MouseButton1Click:Connect(hideGui)
miniBubble.MouseButton1Click:Connect(showGui)

-- PC keyboard toggle
if not isMobile then
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            if panel.Visible then hideGui() else showGui() end
        end
    end)
end

-- ================================================
--   MARKETPLACE LISTENERS
-- ================================================
MarketplaceService.PromptProductPurchaseFinished:Connect(function(plr, id, bought)
    if suppressCounter == 0 then addLog("Product",  id, "Product")  end
end)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, id, bought)
    if suppressCounter == 0 then addLog("Gamepass", id, "Gamepass") end
end)
MarketplaceService.PromptBulkPurchaseFinished:Connect(function(userId, id, bought)
    if suppressCounter == 0 then addLog("Bulk",     id, "Bulk")     end
end)
MarketplaceService.PromptPurchaseFinished:Connect(function(userId, id, bought)
    if suppressCounter == 0 then addLog("Purchase", id, "Purchase") end
end)

print("[SELUWIA] ✅ Loaded — Improved Edition")
