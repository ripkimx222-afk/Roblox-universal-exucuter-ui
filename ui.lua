--[[
  Fog Hub - Universal Executors (responsive & optimized)
  By Hikmes0 (updated)
  - Убрана кнопка "Copy raw link" в Universal
  - Тексты адаптивны (TextScaled где нужно)
  - Оптимизировано обновление при ресайзе (debounce)
  - Плавные анимации переключений вкладок
  - Темы отображаются в Grid внутри ScrollingFrame
  - Улучшены UX: hover эффекты, тест исполнителя, профили, execute/beautify/clear/delay
  Требует (опционально) writefile/readfile/isfile/delfile (для сохранений)
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- File API detection
local HAS_WRITEFILE = type(writefile) == "function"
local HAS_READFILE  = type(readfile) == "function"
local HAS_ISFILE    = type(isfile) == "function"
local HAS_DELFILE   = type(delfile) == "function"

local SETTINGS_FILE = "FogHub_Settings.json"
local PROFILES_FILE = "FogHub_Profiles.json"

-- Helpers
local function safeEncode(t)
    local ok, res = pcall(function() return HttpService:JSONEncode(t) end)
    if ok then return res end
    return nil
end
local function safeDecode(s)
    if type(s) ~= "string" then return nil end
    local ok, res = pcall(function() return HttpService:JSONDecode(s) end)
    if ok then return res end
    return nil
end
local function safeRead(name)
    if HAS_READFILE then
        local ok, res = pcall(readfile, name)
        if ok then return res end
    end
    return nil
end
local function safeWrite(name, text)
    if HAS_WRITEFILE then
        local ok, err = pcall(function() writefile(name, text) end)
        return ok, err
    end
    return false, "no_writefile"
end

-- Config
local THEMES = {
    ["Dark Purple"] = { window=Color3.fromRGB(42,18,66), accent=Color3.fromRGB(173,107,255), button=Color3.fromRGB(255,205,0), symbol="⚡" },
    ["Cyberpunk"]   = { window=Color3.fromRGB(8,8,18),  accent=Color3.fromRGB(0,200,255),   button=Color3.fromRGB(0,200,255),   symbol="💠" },
    ["Neon"]        = { window=Color3.fromRGB(25,0,40), accent=Color3.fromRGB(255,0,200),   button=Color3.fromRGB(255,0,200),   symbol="✨" },
    ["Matrix"]      = { window=Color3.fromRGB(6,6,6),   accent=Color3.fromRGB(0,255,120),   button=Color3.fromRGB(0,200,0),     symbol="🟢" },
    ["Inferno"]     = { window=Color3.fromRGB(30,6,6),  accent=Color3.fromRGB(255,80,0),    button=Color3.fromRGB(255,140,0),   symbol="🔥" },
    ["Crystal"]     = { window=Color3.fromRGB(38,6,66), accent=Color3.fromRGB(170,120,255), button=Color3.fromRGB(170,120,255), symbol="💎" },
    ["Pay2Win"]     = { window=Color3.fromRGB(12,8,10), accent=Color3.fromRGB(255,210,0),   button=Color3.fromRGB(255,200,0),   symbol="💰" },
}

local DEFAULT_THEME = "Dark Purple"
local DEFAULT_LANG = "RU"
local DEFAULT_BASE = "KRNL"
local MAX_PROFILES = 3
local MIN_SIZE = Vector2.new(360,220)

local LANG = {
    RU = {
        tabs = {"Главная","База","Универсальные","Профили","Настройки"},
        executor = "Исполнитель: %s",
        execute = "Выполнить",
        placeholder = "-- Вставь код сюда",
        infinite = "Infinite Yield",
        toast_loaded = "Fog Hub запущен",
        toast_executed = "Скрипт отправлен в %s",
        toast_base = "Выбрана база: %s",
        toast_saved = "Профиль сохранён",
        toast_loaded_profile = "Профиль загружен",
        toast_deleted = "Профиль удалён",
        clear = "Очистить",
        beautify = "Формат",
        delay = "Задержка (с)",
        empty = "Пусто"
    },
    EN = {
        tabs = {"Main","Base","Universal","Profiles","Settings"},
        executor = "Executor: %s",
        execute = "Execute",
        placeholder = "-- Enter code here",
        infinite = "Infinite Yield",
        toast_loaded = "Fog Hub started",
        toast_executed = "Script sent to %s",
        toast_base = "Base selected: %s",
        toast_saved = "Profile saved",
        toast_loaded_profile = "Profile loaded",
        toast_deleted = "Profile deleted",
        clear = "Clear",
        beautify = "Beautify",
        delay = "Delay (s)",
        empty = "Empty"
    }
}

-- Load / init settings & profiles
local SETTINGS = {
    Theme = DEFAULT_THEME,
    Language = DEFAULT_LANG,
    Position = {0.2,0,0.2,0},
    Size = {820, 340},
    SelectedBase = DEFAULT_BASE,
    SFX = true
}
local PROFILES = { nil, nil, nil }

do
    local s = safeRead(SETTINGS_FILE)
    local t = safeDecode(s)
    if type(t) == "table" then
        SETTINGS.Theme = t.Theme or SETTINGS.Theme
        SETTINGS.Language = t.Language or SETTINGS.Language
        if type(t.Position) == "table" and #t.Position >= 4 then SETTINGS.Position = t.Position end
        if type(t.Size) == "table" and #t.Size >= 2 then SETTINGS.Size = t.Size end
        SETTINGS.SelectedBase = t.SelectedBase or SETTINGS.SelectedBase
        SETTINGS.SFX = (t.SFX == nil) and SETTINGS.SFX or not not t.SFX
    end
    local p = safeRead(PROFILES_FILE)
    local pt = safeDecode(p)
    if type(pt) == "table" then
        for i=1,MAX_PROFILES do PROFILES[i] = pt[i] end
    end
end

local function persistSettings()
    local ok, err = pcall(function()
        local s = safeEncode(SETTINGS)
        if s then safeWrite(SETTINGS_FILE, s) end
    end)
    if not ok then warn("Persist settings failed:", err) end
end
local function persistProfiles()
    local ok, err = pcall(function()
        local s = safeEncode(PROFILES)
        if s then safeWrite(PROFILES_FILE, s) end
    end)
    if not ok then warn("Persist profiles failed:", err) end
end

-- Executors (common + extras)
local EXECUTORS = {
    ["XENO"] = function(code) if syn and type(loadstring)=="function" then return pcall(loadstring, code) end return false end,
    ["DELTA X"] = function(code) if delta and type(delta.execute)=="function" then return pcall(function() delta.execute(code) end) end return false end,
    ["KRNL"] = function(code) 
        if KRNL and type(KRNL.execute)=="function" then return pcall(function() KRNL.execute(code) end) end
        if krnl and type(krnl.execute)=="function" then return pcall(function() krnl.execute(code) end) end
        if loadstring then return pcall(loadstring, code) end
        return false
    end,
    ["Arceus X"] = function(code) if ArceusX and type(ArceusX.execute)=="function" then return pcall(function() ArceusX.execute(code) end) end return false end,
    ["Fluxus"] = function(code) if fluxus and type(fluxus.execute)=="function" then return pcall(function() fluxus.execute(code) end) end return false end,
    ["Electron"] = function(code) if electron and type(electron.execute)=="function" then return pcall(function() electron.execute(code) end) end return false end,
    ["Oxygen U"] = function(code) if oxygen and type(oxygen.execute)=="function" then return pcall(function() oxygen.execute(code) end) end return false end,
    ["Script-Ware"] = function(code) if is_sirhurt_closure then return pcall(function() loadstring(code)() end) end if loadstring then return pcall(loadstring, code) end return false end,
    ["Evon"] = function(code) if evon and type(evon.execute)=="function" then return pcall(function() evon.execute(code) end) end return false end,
}

local BASES = {"KRNL","DELTA X","XENO","Arceus X","Fluxus","Electron","Oxygen U","Script-Ware","Evon"}
SETTINGS.SelectedBase = SETTINGS.SelectedBase or DEFAULT_BASE

-- ========== Build GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FogHubGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- SFX folder (optional)
local SFX = Instance.new("Folder", screenGui); SFX.Name = "SFX"

-- Window
local Window = Instance.new("Frame", screenGui)
Window.Name = "Fog_Window"
Window.Size = UDim2.new(0, SETTINGS.Size[1], 0, SETTINGS.Size[2])
Window.Position = UDim2.new(SETTINGS.Position[1], SETTINGS.Position[2] or 0, SETTINGS.Position[3], SETTINGS.Position[4] or 0)
Window.BackgroundColor3 = THEMES[SETTINGS.Theme].window
Window.ClipsDescendants = true
Window.Active = true
local winCorner = Instance.new("UICorner", Window); winCorner.CornerRadius = UDim.new(0,12)
local winStroke = Instance.new("UIStroke", Window); winStroke.Color = THEMES[SETTINGS.Theme].accent; winStroke.Thickness = 1; winStroke.Transparency = 0.35

-- Header
local Header = Instance.new("Frame", Window); Header.Size = UDim2.new(1,0,0,52); Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header); Title.Position = UDim2.new(0,12,0,6); Title.Size = UDim2.new(0.6,0,0,28); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.Text = "Fog Hub"; Title.TextColor3 = Color3.new(1,1,1); Title.TextScaled = true
local Subtitle = Instance.new("TextLabel", Header); Subtitle.Position = UDim2.new(0,12,0,30); Subtitle.Size = UDim2.new(0.6,0,0,16); Subtitle.BackgroundTransparency = 1; Subtitle.Font = Enum.Font.Gotham; Subtitle.Text = "Universal Executors"; Subtitle.TextColor3 = Color3.fromRGB(200,200,200); Subtitle.TextScaled = true
local CloseBtn = Instance.new("TextButton", Header); CloseBtn.Size = UDim2.new(0,36,0,28); CloseBtn.Position = UDim2.new(1,-48,0,10); CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.TextScaled = true; CloseBtn.BackgroundTransparency = 0.4
local closeCorner = Instance.new("UICorner", CloseBtn); closeCorner.CornerRadius = UDim.new(0,6)

-- Footer
local Footer = Instance.new("Frame", Window); Footer.Size = UDim2.new(1,0,0,24); Footer.Position = UDim2.new(0,0,1,-24); Footer.BackgroundTransparency = 1
local FooterText = Instance.new("TextLabel", Footer); FooterText.Position = UDim2.new(0,12,0,2); FooterText.Size = UDim2.new(1,-24,1,-4); FooterText.BackgroundTransparency = 1; FooterText.Font = Enum.Font.Gotham; FooterText.Text = "By Hikmes0"; FooterText.TextTransparency = 0.5; FooterText.TextScaled = true

-- Tabs column
local TabsCol = Instance.new("Frame", Window); TabsCol.Size = UDim2.new(0,160,1,-92); TabsCol.Position = UDim2.new(0,12,0,60); TabsCol.BackgroundTransparency = 1
local TabsBg = Instance.new("Frame", TabsCol); TabsBg.Size = UDim2.new(1,0,1,0); TabsBg.BackgroundColor3 = Color3.fromRGB(18,10,28); local tabsCorner = Instance.new("UICorner", TabsBg); tabsCorner.CornerRadius = UDim.new(0,10)
local TabsLayout = Instance.new("UIListLayout", TabsBg); TabsLayout.Padding = UDim.new(0,8); TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Content
local Content = Instance.new("Frame", Window); Content.Size = UDim2.new(1,-188,1,-92); Content.Position = UDim2.new(0,180,0,60); Content.BackgroundTransparency = 1
local Pages = Instance.new("Folder", Content); Pages.Name = "Pages"

-- Resizer (bottom-right)
local Resizer = Instance.new("Frame", Window); Resizer.Size = UDim2.new(0,14,0,14); Resizer.Position = UDim2.new(1,-18,1,-18); Resizer.BackgroundColor3 = Color3.fromRGB(255,255,255); local resCorner = Instance.new("UICorner", Resizer); resCorner.CornerRadius = UDim.new(0,3)

-- Toggle button (movable)
local ToggleBtn = Instance.new("TextButton", screenGui); ToggleBtn.Size = UDim2.new(0,64,0,64); ToggleBtn.Position = UDim2.new(0,12,0.6,-32); ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.Text = THEMES[SETTINGS.Theme].symbol; ToggleBtn.BackgroundColor3 = THEMES[SETTINGS.Theme].button; ToggleBtn.AutoButtonColor = false
local toggleCorner = Instance.new("UICorner", ToggleBtn); toggleCorner.CornerRadius = UDim.new(1,0)

-- Create tabs and pages
local TAB_ORDER = {"Main","Base","Universal","Profiles","Settings"}
local TabButtons = {}
local PageFrames = {}

local function createTab(name)
    local btn = Instance.new("TextButton", TabsBg)
    btn.Size = UDim2.new(1,-16,0,44)
    btn.Position = UDim2.new(0,8,0,0)
    btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Text = name
    btn.AutoButtonColor = false
    btn.TextScaled = true
    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0,8)

    local page = Instance.new("Frame", Pages)
    page.Name = name.."_Page"
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false

    -- hover bg visual (subtle)
    local hover = Instance.new("Frame", btn)
    hover.Name = "Hover"
    hover.Size = UDim2.new(1,0,1,0)
    hover.BackgroundTransparency = 1
    hover.BackgroundColor3 = Color3.fromRGB(255,255,255)
    hover.ZIndex = 0

    btn.MouseEnter:Connect(function()
        TweenService:Create(hover, TweenInfo.new(0.12), {BackgroundTransparency = 0.93}):Play()
        TweenService:Create(btn, TweenInfo.new(0.12), {TextColor3 = THEMES[SETTINGS.Theme].accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(hover, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
        TweenService:Create(btn, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(220,220,220)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        for k,v in pairs(PageFrames) do
            -- fade out
            TweenService:Create(v, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
            v.Visible = false
        end
        page.Visible = true
        page.BackgroundTransparency = 0
        for _,b in pairs(TabButtons) do b.TextColor3 = Color3.fromRGB(200,200,200) end
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        -- little pop animation for selected tab
        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Size = UDim2.new(1,-16,0,46)}):Play()
        task.delay(0.18, function() pcall(function() btn.Size = UDim2.new(1,-16,0,44) end) end)
    end)

    TabButtons[name] = btn
    PageFrames[name] = page
    return btn, page
end

for _,n in ipairs(TAB_ORDER) do createTab(n) end

-- Local helper for toast
local function showToast(text)
    local toast = Instance.new("Frame", screenGui); toast.Size = UDim2.new(0,280,0,44); toast.Position = UDim2.new(1,-300,1,-60); toast.BackgroundColor3 = Color3.fromRGB(28,28,28); toast.ZIndex = 1000
    local tc = Instance.new("UICorner", toast); tc.CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", toast); label.Size = UDim2.new(1,-12,1,-12); label.Position = UDim2.new(0,6,0,6); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamBold; label.TextColor3 = Color3.new(1,1,1)
    label.Text = text; label.TextScaled = true; label.TextXAlignment = Enum.TextXAlignment.Left
    TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Position = UDim2.new(1,-300,1,-120)}):Play()
    task.delay(3, function()
        TweenService:Create(label, TweenInfo.new(0.28), {TextTransparency = 1}):Play()
        TweenService:Create(toast, TweenInfo.new(0.28), {BackgroundTransparency = 1}):Play()
        task.delay(0.32, function() pcall(function() toast:Destroy() end) end)
    end)
end

-- Optimized responsive approach:
-- Use TextScaled for most static labels/buttons so they always fit.
-- For code TextBox keep dynamic text size but allow wrap. Use debounce for size updates.

-- MAIN PAGE
do
    local page = PageFrames["Main"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.Text = LANG[SETTINGS.Language].tabs[1]; header.TextScaled = true

    local execLabel = Instance.new("TextLabel", page); execLabel.Name = "ExecLabel"; execLabel.Size = UDim2.new(1,-24,0,20); execLabel.Position = UDim2.new(0,12,0,36); execLabel.BackgroundTransparency = 1; execLabel.Font = Enum.Font.Gotham; execLabel.TextColor3 = Color3.fromRGB(210,210,210); execLabel.Text = string.format(LANG[SETTINGS.Language].executor, SETTINGS.SelectedBase); execLabel.TextScaled = true

    local codeBox = Instance.new("TextBox", page); codeBox.Name = "CodeBox"; codeBox.Position = UDim2.new(0,12,0,66); codeBox.Size = UDim2.new(1,-24,0.62,-66); codeBox.BackgroundColor3 = Color3.fromRGB(28,14,40); codeBox.TextColor3 = Color3.fromRGB(240,240,240); codeBox.Font = Enum.Font.Code; codeBox.TextSize = 14; codeBox.TextWrapped = true; codeBox.MultiLine = true; codeBox.ClearTextOnFocus = false; codeBox.PlaceholderText = LANG[SETTINGS.Language].placeholder

    local cbCorner = Instance.new("UICorner", codeBox); cbCorner.CornerRadius = UDim.new(0,8)

    local clearBtn = Instance.new("TextButton", page); clearBtn.Size = UDim2.new(0,84,0,32); clearBtn.Position = UDim2.new(0,12,1,-44); clearBtn.Text = LANG[SETTINGS.Language].clear; clearBtn.Font = Enum.Font.Gotham; clearBtn.TextScaled = true; local cc = Instance.new("UICorner", clearBtn); cc.CornerRadius = UDim.new(0,6)
    local beautBtn = Instance.new("TextButton", page); beautBtn.Size = UDim2.new(0,84,0,32); beautBtn.Position = UDim2.new(0,108,1,-44); beautBtn.Text = LANG[SETTINGS.Language].beautify; beautBtn.Font = Enum.Font.Gotham; beautBtn.TextScaled = true; local bc = Instance.new("UICorner", beautBtn); bc.CornerRadius = UDim.new(0,6)
    local delayLbl = Instance.new("TextLabel", page); delayLbl.Position = UDim2.new(1,-340,1,-40); delayLbl.Size = UDim2.new(0,120,0,24); delayLbl.BackgroundTransparency = 1; delayLbl.Font = Enum.Font.Gotham; delayLbl.Text = LANG[SETTINGS.Language].delay; delayLbl.TextScaled = true
    local delayBox = Instance.new("TextBox", page); delayBox.Size = UDim2.new(0,84,0,32); delayBox.Position = UDim2.new(1,-220,1,-44); delayBox.PlaceholderText = "0"; delayBox.Font = Enum.Font.Gotham; delayBox.TextScaled = true; local dbc = Instance.new("UICorner", delayBox); dbc.CornerRadius = UDim.new(0,6)

    local execBtn = Instance.new("TextButton", page); execBtn.Name = "ExecBtn"; execBtn.Size = UDim2.new(0,140,0,40); execBtn.Position = UDim2.new(0.5,-70,0.86,0); execBtn.Font = Enum.Font.GothamBold; execBtn.Text = LANG[SETTINGS.Language].execute; execBtn.TextColor3 = Color3.new(1,1,1); execBtn.TextScaled = true; execBtn.BackgroundColor3 = THEMES[SETTINGS.Theme].accent; local ebc = Instance.new("UICorner", execBtn); ebc.CornerRadius = UDim.new(0,8)

    -- quick preset
    local preset1 = Instance.new("TextButton", page); preset1.Size = UDim2.new(0,120,0,28); preset1.Position = UDim2.new(0,160,0.72,0); preset1.Text = "print('Hi')"; preset1.Font = Enum.Font.Gotham; preset1.TextScaled = true; local p1c = Instance.new("UICorner", preset1); p1c.CornerRadius = UDim.new(0,6)
    preset1.MouseButton1Click:Connect(function() codeBox.Text = "print('Hello from Fog Hub')\n" end)

    beautBtn.MouseButton1Click:Connect(function()
        local txt = codeBox.Text or ""
        txt = txt:gsub("[ \t]+(\n)","%1")
        txt = txt:gsub("\r","")
        txt = txt:gsub("\n%s*\n","\n\n")
        if not txt:match("\n$") then txt = txt.."\n" end
        codeBox.Text = txt
        showToast("Formatted")
    end)

    clearBtn.MouseButton1Click:Connect(function()
        codeBox.Text = ""
        showToast(LANG[SETTINGS.Language].clear)
    end)

    execBtn.MouseButton1Click:Connect(function()
        local code = codeBox.Text or ""
        local d = tonumber(delayBox.Text) or 0
        local function run()
            local fn = EXECUTORS[SETTINGS.SelectedBase]
            local ok, res = false, nil
            if type(fn) == "function" then ok, res = pcall(function() return fn(code) end) end
            if not ok or res == false then
                local ok2, err2 = pcall(function() if loadstring then loadstring(code)() end end)
                if not ok2 then showToast("Execute error: "..tostring(err2)) else showToast(string.format(LANG[SETTINGS.Language].toast_executed, SETTINGS.SelectedBase)) end
            else
                showToast(string.format(LANG[SETTINGS.Language].toast_executed, SETTINGS.SelectedBase))
            end
        end
        if d > 0 then
            showToast("Executing in "..d.."s")
            spawn(function() task.wait(d); run() end)
        else
            run()
        end
    end)
end

-- BASE page
do
    local page = PageFrames["Base"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.Text = LANG[SETTINGS.Language].tabs[2]; header.TextScaled = true
    local scroll = Instance.new("ScrollingFrame", page); scroll.Position = UDim2.new(0,12,0,44); scroll.Size = UDim2.new(1,-24,1,-56); scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 8
    local layout = Instance.new("UIListLayout", scroll); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,8)

    for i,b in ipairs(BASES) do
        local btn = Instance.new("TextButton", scroll); btn.Size = UDim2.new(1,-12,0,40); btn.BackgroundColor3 = Color3.fromRGB(28,12,36); btn.Font = Enum.Font.Gotham; btn.Text = b; btn.TextColor3 = Color3.fromRGB(235,235,235); btn.TextScaled = true; local bc = Instance.new("UICorner", btn); bc.CornerRadius = UDim.new(0,8)
        btn.MouseButton1Click:Connect(function()
            SETTINGS.SelectedBase = b
            persistSettings()
            local execLabel = PageFrames["Main"]:FindFirstChild("ExecLabel")
            if execLabel then execLabel.Text = string.format(LANG[SETTINGS.Language].executor, b) end
            showToast(string.format(LANG[SETTINGS.Language].toast_base, b))
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = THEMES[SETTINGS.Theme].accent}):Play()
            task.delay(0.12, function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(28,12,36)}):Play() end)
        end)
    end

    -- Test executor
    local testBtn = Instance.new("TextButton", page); testBtn.Size = UDim2.new(0.38,0,0,32); testBtn.Position = UDim2.new(0.58,0,0,6); testBtn.Text = "Test Executor"; testBtn.Font = Enum.Font.Gotham; testBtn.TextScaled = true; local tc = Instance.new("UICorner", testBtn); tc.CornerRadius = UDim.new(0,6)
    testBtn.MouseButton1Click:Connect(function()
        local base = SETTINGS.SelectedBase or DEFAULT_BASE
        local fn = EXECUTORS[base]
        local ok, res = false, nil
        if type(fn) == "function" then ok, res = pcall(function() return fn("print('FogHub test')") end) end
        if ok and res ~= false then showToast("Executor "..base.." available") else showToast("Executor "..base.." unavailable") end
    end)
