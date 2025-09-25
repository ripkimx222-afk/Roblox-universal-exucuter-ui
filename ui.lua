--[[ 
  Fog Hub - Universal Executors (fixed)
  By Hikmes0 (assistant fixes)
  Исправления:
    - При открытии/закрытии не "сплющивает" окно — сохраняется реальный размер и позиция.
    - Ресайз изменяет только Size (не двигает окно).
    - Во время ресайза перетаскивание отключено.
    - Toggle-кнопка корректно открывает/скрывает GUI.
    - Все вкладки содержат элементы и работают.
    - Профили/настройки/темы/языки/execute/Infinite Yield и т.д.
--]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- File API detection (exploit-specific)
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

-- Defaults
local THEMES = {
    ["Cyberpunk"] = { window=Color3.fromRGB(8,8,18), accent=Color3.fromRGB(0,200,255), button=Color3.fromRGB(0,200,255), symbol="💠" },
    ["Neon"] = { window=Color3.fromRGB(25,0,40), accent=Color3.fromRGB(255,0,200), button=Color3.fromRGB(255,0,200), symbol="✨" },
    ["Dark Purple"] = { window=Color3.fromRGB(42,18,66), accent=Color3.fromRGB(173,107,255), button=Color3.fromRGB(255,205,0), symbol="⚡" },
    ["Ice Blue"] = { window=Color3.fromRGB(12,20,30), accent=Color3.fromRGB(120,200,255), button=Color3.fromRGB(120,200,255), symbol="❄️" },
    ["Matrix"] = { window=Color3.fromRGB(6,6,6), accent=Color3.fromRGB(0,255,120), button=Color3.fromRGB(0,200,0), symbol="🟢" },
    ["Inferno"] = { window=Color3.fromRGB(30,6,6), accent=Color3.fromRGB(255,80,0), button=Color3.fromRGB(255,140,0), symbol="🔥" },
    ["Pay2Win"] = { window=Color3.fromRGB(12,8,10), accent=Color3.fromRGB(255,210,0), button=Color3.fromRGB(255,200,0), symbol="💰" },
}

local DEFAULT_THEME = "Dark Purple"
local DEFAULT_LANG = "RU"
local DEFAULT_BASE = "KRNL"
local MAX_SLOTS = 3
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
        delay = "Задержка (с)"
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
        delay = "Delay (s)"
    }
}

-- Load persisted settings/profiles (or defaults)
local SETTINGS = {
    Theme = DEFAULT_THEME,
    Language = DEFAULT_LANG,
    Position = {0.2, 0, 0.2, 0}, -- scaleX, offsetX, scaleY, offsetY
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
        SETTINGS.Position = (type(t.Position)=="table" and t.Position) or SETTINGS.Position
        SETTINGS.Size = (type(t.Size)=="table" and t.Size) or SETTINGS.Size
        SETTINGS.SelectedBase = t.SelectedBase or SETTINGS.SelectedBase
        if t.SFX ~= nil then SETTINGS.SFX = not not t.SFX end
    end
    local p = safeRead(PROFILES_FILE)
    local pt = safeDecode(p)
    if type(pt) == "table" then
        for i=1,MAX_SLOTS do PROFILES[i] = pt[i] end
    end
end

local function persistSettings()
    local ok, err = pcall(function()
        local s = safeEncode(SETTINGS)
        if s then safeWrite(SETTINGS_FILE, s) end
    end)
    if not ok then warn("Failed persist settings:", err) end
end
local function persistProfiles()
    local ok, err = pcall(function()
        local s = safeEncode(PROFILES)
        if s then safeWrite(PROFILES_FILE, s) end
    end)
    if not ok then warn("Failed persist profiles:", err) end
end

-- EXECUTORS table (common ones, with fallbacks)
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

-- ---------- Build GUI ----------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FogHubGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- SFX folder (optional)
local SFX = Instance.new("Folder", screenGui)
SFX.Name = "FogSFX"
local function createSound(id, name)
    if not id then return end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = 0.8
    s.Name = name
    s.Parent = SFX
    return s
end

-- Main Window
local Window = Instance.new("Frame", screenGui)
Window.Name = "Window"
Window.Size = UDim2.new(0, SETTINGS.Size[1], 0, SETTINGS.Size[2])
Window.Position = UDim2.new(SETTINGS.Position[1], SETTINGS.Position[2] or 0, SETTINGS.Position[3], SETTINGS.Position[4] or 0)
Window.BackgroundColor3 = THEMES[SETTINGS.Theme].window
Window.ClipsDescendants = true
Window.Active = true
local winCorner = Instance.new("UICorner", Window); winCorner.CornerRadius = UDim.new(0,10)
local winStroke = Instance.new("UIStroke", Window); winStroke.Color = THEMES[SETTINGS.Theme].accent; winStroke.Thickness = 1; winStroke.Transparency = 0.35

-- Header (title, subtitle, X)
local Header = Instance.new("Frame", Window); Header.Size = UDim2.new(1,0,0,52); Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header); Title.Position = UDim2.new(0,12,0,6); Title.Size = UDim2.new(0.6,0,0,28); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.TextSize = 20; Title.TextColor3 = Color3.new(1,1,1); Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Text = "Fog Hub"
local Subtitle = Instance.new("TextLabel", Header); Subtitle.Position = UDim2.new(0,12,0,30); Subtitle.Size = UDim2.new(0.6,0,0,16); Subtitle.BackgroundTransparency = 1; Subtitle.Font = Enum.Font.Gotham; Subtitle.TextSize = 12; Subtitle.TextColor3 = Color3.fromRGB(200,200,200); Subtitle.Text = "Universal Executors"
local CloseBtn = Instance.new("TextButton", Header); CloseBtn.Size = UDim2.new(0,36,0,28); CloseBtn.Position = UDim2.new(1,-48,0,10); CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 18; CloseBtn.BackgroundTransparency = 0.4
local closeCorner = Instance.new("UICorner", CloseBtn); closeCorner.CornerRadius = UDim.new(0,6)

