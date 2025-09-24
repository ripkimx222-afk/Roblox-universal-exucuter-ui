-- Universal Executor UI (final polished build)
-- Работает с движением, односторонним ресайзом, настройками и темами

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function New(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local screen = New("ScreenGui", {Name = "UniversalExecutorUI_final", ResetOnSpawn = false}, playerGui)

-- Themes
local Themes = {
    ["Purple Black"] = {
        Background = Color3.fromRGB(40, 0, 60),
        Accent = Color3.fromRGB(150, 90, 220),
        Text = Color3.new(1,1,1)
    },
    ["Pay to Win"] = {
        Background = Color3.fromRGB(10, 10, 10),
        Accent = Color3.fromRGB(255, 220, 0),
        Text = Color3.fromRGB(255, 255, 0)
    },
    ["Cyber Blue"] = {
        Background = Color3.fromRGB(15, 15, 25),
        Accent = Color3.fromRGB(0, 180, 255),
        Text = Color3.fromRGB(200, 240, 255)
    },
    ["Pastel Dream"] = {
        Background = Color3.fromRGB(245, 230, 255),
        Accent = Color3.fromRGB(255, 150, 200),
        Text = Color3.fromRGB(60, 60, 80)
    }
}

local CurrentTheme = "Purple Black"

local DEFAULT_W, DEFAULT_H = 720, 480
local main = New("Frame", {
    Size = UDim2.new(0, DEFAULT_W, 0, DEFAULT_H),
    Position = UDim2.new(0.5, -DEFAULT_W/2, 0.5, -DEFAULT_H/2),
    BackgroundColor3 = Themes[CurrentTheme].Background,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Visible = true
}, screen)
New("UICorner", {CornerRadius = UDim.new(0, 14)}, main)

-- Dragging
local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Resize (односторонний)
local resizeBtn = New("Frame", {
    Size = UDim2.new(0, 18, 0, 18),
    Position = UDim2.new(1, -18, 1, -18),
    BackgroundColor3 = Themes[CurrentTheme].Accent,
    BorderSizePixel = 0,
    Parent = main
})
New("UICorner", {CornerRadius = UDim.new(0,6)}, resizeBtn)

local resizing, resizeStart, startSize
resizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        resizeStart = input.Position
        startSize = main.Size
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizing then
        local delta = input.Position - resizeStart
        main.Size = UDim2.new(startSize.X.Scale, math.max(360, startSize.X.Offset + delta.X),
                              startSize.Y.Scale, math.max(240, startSize.Y.Offset + delta.Y))
    end
end)

-- Tabs
local tabHolder = New("Frame", {
    Size = UDim2.new(0, 160, 1, 0),
    BackgroundColor3 = Themes[CurrentTheme].Accent,
    Parent = main
})
New("UICorner", {CornerRadius = UDim.new(0,14)}, tabHolder)

local pages = New("Frame", {
    Size = UDim2.new(1, -160, 1, 0),
    Position = UDim2.new(0, 160, 0, 0),
    BackgroundTransparency = 1,
    Parent = main
})

-- Page switch
local pageFrames = {}
local function addPage(name)
    local btn = New("TextButton", {
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.new(0, 10, 0, (#tabHolder:GetChildren()-1)*60 + 20),
        BackgroundColor3 = Themes[CurrentTheme].Background,
        Text = name,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Themes[CurrentTheme].Text,
        Parent = tabHolder
    })
    New("UICorner", {CornerRadius = UDim.new(0,8)}, btn)

    local page = New("Frame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = pages
    })
    pageFrames[name] = page

    btn.MouseButton1Click:Connect(function()
        for n,f in pairs(pageFrames) do f.Visible = false end
        page.Visible = true
    end)

    return page
end

-- Main page
local mainPage = addPage("Main")
local execBox = New("TextBox", {
    Size = UDim2.new(1, -40, 0, 120),
    Position = UDim2.new(0,20,0,20),
    BackgroundColor3 = Themes[CurrentTheme].Background,
    Text = "-- Enter Lua code here",
    Font = Enum.Font.Code,
    TextSize = 16,
    TextColor3 = Themes[CurrentTheme].Text,
    ClearTextOnFocus = false,
    Parent = mainPage
})
New("UICorner", {CornerRadius = UDim.new(0,8)}, execBox)

local execBtn = New("TextButton", {
    Size = UDim2.new(0,120,0,40),
    Position = UDim2.new(0,20,0,160),
    BackgroundColor3 = Themes[CurrentTheme].Accent,
    Text = "Execute",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Themes[CurrentTheme].Text,
    Parent = mainPage
})
New("UICorner", {CornerRadius = UDim.new(0,8)}, execBtn)

-- Executors page
local execPage = addPage("Executors")
New("TextLabel", {
    Size = UDim2.new(1, -40, 0, 40),
    Position = UDim2.new(0,20,0,20),
    BackgroundTransparency = 1,
    Text = "Выбор базы: XENO / Delta X / KRNL / Arceus X / Fluxus",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Themes[CurrentTheme].Text,
    Parent = execPage
})

-- Settings page
local settingsPage = addPage("Settings")
local themeBtn = New("TextButton", {
    Size = UDim2.new(0,200,0,40),
    Position = UDim2.new(0,20,0,20),
    BackgroundColor3 = Themes[CurrentTheme].Accent,
    Text = "Theme: "..CurrentTheme,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Themes[CurrentTheme].Text,
    Parent = settingsPage
})
New("UICorner", {CornerRadius = UDim.new(0,8)}, themeBtn)

themeBtn.MouseButton1Click:Connect(function()
    local names = {}
    for n in pairs(Themes) do table.insert(names,n) end
    local idx = table.find(names, CurrentTheme) or 1
    idx = idx % #names + 1
    CurrentTheme = names[idx]
    themeBtn.Text = "Theme: "..CurrentTheme
    main.BackgroundColor3 = Themes[CurrentTheme].Background
    tabHolder.BackgroundColor3 = Themes[CurrentTheme].Accent
    execBox.BackgroundColor3 = Themes[CurrentTheme].Background
    execBtn.BackgroundColor3 = Themes[CurrentTheme].Accent
end)

-- Disclaimer page
local disclaimer = addPage("Disclaimer")
New("TextLabel", {
    Size = UDim2.new(1, -40, 0, 120),
    Position = UDim2.new(0,20,0,20),
    BackgroundTransparency = 1,
    TextWrapped = true,
    Text = "Скрипт создан исключительно в развлекательных целях. Не злоупотребляйте. Beta версия.",
    Font = Enum.Font.Gotham,
    TextSize = 18,
    TextColor3 = Themes[CurrentTheme].Text,
    Parent = disclaimer
})

-- Default visible page
mainPage.Visible = true