end

-- UNIVERSAL page (removed copy raw link per request)
do
    local page = PageFrames["Universal"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.Text = LANG[SETTINGS.Language].tabs[3]; header.TextScaled = true
    local infBtn = Instance.new("TextButton", page); infBtn.Size = UDim2.new(0.46,0,0,40); infBtn.Position = UDim2.new(0.27,0,0.18,0); infBtn.Text = LANG[SETTINGS.Language].infinite; infBtn.Font = Enum.Font.GothamBold; infBtn.TextScaled = true; infBtn.BackgroundColor3 = Color3.fromRGB(0,120,200); local ic = Instance.new("UICorner", infBtn); ic.CornerRadius = UDim.new(0,8)
    infBtn.MouseButton1Click:Connect(function()
        local ok, err = pcall(function()
            local src = game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
            loadstring(src)()
        end)
        if ok then showToast("Infinite Yield started") else showToast("Error: "..tostring(err)) end
    end)
end

-- PROFILES page
do
    local page = PageFrames["Profiles"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.Text = LANG[SETTINGS.Language].tabs[4]; header.TextScaled = true
    local frame = Instance.new("Frame", page); frame.Position = UDim2.new(0,12,0,44); frame.Size = UDim2.new(1,-24,1,-56); frame.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", frame); layout.Padding = UDim.new(0,8)

    for i=1,MAX_PROFILES do
        local slot = Instance.new("Frame", frame); slot.Size = UDim2.new(1,0,0,84); slot.BackgroundColor3 = Color3.fromRGB(24,10,30); local sc = Instance.new("UICorner", slot); sc.CornerRadius = UDim.new(0,8)
        local nameLbl = Instance.new("TextLabel", slot); nameLbl.Position = UDim2.new(0,12,0,8); nameLbl.Size = UDim2.new(0.5,-24,0,24); nameLbl.BackgroundTransparency = 1; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextColor3 = Color3.fromRGB(235,235,235); nameLbl.TextScaled = true
        nameLbl.Text = (PROFILES[i] and PROFILES[i].Name) or LANG[SETTINGS.Language].empty

        local btnRename = Instance.new("TextButton", slot); btnRename.Size = UDim2.new(0,84,0,28); btnRename.Position = UDim2.new(1,-96,0,8); btnRename.Text = "Rename"; btnRename.Font = Enum.Font.Gotham; btnRename.TextScaled = true; local ruc = Instance.new("UICorner", btnRename); ruc.CornerRadius = UDim.new(0,6)
        local btnSave = Instance.new("TextButton", slot); btnSave.Size = UDim2.new(0,84,0,28); btnSave.Position = UDim2.new(1,-96,0,44); btnSave.Text = "Save"; btnSave.Font = Enum.Font.Gotham; btnSave.TextScaled = true; local sc2 = Instance.new("UICorner", btnSave); sc2.CornerRadius = UDim.new(0,6)
        local btnLoad = Instance.new("TextButton", slot); btnLoad.Size = UDim2.new(0,84,0,28); btnLoad.Position = UDim2.new(1,-186,0,44); btnLoad.Text = "Load"; btnLoad.Font = Enum.Font.Gotham; btnLoad.TextScaled = true; local lc = Instance.new("UICorner", btnLoad); lc.CornerRadius = UDim.new(0,6)
        local btnDelete = Instance.new("TextButton", slot); btnDelete.Size = UDim2.new(0,84,0,28); btnDelete.Position = UDim2.new(1,-276,0,44); btnDelete.Text = "Delete"; btnDelete.Font = Enum.Font.Gotham; btnDelete.TextScaled = true; local dc = Instance.new("UICorner", btnDelete); dc.CornerRadius = UDim.new(0,6)

        btnSave.MouseButton1Click:Connect(function()
            local prof = {
                Name = (PROFILES[i] and PROFILES[i].Name) or ("Profile "..i),
                Theme = SETTINGS.Theme,
                Language = SETTINGS.Language,
                Position = { Window.Position.X.Scale, Window.Position.X.Offset, Window.Position.Y.Scale, Window.Position.Y.Offset },
                Size = { Window.AbsoluteSize.X, Window.AbsoluteSize.Y },
                SelectedBase = SETTINGS.SelectedBase,
                SFX = SETTINGS.SFX
            }
            PROFILES[i] = prof
            nameLbl.Text = prof.Name
            persistProfiles()
            showToast(LANG[SETTINGS.Language].toast_saved)
        end)

        btnLoad.MouseButton1Click:Connect(function()
            local prof = PROFILES[i]
            if not prof then showToast(LANG[SETTINGS.Language].empty); return end
            SETTINGS.Theme = prof.Theme or SETTINGS.Theme
            SETTINGS.Language = prof.Language or SETTINGS.Language
            if type(prof.Position) == "table" and #prof.Position >= 4 then Window.Position = UDim2.new(prof.Position[1], prof.Position[2], prof.Position[3], prof.Position[4]) end
            if type(prof.Size) == "table" and #prof.Size >= 2 then Window.Size = UDim2.new(0, math.max(MIN_SIZE.X, prof.Size[1]), 0, math.max(MIN_SIZE.Y, prof.Size[2])) end
            SETTINGS.SelectedBase = prof.SelectedBase or SETTINGS.SelectedBase
            SETTINGS.SFX = (prof.SFX == nil) and SETTINGS.SFX or not not prof.SFX
            applyTheme = applyTheme or function(t) end -- avoid nil issues
            applyTheme(SETTINGS.Theme)
            refreshTexts()
            persistSettings()
            showToast(LANG[SETTINGS.Language].toast_loaded_profile)
        end)

        btnDelete.MouseButton1Click:Connect(function()
            PROFILES[i] = nil
            nameLbl.Text = LANG[SETTINGS.Language].empty
            persistProfiles()
            showToast(LANG[SETTINGS.Language].toast_deleted)
        end)

        btnRename.MouseButton1Click:Connect(function()
            local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,360,0,100); modal.Position = UDim2.new(0.5,-180,0.5,-50); modal.BackgroundColor3 = Color3.fromRGB(18,12,28)
            local mc = Instance.new("UICorner", modal); mc.CornerRadius = UDim.new(0,8)
            local tb = Instance.new("TextBox", modal); tb.Size = UDim2.new(1,-24,0,36); tb.Position = UDim2.new(0,12,0,12); tb.Text = (PROFILES[i] and PROFILES[i].Name) or ("Profile "..i); tb.Font = Enum.Font.Gotham; tb.TextSize = 16
            local ok = Instance.new("TextButton", modal); ok.Size = UDim2.new(0,84,0,32); ok.Position = UDim2.new(1,-96,1,-44); ok.Text = "OK"; local okc = Instance.new("UICorner", ok); okc.CornerRadius = UDim.new(0,6)
            local cancel = Instance.new("TextButton", modal); cancel.Size = UDim2.new(0,84,0,32); cancel.Position = UDim2.new(1,-196,1,-44); cancel.Text = "Cancel"; local canc = Instance.new("UICorner", cancel); canc.CornerRadius = UDim.new(0,6)
            ok.MouseButton1Click:Connect(function()
                local newName = tostring(tb.Text or ""):sub(1,40)
                if not PROFILES[i] then PROFILES[i] = {} end
                PROFILES[i].Name = newName
                nameLbl.Text = newName
                persistProfiles()
                modal:Destroy()
            end)
            cancel.MouseButton1Click:Connect(function() modal:Destroy() end)
        end)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() frame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12) end)