-- Footer
local Footer = Instance.new("Frame", Window); Footer.Size = UDim2.new(1,0,0,24); Footer.Position = UDim2.new(0,0,1,-24); Footer.BackgroundTransparency = 1
local FooterText = Instance.new("TextLabel", Footer); FooterText.Position = UDim2.new(0,12,0,2); FooterText.Size = UDim2.new(1,-24,1,-4); FooterText.BackgroundTransparency = 1; FooterText.Font = Enum.Font.Gotham; FooterText.TextSize = 12; FooterText.TextColor3 = Color3.fromRGB(255,255,255); FooterText.TextTransparency = 0.5; FooterText.Text = "By Hikmes0"

-- Left tabs
local TabsCol = Instance.new("Frame", Window); TabsCol.Size = UDim2.new(0,160,1,-88); TabsCol.Position = UDim2.new(0,12,0,60); TabsCol.BackgroundTransparency = 1
local TabsBg = Instance.new("Frame", TabsCol); TabsBg.Size = UDim2.new(1,0,1,0); TabsBg.BackgroundColor3 = Color3.fromRGB(18,10,28); local tabsCorner = Instance.new("UICorner", TabsBg); tabsCorner.CornerRadius = UDim.new(0,10)
local TabsLayout = Instance.new("UIListLayout", TabsBg); TabsLayout.Padding = UDim.new(0,8); TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Content area
local Content = Instance.new("Frame", Window); Content.Size = UDim2.new(1,-188,1,-88); Content.Position = UDim2.new(0,180,0,60); Content.BackgroundTransparency = 1
local Pages = Instance.new("Folder", Content); Pages.Name = "Pages"

-- Resizer bottom-right
local Resizer = Instance.new("Frame", Window); Resizer.Size = UDim2.new(0,14,0,14); Resizer.Position = UDim2.new(1,-18,1,-18); Resizer.BackgroundColor3 = Color3.fromRGB(255,255,255); local resCorner = Instance.new("UICorner", Resizer); resCorner.CornerRadius = UDim.new(0,3)

-- Toggle circular button (movable)
local ToggleBtn = Instance.new("TextButton", screenGui); ToggleBtn.Size = UDim2.new(0,64,0,64); ToggleBtn.Position = UDim2.new(0,12,0.6,-32); ToggleBtn.AnchorPoint = Vector2.new(0,0.5); ToggleBtn.AutoButtonColor = false
ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.TextSize = 28; ToggleBtn.Text = THEMES[SETTINGS.Theme].symbol; ToggleBtn.BackgroundColor3 = THEMES[SETTINGS.Theme].button
local toggleCorner = Instance.new("UICorner", ToggleBtn); toggleCorner.CornerRadius = UDim.new(1,0)

-- Tab creation
local TAB_ORDER = {"Main","Base","Universal","Profiles","Settings"}
local TabButtons = {}
local PageFrames = {}

local function createTab(name)
    local btn = Instance.new("TextButton", TabsBg)
    btn.Size = UDim2.new(1,-16,0,40)
    btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Text = name
    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0,8)
    local page = Instance.new("Frame", Pages); page.Size = UDim2.new(1,0,1,0); page.BackgroundTransparency = 1; page.Visible = false

    TabButtons[name] = btn
    PageFrames[name] = page

    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {TextColor3 = THEMES[SETTINGS.Theme].accent}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(220,220,220)}):Play() end)
    btn.MouseButton1Click:Connect(function()
        for k,v in pairs(PageFrames) do v.Visible = false end
        page.Visible = true
        for _,b in pairs(TabButtons) do b.TextColor3 = Color3.fromRGB(200,200,200) end
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        showToast("Открыта вкладка: "..name)
    end)
    return btn, page
end

for _,n in ipairs(TAB_ORDER) do createTab(n) end

-- ---------- Helper functions ----------
-- localized text getter
local function loc(key)
    local lang = SETTINGS.Language or DEFAULT_LANG
    return LANG[lang][key] or LANG[DEFAULT_LANG][key] or key
end

-- toast
function showToast(text)
    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0,260,0,44)
    frame.Position = UDim2.new(1,-280,1,-60)
    frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    frame.ZIndex = 1000
    local c = Instance.new("UICorner", frame); c.CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,-12,1,-12)
    label.Position = UDim2.new(0,6,0,6)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text

    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Position = UDim2.new(1,-280,1,-120)}):Play()
    task.delay(3, function()
        TweenService:Create(label, TweenInfo.new(0.28), {TextTransparency = 1}):Play()
        TweenService:Create(frame, TweenInfo.new(0.28), {BackgroundTransparency = 1}):Play()
        task.delay(0.35, function() pcall(function() frame:Destroy() end) end)
    end)
end

-- Apply theme
local function applyTheme(themeName)
    local theme = THEMES[themeName] or THEMES[DEFAULT_THEME]
    Window.BackgroundColor3 = theme.window
    winStroke.Color = theme.accent
    ToggleBtn.BackgroundColor3 = theme.button
    ToggleBtn.Text = theme.symbol
    -- exec button accent update later if exists
end

-- Refresh language-dependent texts
local function refreshTexts()
    local lang = SETTINGS.Language or DEFAULT_LANG
    for i,name in ipairs(TAB_ORDER) do
        local btn = TabButtons[name]
        if btn then
            btn.Text = LANG[lang].tabs[i] or name
        end
    end
    -- main placeholders and execute button
    local codeBox = PageFrames["Main"]:FindFirstChild("CodeBox")
    if codeBox then codeBox.PlaceholderText = LANG[SETTINGS.Language].placeholder end
    local execBtn = PageFrames["Main"]:FindFirstChild("ExecBtn")
    if execBtn then execBtn.Text = LANG[SETTINGS.Language].execute end
    local execLabel = PageFrames["Main"]:FindFirstChild("ExecLabel")
    if execLabel then execLabel.Text = string.format(LANG[SETTINGS.Language].executor, SETTINGS.SelectedBase) end

    -- profiles names
    local idx = 1
    for _,frame in ipairs(PageFrames["Profiles"]:GetChildren()) do
        if frame:IsA("Frame") then
            local label = frame:FindFirstChildWhichIsA("TextLabel")
            if label then
                label.Text = (PROFILES[idx] and PROFILES[idx].Name) or LANG[SETTINGS.Language].empty or "Empty"
            end
            idx = idx + 1
            if idx > MAX_SLOTS then break end
        end
    end
end

-- ---------- Create page contents ----------