end

-- SETTINGS page (themes grid)
do
    local page = PageFrames["Settings"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.Text = LANG[SETTINGS.Language].tabs[5]; header.TextScaled = true

    local themeLabel = Instance.new("TextLabel", page); themeLabel.Position = UDim2.new(0,12,0,44); themeLabel.Size = UDim2.new(1,-24,0,20); themeLabel.BackgroundTransparency = 1; themeLabel.Font = Enum.Font.Gotham; themeLabel.TextColor3 = Color3.fromRGB(220,220,220); themeLabel.Text = "Themes"; themeLabel.TextScaled = true

    local themeScroll = Instance.new("ScrollingFrame", page); themeScroll.Position = UDim2.new(0,12,0,72); themeScroll.Size = UDim2.new(1,-24,0,116); themeScroll.CanvasSize = UDim2.new(0,0,0,0); themeScroll.ScrollBarThickness = 8; themeScroll.BackgroundTransparency = 1
    local grid = Instance.new("UIGridLayout", themeScroll); grid.CellSize = UDim2.new(0,100,0,48); grid.CellPadding = UDim2.new(0,8,0,8); grid.FillDirection = Enum.FillDirection.Horizontal

    for key, dat in pairs(THEMES) do
        local b = Instance.new("TextButton", themeScroll); b.Size = UDim2.new(0,100,0,48); b.BackgroundColor3 = dat.window; b.Text = dat.symbol; b.Font = Enum.Font.GothamBold; b.TextScaled = true; local tc = Instance.new("UICorner", b); tc.CornerRadius = UDim.new(0,10)
        b.MouseButton1Click:Connect(function()
            SETTINGS.Theme = key
            -- apply theme immediately
            Window.BackgroundColor3 = dat.window
            winStroke.Color = dat.accent
            ToggleBtn.BackgroundColor3 = dat.button
            ToggleBtn.Text = dat.symbol
            persistSettings()
            showToast("Theme: "..key)
        end)
    end

    -- language toggles
    local langLabel = Instance.new("TextLabel", page); langLabel.Position = UDim2.new(0,12,0,200); langLabel.Size = UDim2.new(0,120,0,24); langLabel.BackgroundTransparency = 1; langLabel.Font = Enum.Font.Gotham; langLabel.TextColor3 = Color3.fromRGB(220,220,220); langLabel.Text = "Language"; langLabel.TextScaled = true
    local ru = Instance.new("TextButton", page); ru.Size = UDim2.new(0,48,0,28); ru.Position = UDim2.new(0,140,0,198); ru.Text="🇷🇺"; local ruc = Instance.new("UICorner", ru); ruc.CornerRadius = UDim.new(0,6)
    local en = Instance.new("TextButton", page); en.Size = UDim2.new(0,48,0,28); en.Position = UDim2.new(0,200,0,198); en.Text="🇺🇸"; local enc = Instance.new("UICorner", en); enc.CornerRadius = UDim.new(0,6)
    ru.MouseButton1Click:Connect(function() SETTINGS.Language = "RU"; persistSettings(); refreshTexts(); showToast("Language: RU") end)
    en.MouseButton1Click:Connect(function() SETTINGS.Language = "EN"; persistSettings(); refreshTexts(); showToast("Language: EN") end)

    -- SFX toggle
    local sfxLabel = Instance.new("TextLabel", page); sfxLabel.Position = UDim2.new(0,260,0,198); sfxLabel.Size = UDim2.new(0,60,0,24); sfxLabel.BackgroundTransparency = 1; sfxLabel.Font=Enum.Font.Gotham; sfxLabel.TextColor3=Color3.fromRGB(220,220,220); sfxLabel.Text="SFX"; sfxLabel.TextScaled = true
    local sfxBtn = Instance.new("TextButton", page); sfxBtn.Position = UDim2.new(0,320,0,196); sfxBtn.Size = UDim2.new(0,48,0,28); sfxBtn.Text = (SETTINGS.SFX and "ON" or "OFF")
    sfxBtn.MouseButton1Click:Connect(function() SETTINGS.SFX = not SETTINGS.SFX; sfxBtn.Text = (SETTINGS.SFX and "ON" or "OFF"); persistSettings() end)

    -- export/import left as before (omitted for brevity in UI appearance)
end

-- ========== Drag & Resize (optimized, no movement during resize) ==========
local isResizing = false
local isDragging = false
local dragStart, dragOrigin
local resStartPos, resStartSize

-- Drag (Header & Footer & Toggle hold)
local function beginDrag(input)
    if isResizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    isDragging = true
    dragStart = input.Position
    dragOrigin = Window.Position
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            isDragging = false
            SETTINGS.Position = { Window.Position.X.Scale, Window.Position.X.Offset, Window.Position.Y.Scale, Window.Position.Y.Offset }
            persistSettings()
        end
    end)