-- MAIN
do
    local page = PageFrames["Main"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = loc("tabs")[1] or "Main"

    local execLabel = Instance.new("TextLabel", page); execLabel.Name = "ExecLabel"; execLabel.Size = UDim2.new(1,-24,0,20); execLabel.Position = UDim2.new(0,12,0,36); execLabel.BackgroundTransparency = 1; execLabel.Font = Enum.Font.Gotham; execLabel.TextSize = 14; execLabel.TextColor3 = Color3.fromRGB(210,210,210)
    execLabel.Text = string.format(LANG[SETTINGS.Language].executor, SETTINGS.SelectedBase)

    local codeBox = Instance.new("TextBox", page); codeBox.Name = "CodeBox"; codeBox.Position = UDim2.new(0,12,0,66); codeBox.Size = UDim2.new(1,-24,0.62,-66); codeBox.BackgroundColor3 = Color3.fromRGB(28,14,40); codeBox.TextColor3 = Color3.fromRGB(240,240,240); codeBox.Font = Enum.Font.Code; codeBox.TextSize = 14; codeBox.TextWrapped = true; codeBox.MultiLine = true; codeBox.ClearTextOnFocus = false; codeBox.PlaceholderText = LANG[SETTINGS.Language].placeholder
    local cbCorner = Instance.new("UICorner", codeBox); cbCorner.CornerRadius = UDim.new(0,8)

    -- utilities
    local clearBtn = Instance.new("TextButton", page); clearBtn.Size = UDim2.new(0,84,0,32); clearBtn.Position = UDim2.new(0,12,1,-44); clearBtn.Text = LANG[SETTINGS.Language].clear; local cCor = Instance.new("UICorner", clearBtn); cCor.CornerRadius = UDim.new(0,6)
    local beautBtn = Instance.new("TextButton", page); beautBtn.Size = UDim2.new(0,84,0,32); beautBtn.Position = UDim2.new(0,108,1,-44); beautBtn.Text = LANG[SETTINGS.Language].beautify; local bCor = Instance.new("UICorner", beautBtn); bCor.CornerRadius = UDim.new(0,6)
    local delayLbl = Instance.new("TextLabel", page); delayLbl.Position = UDim2.new(1,-340,1,-40); delayLbl.Size = UDim2.new(0,120,0,24); delayLbl.BackgroundTransparency = 1; delayLbl.Font = Enum.Font.Gotham; delayLbl.TextColor3 = Color3.fromRGB(220,220,220); delayLbl.Text = LANG[SETTINGS.Language].delay or "Delay (s)"
    local delayBox = Instance.new("TextBox", page); delayBox.Size = UDim2.new(0,84,0,32); delayBox.Position = UDim2.new(1,-220,1,-44); delayBox.PlaceholderText = "0"; delayBox.Font = Enum.Font.Gotham; local dbCorner = Instance.new("UICorner", delayBox); dbCorner.CornerRadius = UDim.new(0,6)

    local execBtn = Instance.new("TextButton", page); execBtn.Name = "ExecBtn"; execBtn.Size = UDim2.new(0,140,0,40); execBtn.Position = UDim2.new(0.5,-70,0.86,0); execBtn.AnchorPoint = Vector2.new(0.5,0); execBtn.Font = Enum.Font.GothamBold; execBtn.TextSize = 16; execBtn.Text = LANG[SETTINGS.Language].execute; execBtn.BackgroundColor3 = THEMES[SETTINGS.Theme].accent; execBtn.TextColor3 = Color3.fromRGB(255,255,255); local ebCorner = Instance.new("UICorner", execBtn); ebCorner.CornerRadius = UDim.new(0,8)

    -- quick preset
    local preset1 = Instance.new("TextButton", page); preset1.Size = UDim2.new(0,120,0,28); preset1.Position = UDim2.new(0,160,0.72,0); preset1.Text = "print('Hi')"; local p1c = Instance.new("UICorner", preset1); p1c.CornerRadius = UDim.new(0,6)
    preset1.MouseButton1Click:Connect(function() codeBox.Text = "print('Hello from Fog Hub')\n" end)

    -- beautify rudimentary
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

    -- execute with optional delay
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

-- BASE
do
    local page = PageFrames["Base"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = loc("tabs")[2]
    local scroll = Instance.new("ScrollingFrame", page); scroll.Position = UDim2.new(0,12,0,44); scroll.Size = UDim2.new(1,-24,1,-56); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 8
    local layout = Instance.new("UIListLayout", scroll); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,8)
    for i,b in ipairs(BASES) do
        local btn = Instance.new("TextButton", scroll); btn.Size = UDim2.new(1,-12,0,40); btn.Position = UDim2.new(0,6,0,(i-1)*48); btn.BackgroundColor3 = Color3.fromRGB(28,12,36); btn.Font = Enum.Font.Gotham; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(235,235,235); btn.Text = b
        local bc = Instance.new("UICorner", btn); bc.CornerRadius = UDim.new(0,8)
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
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12) end)

    -- Test executor button
    local testBtn = Instance.new("TextButton", page); testBtn.Size = UDim2.new(0.4,0,0,32); testBtn.Position = UDim2.new(0.55,0,0,6); testBtn.Text = "Test Executor"; local tc = Instance.new("UICorner", testBtn); tc.CornerRadius = UDim.new(0,6)
    testBtn.MouseButton1Click:Connect(function()
        local base = SETTINGS.SelectedBase or DEFAULT_BASE
        local fn = EXECUTORS[base]
        local ok, res = false, nil
        if type(fn) == "function" then ok, res = pcall(function() return fn("print('FogHub test')") end) end
        if ok and res ~= false then showToast("Executor "..base.." appears available") else showToast("Executor "..base.." unavailable") end
    end)
end

-- UNIVERSAL
do
    local page = PageFrames["Universal"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = loc("tabs")[3]
    local infBtn = Instance.new("TextButton", page); infBtn.Size = UDim2.new(0.46,0,0,40); infBtn.Position = UDim2.new(0.27,0,0.18,0); infBtn.Text = loc("infinite"); infBtn.Font = Enum.Font.GothamBold; infBtn.TextSize = 16; infBtn.BackgroundColor3 = Color3.fromRGB(0,120,200); local ic = Instance.new("UICorner", infBtn); ic.CornerRadius = UDim.new(0,8)
    infBtn.MouseButton1Click:Connect(function()
        local ok, err = pcall(function()
            local src = game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
            loadstring(src)()
        end)
        if ok then showToast("Infinite Yield started") else showToast("Error: "..tostring(err)) end
    end)

    local copyBtn = Instance.new("TextButton", page); copyBtn.Size = UDim2.new(0.46,0,0,28); copyBtn.Position = UDim2.new(0.27,0,0.32,0); copyBtn.Text = "Copy raw link"; local cc = Instance.new("UICorner", copyBtn); cc.CornerRadius = UDim.new(0,6)
    copyBtn.MouseButton1Click:Connect(function()
        local link = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
        local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,520,0,120); modal.Position = UDim2.new(0.5,-260,0.5,-60); modal.BackgroundColor3 = Color3.fromRGB(18,12,28)
        local rc = Instance.new("UICorner", modal); rc.CornerRadius = UDim.new(0,8)
        local tb = Instance.new("TextBox", modal); tb.Size = UDim2.new(1,-24,0,60); tb.Position = UDim2.new(0,12,0,12); tb.Text = link; tb.Font = Enum.Font.Code; tb.TextSize=14
        local ok = Instance.new("TextButton", modal); ok.Size = UDim2.new(0,84,0,36); ok.Position = UDim2.new(1,-96,1,-44); ok.Text = "OK"; local okc = Instance.new("UICorner", ok); okc.CornerRadius = UDim.new(0,8)
        ok.MouseButton1Click:Connect(function() modal:Destroy() end)
    end)
end