end

local function updateDrag(input)
    if not isDragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    Window.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y)
end

Header.InputBegan:Connect(beginDrag)
Footer.InputBegan:Connect(beginDrag)
ToggleBtn.MouseButton1Down:Connect(function(input) beginDrag(input) end)
UserInputService.InputChanged:Connect(updateDrag)

-- Toggle button drag
do
    local draggingBtn = false
    local startPosBtn, originPosBtn
    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        draggingBtn = true
        startPosBtn = input.Position
        originPosBtn = ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingBtn = false end
        end)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not draggingBtn then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startPosBtn
            ToggleBtn.Position = UDim2.new(originPosBtn.X.Scale, originPosBtn.X.Offset + delta.X, originPosBtn.Y.Scale, originPosBtn.Y.Offset + delta.Y)
        end
    end)
end

-- Resizer: change only size, block dragging while resizing
Resizer.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    isResizing = true
    resStartPos = input.Position
    resStartSize = Window.AbsoluteSize
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            isResizing = false
            SETTINGS.Size = { Window.AbsoluteSize.X, Window.AbsoluteSize.Y }
            persistSettings()
        end
    end)
end)

UserInputService.InputChanged:Connect(function(input)
    if not isResizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - resStartPos
    local newW = math.max(MIN_SIZE.X, math.floor(resStartSize.X + delta.X))
    local newH = math.max(MIN_SIZE.Y, math.floor(resStartSize.Y + delta.Y))
    Window.Size = UDim2.new(0, newW, 0, newH)
end)