-- PROFILES
do
    local page = PageFrames["Profiles"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = loc("tabs")[4]
    local frame = Instance.new("Frame", page); frame.Position = UDim2.new(0,12,0,44); frame.Size = UDim2.new(1,-24,1,-56); frame.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", frame); layout.Padding = UDim.new(0,8)

    for i=1,MAX_SLOTS do
        local slot = Instance.new("Frame", frame); slot.Size = UDim2.new(1,0,0,84); slot.BackgroundColor3 = Color3.fromRGB(24,10,30); local sc = Instance.new("UICorner", slot); sc.CornerRadius = UDim.new(0,8)
        local nameLbl = Instance.new("TextLabel", slot); nameLbl.Position = UDim2.new(0,12,0,8); nameLbl.Size = UDim2.new(0.5,-24,0,24); nameLbl.BackgroundTransparency = 1; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 16; nameLbl.TextColor3 = Color3.fromRGB(235,235,235)
        nameLbl.Text = (PROFILES[i] and PROFILES[i].Name) or "Empty"

        local btnRename = Instance.new("TextButton", slot); btnRename.Size = UDim2.new(0,84,0,28); btnRename.Position = UDim2.new(1,-96,0,8); btnRename.Text = "Rename"; local ruc = Instance.new("UICorner", btnRename); ruc.CornerRadius = UDim.new(0,6)
        local btnSave = Instance.new("TextButton", slot); btnSave.Size = UDim2.new(0,84,0,28); btnSave.Position = UDim2.new(1,-96,0,44); btnSave.Text = "Save"; local sc2 = Instance.new("UICorner", btnSave); sc2.CornerRadius = UDim.new(0,6)
        local btnLoad = Instance.new("TextButton", slot); btnLoad.Size = UDim2.new(0,84,0,28); btnLoad.Position = UDim2.new(1,-186,0,44); btnLoad.Text = "Load"; local lc = Instance.new("UICorner", btnLoad); lc.CornerRadius = UDim.new(0,6)
        local btnDelete = Instance.new("TextButton", slot); btnDelete.Size = UDim2.new(0,84,0,28); btnDelete.Position = UDim2.new(1,-276,0,44); btnDelete.Text = "Delete"; local dc = Instance.new("UICorner", btnDelete); dc.CornerRadius = UDim.new(0,6)

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
            if not prof then showToast("Empty") return end
            SETTINGS.Theme = prof.Theme or SETTINGS.Theme
            SETTINGS.Language = prof.Language or SETTINGS.Language
            if type(prof.Position)=="table" and #prof.Position>=4 then Window.Position = UDim2.new(prof.Position[1], prof.Position[2], prof.Position[3], prof.Position[4]) end
            if type(prof.Size)=="table" and #prof.Size>=2 then Window.Size = UDim2.new(0, math.max(MIN_SIZE.X, prof.Size[1]), 0, math.max(MIN_SIZE.Y, prof.Size[2])) end
            SETTINGS.SelectedBase = prof.SelectedBase or SETTINGS.SelectedBase
            SETTINGS.SFX = (prof.SFX == nil) and SETTINGS.SFX or not not prof.SFX
            applyTheme(SETTINGS.Theme)
            refreshTexts()
            persistSettings()
            showToast(LANG[SETTINGS.Language].toast_loaded_profile)
        end)

        btnDelete.MouseButton1Click:Connect(function()
            PROFILES[i] = nil
            nameLbl.Text = "Empty"
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

-- SETTINGS
do
    local page = PageFrames["Settings"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = loc("tabs")[5]

    local themeLabel = Instance.new("TextLabel", page); themeLabel.Position = UDim2.new(0,12,0,44); themeLabel.Size = UDim2.new(1,-24,0,20); themeLabel.BackgroundTransparency = 1; themeLabel.Font = Enum.Font.Gotham; themeLabel.TextColor3 = Color3.fromRGB(220,220,220); themeLabel.Text = "Themes"
    local themeFrame = Instance.new("Frame", page); themeFrame.Position = UDim2.new(0,12,0,70); themeFrame.Size = UDim2.new(1,-24,0,64); themeFrame.BackgroundTransparency = 1

    local idx = 0
    for key, dat in pairs(THEMES) do
        idx = idx + 1
        local b = Instance.new("TextButton", themeFrame); b.Size = UDim2.new(0,100,0,48); b.Position = UDim2.new(0,(idx-1)*104,0,8); b.BackgroundColor3 = dat.window; b.Text = dat.symbol; b.Font = Enum.Font.GothamBold; b.TextSize = 22; b.TextColor3 = Color3.fromRGB(240,240,240); local tc = Instance.new("UICorner", b); tc.CornerRadius = UDim.new(0,10)
        b.MouseButton1Click:Connect(function()
            SETTINGS.Theme = key
            applyTheme(key)
            persistSettings()
            showToast("Theme: "..key)
        end)
    end

    -- language
    local langLabel = Instance.new("TextLabel", page); langLabel.Position = UDim2.new(0,12,0,150); langLabel.Size = UDim2.new(0,120,0,24); langLabel.BackgroundTransparency = 1; langLabel.Font = Enum.Font.Gotham; langLabel.TextColor3 = Color3.fromRGB(220,220,220); langLabel.Text = "Language"
    local ru = Instance.new("TextButton", page); ru.Size = UDim2.new(0,48,0,28); ru.Position = UDim2.new(0,140,0,148); ru.Text="🇷🇺"
    local en = Instance.new("TextButton", page); en.Size = UDim2.new(0,48,0,28); en.Position = UDim2.new(0,200,0,148); en.Text="🇺🇸"
    ru.MouseButton1Click:Connect(function() SETTINGS.Language = "RU"; persistSettings(); refreshTexts(); showToast("Language: RU") end)
    en.MouseButton1Click:Connect(function() SETTINGS.Language = "EN"; persistSettings(); refreshTexts(); showToast("Language: EN") end)

    -- sfx toggle
    local sfxLabel = Instance.new("TextLabel", page); sfxLabel.Position = UDim2.new(0,260,0,150); sfxLabel.Size = UDim2.new(0,60,0,24); sfxLabel.BackgroundTransparency = 1; sfxLabel.Font=Enum.Font.Gotham; sfxLabel.TextColor3=Color3.fromRGB(220,220,220); sfxLabel.Text="SFX"
    local sfxBtn = Instance.new("TextButton", page); sfxBtn.Position = UDim2.new(0,320,0,148); sfxBtn.Size = UDim2.new(0,48,0,28); sfxBtn.Text = (SETTINGS.SFX and "ON" or "OFF")
    sfxBtn.MouseButton1Click:Connect(function() SETTINGS.SFX = not SETTINGS.SFX; sfxBtn.Text = (SETTINGS.SFX and "ON" or "OFF"); persistSettings() end)

    -- Export/Import buttons for profiles
    local exportBtn = Instance.new("TextButton", page); exportBtn.Size = UDim2.new(0,100,0,30); exportBtn.Position = UDim2.new(1,-236,1,-44); exportBtn.AnchorPoint = Vector2.new(0,1); exportBtn.Text = "Export"
    local importBtn = Instance.new("TextButton", page); importBtn.Size = UDim2.new(0,100,0,30); importBtn.Position = UDim2.new(1,-120,1,-44); importBtn.AnchorPoint = Vector2.new(0,1); importBtn.Text = "Import"
    exportBtn.MouseButton1Click:Connect(function()
        local s = safeEncode(PROFILES)
        if s then
            local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,540,0,220); modal.Position = UDim2.new(0.5,-270,0.5,-110); modal.BackgroundColor3 = Color3.fromRGB(18,12,28)
            local mc = Instance.new("UICorner", modal); mc.CornerRadius = UDim.new(0,8)
            local tb = Instance.new("TextBox", modal); tb.Size = UDim2.new(1,-24,1,-64); tb.Position = UDim2.new(0,12,0,12); tb.Text = s; tb.MultiLine = true; tb.Font = Enum.Font.Code; tb.TextSize = 14
            local ok = Instance.new("TextButton", modal); ok.Size = UDim2.new(0,84,0,36); ok.Position = UDim2.new(1,-96,1,-44); ok.Text = "OK"; local okc = Instance.new("UICorner", ok); okc.CornerRadius = UDim.new(0,8)
            ok.MouseButton1Click:Connect(function() modal:Destroy() end)
        else
            showToast("Export error")
        end
    end)
    importBtn.MouseButton1Click:Connect(function()
        local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,540,0,220); modal.Position = UDim2.new(0.5,-270,0.5,-110); modal.BackgroundColor3 = Color3.fromRGB(18,12,28)
        local mc = Instance.new("UICorner", modal); mc.CornerRadius = UDim.new(0,8)
        local tb = Instance.new("TextBox", modal); tb.Size = UDim2.new(1,-24,1,-64); tb.Position = UDim2.new(0,12,0,12); tb.PlaceholderText = "Paste profiles JSON here"; tb.MultiLine = true; tb.Font = Enum.Font.Code; tb.TextSize = 14
        local ok = Instance.new("TextButton", modal); ok.Size = UDim2.new(0,84,0,36); ok.Position = UDim2.new(1,-96,1,-44); ok.Text = "Import"; local okc = Instance.new("UICorner", ok); okc.CornerRadius = UDim.new(0,8)
        local cancel = Instance.new("TextButton", modal); cancel.Size = UDim2.new(0,84,0,36); cancel.Position = UDim2.new(1,-196,1,-44); cancel.Text = "Cancel"; local cc = Instance.new("UICorner", cancel); cc.CornerRadius = UDim.new(0,8)
        ok.MouseButton1Click:Connect(function()
            local t = safeDecode(tb.Text)
            if type(t) == "table" then
                for i=1,MAX_SLOTS do PROFILES[i] = t[i] end
                persistProfiles()
                refreshTexts()
                showToast("Profiles imported")
                modal:Destroy()
            else
                showToast("Import error")
            end
        end)
        cancel.MouseButton1Click:Connect(function() modal:Destroy() end)
    end)