-- Responsive update debounce (reduce lag)
local resizeDebounce = false
Window:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    if resizeDebounce then return end
    resizeDebounce = true
    task.defer(function()
        -- adjust only dynamic elements if needed; many static labels are TextScaled so no heavy loops
        -- ensure codebox font remains readable by adjusting textsize moderately
        local mainCodeBox = PageFrames["Main"] and PageFrames["Main"]:FindFirstChild("CodeBox")
        if mainCodeBox then
            pcall(function()
                local w = mainCodeBox.AbsoluteSize.X
                mainCodeBox.TextSize = math.clamp(math.floor(w / 55), 12, 18)
            end)
        end
        -- adjust grid cell count for themes: UIGridLayout handles it automatically
        resizeDebounce = false
    end)
end)

-- Open / Close (store size/pos to prevent squish)
local storedSize = Vector2.new(SETTINGS.Size[1], SETTINGS.Size[2])
local storedPos = UDim2.new(SETTINGS.Position[1], SETTINGS.Position[2] or 0, SETTINGS.Position[3], SETTINGS.Position[4] or 0)
local isOpen = true

local function openWindow()
    isOpen = true
    Window.Visible = true
    Window.Position = storedPos
    Window.Size = UDim2.new(0, 18, 0, 18)
    local tween = TweenService:Create(Window, TweenInfo.new(0.28, Enum.EasingStyle.Back), {Size = UDim2.new(0, storedSize.X, 0, storedSize.Y)})
    tween:Play()