end

-- ---------- Drag & Resize behavior ----------

local isResizing = false
local isDragging = false
local dragStartPos, dragOrigin
local resStartPos, resStartSize

-- Drag begin (header/footer/toggle)
local function beginDrag(input)
    if isResizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    isDragging = true
    dragStartPos = input.Position
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
    local delta = input.Position - dragStartPos
    Window.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y)
end

Header.InputBegan:Connect(beginDrag)
Footer.InputBegan:Connect(beginDrag)
ToggleBtn.MouseButton1Down:Connect(function(input) beginDrag(input) end)
UserInputService.InputChanged:Connect(updateDrag)

-- ToggleBtn movable (drag itself)
do
    local draggingBtn, btnStart, btnOrigin = false, nil, nil
    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        draggingBtn = true
        btnStart = input.Position
        btnOrigin = ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingBtn = false end
        end)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not draggingBtn then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - btnStart
            ToggleBtn.Position = UDim2.new(btnOrigin.X.Scale, btnOrigin.X.Offset + delta.X, btnOrigin.Y.Scale, btnOrigin.Y.Offset + delta.Y)
        end
    end)
end

-- Resize: change only Size, block dragging while resizing
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

-- Update visuals on size change (responsive)
Window:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    SETTINGS.Size = { Window.AbsoluteSize.X, Window.AbsoluteSize.Y }
    -- adjust text sizes slightly
    for _,obj in pairs(Window:GetDescendants()) do
        if obj:IsA("TextLabel") and not obj.TextScaled then
            pcall(function()
                local sz = math.clamp(math.floor(Window.AbsoluteSize.X/60), 12, 20)
                obj.TextSize = sz
            end)
        elseif obj:IsA("TextButton") and not obj.TextScaled then
            pcall(function()
                local sz = math.clamp(math.floor(Window.AbsoluteSize.X/80), 12, 18)
                obj.TextSize = sz
            end)
        elseif obj:IsA("TextBox") and not obj.TextScaled then
            pcall(function()
                local sz = math.clamp(math.floor(Window.AbsoluteSize.X/60), 12, 18)
                obj.TextSize = sz
            end)
        end
    end
    persistSettings()