end

local function closeWindow()
    isOpen = false
    storedSize = Vector2.new(Window.AbsoluteSize.X, Window.AbsoluteSize.Y)
    storedPos = Window.Position
    SETTINGS.Size = { storedSize.X, storedSize.Y }
    SETTINGS.Position = { storedPos.X.Scale, storedPos.X.Offset, storedPos.Y.Scale, storedPos.Y.Offset }
    persistSettings()
    local tween = TweenService:Create(Window, TweenInfo.new(0.16, Enum.EasingStyle.Sine), {Size = UDim2.new(0,18,0,18)})
    tween:Play()
    tween.Completed:Connect(function()
        Window.Visible = false
        Window.Size = UDim2.new(0, storedSize.X, 0, storedSize.Y)
        Window.Position = storedPos
    end)
end

ToggleBtn.MouseButton1Click:Connect(function()
    if isOpen then closeWindow() else openWindow() end
end)
CloseBtn.MouseButton1Click:Connect(function() closeWindow() end)

-- Initial apply theme & texts
Window.BackgroundColor3 = THEMES[SETTINGS.Theme].window
winStroke.Color = THEMES[SETTINGS.Theme].accent
ToggleBtn.BackgroundColor3 = THEMES[SETTINGS.Theme].button
ToggleBtn.Text = THEMES[SETTINGS.Theme].symbol