end)

-- ---------- Open/Close behavior (preserve size & pos) ----------
local storedSize = Vector2.new(SETTINGS.Size[1], SETTINGS.Size[2])
local storedPosition = UDim2.new(SETTINGS.Position[1], SETTINGS.Position[2] or 0, SETTINGS.Position[3], SETTINGS.Position[4] or 0)
local isOpen = true

local function openWindow()
    isOpen = true
    Window.Visible = true
    -- ensure position is storedPosition
    Window.Position = storedPosition
    -- animate from small to storedSize
    Window.Size = UDim2.new(0, 18, 0, 18)
    local tween = TweenService:Create(Window, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, storedSize.X, 0, storedSize.Y)})
    tween:Play()
    if SETTINGS.SFX then pcall(function() local s=SFX:FindFirstChild("open"); if s then s:Play() end end) end
end

local function closeWindow()
    isOpen = false
    -- store current size & pos
    storedSize = Vector2.new(Window.AbsoluteSize.X, Window.AbsoluteSize.Y)
    storedPosition = Window.Position
    SETTINGS.Size = { storedSize.X, storedSize.Y }
    SETTINGS.Position = { storedPosition.X.Scale, storedPosition.X.Offset, storedPosition.Y.Scale, storedPosition.Y.Offset }
    persistSettings()
    -- animate to small size and hide
    local tween = TweenService:Create(Window, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Size = UDim2.new(0,18,0,18)})
    tween:Play()
    tween.Completed:Connect(function()
        Window.Visible = false
        -- restore saved size invisibly for next open
        Window.Size = UDim2.new(0, storedSize.X, 0, storedSize.Y)
        Window.Position = storedPosition
    end)
    if SETTINGS.SFX then pcall(function() local s=SFX:FindFirstChild("close"); if s then s:Play() end end) end
end

ToggleBtn.MouseButton1Click:Connect(function()
    if isOpen then closeWindow() else openWindow() end
end)
CloseBtn.MouseButton1Click:Connect(function() closeWindow() end)

-- ---------- Final init ----------
applyTheme(SETTINGS.Theme)
refreshTexts()

-- Show Main page by default
for name, page in pairs(PageFrames) do page.Visible = false end
PageFrames["Main"].Visible = true
TabButtons["Main"].TextColor3 = Color3.fromRGB(255,255,255)

-- initial stored values
storedSize = Vector2.new(Window.AbsoluteSize.X, Window.AbsoluteSize.Y)
storedPosition = Window.Position

-- initial toast
showToast(LANG[SETTINGS.Language].toast_loaded or "Fog Hub started")

-- persist initially
persistSettings()
persistProfiles()

-- Print quick status
print("[Fog Hub] initialized. Theme:", SETTINGS.Theme, "Lang:", SETTINGS.Language, "Base:", SETTINGS.SelectedBase)
if not HAS_WRITEFILE then warn("[Fog Hub] writefile not available — persistence will not survive session end.") end

-- End of script