local function refreshTexts()
    local lang = SETTINGS.Language or DEFAULT_LANG
    for i,name in ipairs(TAB_ORDER) do
        local btn = TabButtons[name]
        if btn then btn.Text = LANG[lang].tabs[i] or name end
    end
    -- main elements
    local mb = PageFrames["Main"]:FindFirstChild("CodeBox")
    if mb then mb.PlaceholderText = LANG[lang].placeholder end
    local execBtn = PageFrames["Main"]:FindFirstChild("ExecBtn")
    if execBtn then execBtn.Text = LANG[lang].execute end
    local execLabel = PageFrames["Main"]:FindFirstChild("ExecLabel")
    if execLabel then execLabel.Text = string.format(LANG[lang].executor, SETTINGS.SelectedBase) end
end

refreshTexts()

-- Show main page
for k,v in pairs(PageFrames) do v.Visible = false end
PageFrames["Main"].Visible = true
TabButtons["Main"].TextColor3 = Color3.fromRGB(255,255,255)

-- Initial stored values
storedSize = Vector2.new(Window.AbsoluteSize.X, Window.AbsoluteSize.Y)
storedPos = Window.Position

-- Initial toast
showToast(LANG[SETTINGS.Language].toast_loaded or "Fog Hub started")

-- Persist initial
persistSettings(); persistProfiles()

print("[Fog Hub] initialized (responsive). Theme:", SETTINGS.Theme, "Lang:", SETTINGS.Language, "Base:", SETTINGS.SelectedBase)
if not HAS_WRITEFILE then warn("[Fog Hub] writefile not available — persistence will not survive session end.") end

-- End of script
