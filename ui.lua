--[[ Fog Hub - Universal Executors
     By Hikmes0
     Полный LocalScript: UI + Themes + Profiles + Execute + Universal (Infinite Yield) + Toasts + SFX + Drag/Resize/Animations
     Требует (опционально) exploit API: writefile/readfile/isfile/delfile
--]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local parentGui = player:WaitForChild("PlayerGui")

-- Detect file API
local HAS_WRITEFILE = type(writefile) == "function"
local HAS_READFILE  = type(readfile) == "function"
local HAS_ISFILE    = type(isfile) == "function"
local HAS_DELFILE   = type(delfile) == "function"

-- Files
local PROFILES_FILE = "FogHub_Profiles.json"
local SETTINGS_FILE = "FogHub_Settings.json"

-- Utils: safe encode/decode
local function safeEncode(tbl)
    local ok,res = pcall(function() return HttpService:JSONEncode(tbl) end)
    if ok then return res end
    return nil
end
local function safeDecode(str)
    if type(str) ~= "string" then return nil end
    local ok,res = pcall(function() return HttpService:JSONDecode(str) end)
    if ok then return res end
    return nil
end

-- File wrappers with fallback
local volatileProfiles = {nil,nil,nil}
local volatileSettings = nil

local function fileExists(name)
    if HAS_ISFILE then
        local ok, res = pcall(isfile, name)
        if ok then return res end
    end
    return false
end
local function fileRead(name)
    if HAS_READFILE then
        local ok, res = pcall(readfile, name)
        if ok then return res end
    end
    return nil
end
local function fileWrite(name, content)
    if HAS_WRITEFILE then
        local ok, err = pcall(function() writefile(name, content) end)
        if ok then return true else return false, err end
    else
        return false, "no_writefile"
    end
end
local function fileDelete(name)
    if HAS_DELFILE then pcall(delfile, name) end
end

-- Default configuration
local THEMES = {
    Default = { name="Default", window=Color3.fromRGB(42,18,66), accent=Color3.fromRGB(173,107,255), button=Color3.fromRGB(255,205,0), symbol="⚡", sfx={open="rbxassetid://12221976", close="rbxassetid://9083627113", click="rbxassetid://4307186075"} },
    Cyberpunk = { name="Cyberpunk", window=Color3.fromRGB(8,8,18), accent=Color3.fromRGB(0,200,255), button=Color3.fromRGB(0,200,255), symbol="💠", sfx={open="rbxassetid://9083627113", close="rbxassetid://12221976", click="rbxassetid://4307186075"} },
    Neon = { name="Neon", window=Color3.fromRGB(25,0,40), accent=Color3.fromRGB(255,0,200), button=Color3.fromRGB(255,0,200), symbol="✨", sfx={open="rbxassetid://12221976", close="rbxassetid://4307186075", click="rbxassetid://408524543"} },
    Matrix = { name="Matrix", window=Color3.fromRGB(6,6,6), accent=Color3.fromRGB(0,255,120), button=Color3.fromRGB(0,200,0), symbol="🟢", sfx={open="rbxassetid://12221976", close="rbxassetid://9083627113", click="rbxassetid://4307186075"} },
    Inferno = { name="Inferno", window=Color3.fromRGB(30,6,6), accent=Color3.fromRGB(255,80,0), button=Color3.fromRGB(255,140,0), symbol="🔥", sfx={open="rbxassetid://9083627113", close="rbxassetid://12221976", click="rbxassetid://4307186075"} },
    Crystal = { name="Crystal", window=Color3.fromRGB(38,6,66), accent=Color3.fromRGB(150,255,255), button=Color3.fromRGB(170,120,255), symbol="💎", sfx={open="rbxassetid://9083627113", close="rbxassetid://12221976", click="rbxassetid://4307186075"} },
    Pay2Win = { name="Pay2Win", window=Color3.fromRGB(12,8,10), accent=Color3.fromRGB(255,210,0), button=Color3.fromRGB(255,200,0), symbol="💰", sfx={open="rbxassetid://138129320", close="rbxassetid://9083627113", click="rbxassetid://4307186075"} },
}

local DEFAULT_THEME = "Default"
local DEFAULT_LANG = "RU"
local DEFAULT_BASE = "KRNL"
local MAX_SLOTS = 3
local MIN_SIZE = Vector2.new(360,220) -- smaller height, wider width later set

-- Localization
local L = {
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
        save_settings = "Сохранить настройки",
        export = "Экспорт",
        import = "Импорт",
        rename = "Переименовать",
        delete = "Удалить",
        load = "Загрузить",
        save = "Сохранить",
        empty = "Пусто",
        close = "Закрыть",
        open = "Открыть",
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
        save_settings = "Save settings",
        export = "Export",
        import = "Import",
        rename = "Rename",
        delete = "Delete",
        load = "Load",
        save = "Save",
        empty = "Empty",
        close = "Close",
        open = "Open",
    }
}

-- Load or init settings & profiles
local SETTINGS = {
    Theme = DEFAULT_THEME,
    Language = DEFAULT_LANG,
    Position = {0.2,0,0.2,0},
    Size = {820, 360}, -- wider, less height
    SelectedBase = DEFAULT_BASE,
    SFX = true
}
local PROFILES = { nil, nil, nil }

do
    local s = fileRead(SETTINGS_FILE)
    local t = safeDecode(s)
    if type(t) == "table" then
        SETTINGS.Theme = t.Theme or SETTINGS.Theme
        SETTINGS.Language = t.Language or SETTINGS.Language
        if type(t.Position) == "table" and #t.Position >= 4 then SETTINGS.Position = t.Position end
        if type(t.Size) == "table" and #t.Size >= 2 then SETTINGS.Size = t.Size end
        SETTINGS.SelectedBase = t.SelectedBase or SETTINGS.SelectedBase
        SETTINGS.SFX = (t.SFX == nil) and SETTINGS.SFX or not not t.SFX
    end
    local p = fileRead(PROFILES_FILE)
    local pt = safeDecode(p)
    if type(pt) == "table" then
        for i=1,MAX_SLOTS do PROFILES[i] = pt[i] end
    end
end

local function persistSettings()
    local ok, err = pcall(function()
        local s = safeEncode({
            Theme = SETTINGS.Theme,
            Language = SETTINGS.Language,
            Position = SETTINGS.Position,
            Size = SETTINGS.Size,
            SelectedBase = SETTINGS.SelectedBase,
            SFX = SETTINGS.SFX
        })
        if s then fileWrite(SETTINGS_FILE, s) end
    end)
    if not ok then warn("Persist settings failed", err) end
end
local function persistProfiles()
    local ok, err = pcall(function()
        local s = safeEncode(PROFILES)
        if s then fileWrite(PROFILES_FILE, s) end
    end)
    if not ok then warn("Persist profiles failed", err) end
end

-- Executors
local EXECUTORS = {
    ["XENO"] = function(code) if syn and type(loadstring)=="function" then return pcall(loadstring, code) end return false end,
    ["DELTA X"] = function(code) if delta and type(delta.execute)=="function" then return pcall(function() delta.execute(code) end) end return false end,
    ["KRNL"] = function(code) if KRNL and type(KRNL.execute)=="function" then return pcall(function() KRNL.execute(code) end) end if krnl and type(krnl.execute)=="function" then return pcall(function() krnl.execute(code) end) end if loadstring then return pcall(loadstring, code) end return false end,
    ["Arceus X"] = function(code) if ArceusX and type(ArceusX.execute)=="function" then return pcall(function() ArceusX.execute(code) end) end return false end,
    ["Fluxus"] = function(code) if fluxus and type(fluxus.execute)=="function" then return pcall(function() fluxus.execute(code) end) end return false end,
    ["Electron"] = function(code) if electron and type(electron.execute)=="function" then return pcall(function() electron.execute(code) end) end return false end,
    ["Oxygen U"] = function(code) if oxygen and type(oxygen.execute)=="function" then return pcall(function() oxygen.execute(code) end) end return false end,
    ["Script-Ware"] = function(code) if is_sirhurt_closure then return pcall(function() loadstring(code)() end) end if loadstring then return pcall(loadstring, code) end return false end,
    ["Evon"] = function(code) if evon and type(evon.execute)=="function" then return pcall(function() evon.execute(code) end) end return false end,
}

local BASES = {"KRNL","DELTA X","XENO","Arceus X","Fluxus","Electron","Oxygen U","Script-Ware","Evon"}
SETTINGS.SelectedBase = SETTINGS.SelectedBase or DEFAULT_BASE

-- ========== BUILD UI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FogHubGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

-- SFX folder
local SFX = Instance.new("Folder", screenGui); SFX.Name = "SFX"
local function createSFX(id, name)
    if not id then return nil end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = 0.8
    s.Name = name or "sfx"
    s.Parent = SFX
    return s
end

-- Root window
local Window = Instance.new("Frame", screenGui)
Window.Name = "FogHub_Window"
Window.Size = UDim2.new(0, SETTINGS.Size[1], 0, SETTINGS.Size[2])
local pos = SETTINGS.Position
Window.Position = UDim2.new(pos[1], pos[2] or 0, pos[3], pos[4] or 0)
Window.BackgroundColor3 = THEMES[SETTINGS.Theme].window
Window.Active = true
Window.ClipsDescendants = true
local winCorner = Instance.new("UICorner", Window); winCorner.CornerRadius = UDim.new(0,12)
local winStroke = Instance.new("UIStroke", Window); winStroke.Thickness = 1; winStroke.Color = THEMES[SETTINGS.Theme].accent; winStroke.Transparency = 0.35

-- Header (title/subtitle) and close button
local Header = Instance.new("Frame", Window); Header.Name = "Header"; Header.Size = UDim2.new(1,0,0,48); Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header); Title.Position = UDim2.new(0,12,0,6); Title.Size = UDim2.new(0.6,-12,0,28); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.TextSize = 20; Title.TextColor3 = Color3.fromRGB(255,255,255); Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Text = "Fog Hub"
local Sub = Instance.new("TextLabel", Header); Sub.Position = UDim2.new(0,12,0,30); Sub.Size = UDim2.new(0.6,-12,0,16); Sub.BackgroundTransparency = 1; Sub.Font = Enum.Font.Gotham; Sub.TextSize = 12; Sub.TextColor3 = Color3.fromRGB(200,200,200); Sub.Text = "Universal Executors"
local CloseBtn = Instance.new("TextButton", Header); CloseBtn.Size = UDim2.new(0,36,0,28); CloseBtn.Position = UDim2.new(1,-48,0,10); CloseBtn.AnchorPoint = Vector2.new(0,0); CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 18; CloseBtn.BackgroundTransparency = 0.4; local closeCorner = Instance.new("UICorner", CloseBtn); closeCorner.CornerRadius = UDim.new(0,6)

-- Footer (for dragging by bottom)
local Footer = Instance.new("Frame", Window); Footer.Name = "Footer"; Footer.Size = UDim2.new(1,0,0,28); Footer.Position = UDim2.new(0,0,1,-28); Footer.BackgroundTransparency = 1
local FooterText = Instance.new("TextLabel", Footer); FooterText.Position = UDim2.new(0,12,0,4); FooterText.Size = UDim2.new(1,-24,1,-8); FooterText.BackgroundTransparency = 1; FooterText.Font = Enum.Font.Gotham; FooterText.TextSize = 12; FooterText.TextColor3 = Color3.fromRGB(200,200,200); FooterText.Text = "By Hikmes0"; FooterText.TextTransparency = 0.5

-- Left tabs column
local TabsCol = Instance.new("Frame", Window)
TabsCol.Name = "TabsCol"
TabsCol.Size = UDim2.new(0,160,1,-92)
TabsCol.Position = UDim2.new(0,12,0,60)
TabsCol.BackgroundTransparency = 1
local TabsBg = Instance.new("Frame", TabsCol); TabsBg.Size = UDim2.new(1,0,1,0); TabsBg.Position = UDim2.new(0,0,0,0); TabsBg.BackgroundColor3 = Color3.fromRGB(18,10,28); local tabsCorner = Instance.new("UICorner", TabsBg); tabsCorner.CornerRadius = UDim.new(0,10)
local TabsLayout = Instance.new("UIListLayout", TabsBg); TabsLayout.Padding = UDim.new(0,8); TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder; TabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Content area
local Content = Instance.new("Frame", Window); Content.Name = "Content"; Content.Size = UDim2.new(1,-196,1,-92); Content.Position = UDim2.new(0,184,0,60); Content.BackgroundTransparency = 1
local Pages = Instance.new("Folder", Content); Pages.Name = "Pages"

-- Resizer (bottom-right white square)
local Resizer = Instance.new("Frame", Window); Resizer.Name = "Resizer"; Resizer.Size = UDim2.new(0,14,0,14); Resizer.Position = UDim2.new(1,-18,1,-18); Resizer.BackgroundColor3 = Color3.fromRGB(255,255,255); local rcorner = Instance.new("UICorner", Resizer); rcorner.CornerRadius = UDim.new(0,3)

-- Circular toggle button (movable)
local ToggleBtn = Instance.new("TextButton", screenGui); ToggleBtn.Name = "ToggleBtn"; ToggleBtn.Size = UDim2.new(0,64,0,64); ToggleBtn.Position = UDim2.new(0,12,0.6,-32); ToggleBtn.AnchorPoint = Vector2.new(0,0.5); ToggleBtn.AutoButtonColor = false
ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.TextSize = 28; ToggleBtn.Text = THEMES[SETTINGS.Theme].symbol; ToggleBtn.BackgroundColor3 = THEMES[SETTINGS.Theme].button
local toggleCorner = Instance.new("UICorner", ToggleBtn); toggleCorner.CornerRadius = UDim.new(1,0)
local toggleSpark = Instance.new("Frame", ToggleBtn); toggleSpark.Size = UDim2.new(0,14,0,14); toggleSpark.Position = UDim2.new(1,-20,0,6); toggleSpark.BackgroundColor3 = Color3.fromRGB(255,235,120); local tsC = Instance.new("UICorner", toggleSpark); tsC.CornerRadius = UDim.new(1,0)

-- Tab creation
local TAB_ORDER = {"Main","Base","Universal","Profiles","Settings"}
local TabButtons = {}
local PageFrames = {}

local function createTab(name)
    local btn = Instance.new("TextButton", TabsBg)
    btn.Name = name.."_Tab"
    btn.Size = UDim2.new(1,-16,0,40)
    btn.Position = UDim2.new(0,8,0,0)
    btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Text = name
    btn.AutoButtonColor = false
    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0,8)

    local page = Instance.new("Frame", Pages)
    page.Name = name.."_Page"
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false

    TabButtons[name] = btn
    PageFrames[name] = page

    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {TextColor3 = THEMES[SETTINGS.Theme].accent}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(220,220,220)}):Play() end)
    btn.MouseButton1Click:Connect(function()
        for k,v in pairs(PageFrames) do v.Visible = false end
        page.Visible = true
        for _,b in pairs(TabButtons) do b.TextColor3 = Color3.fromRGB(200,200,200) end
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        showToast( (L[SETTINGS.Language].toast_base and string.format(L[SETTINGS.Language].toast_tab or "Opened: %s", name)) or ("Opened: "..name) )
    end)
    return btn, page
end

for _,n in ipairs(TAB_ORDER) do createTab(n) end

-- ===== MAIN PAGE CONTENT =====
do
    local page = PageFrames["Main"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = L[SETTINGS.Language].tabs[1]
    local execLabel = Instance.new("TextLabel", page); execLabel.Name = "ExecLabel"; execLabel.Size = UDim2.new(1,-24,0,20); execLabel.Position = UDim2.new(0,12,0,36); execLabel.BackgroundTransparency = 1; execLabel.Font = Enum.Font.Gotham; execLabel.TextSize = 14; execLabel.TextColor3 = Color3.fromRGB(210,210,210); execLabel.TextXAlignment = Enum.TextXAlignment.Left
    execLabel.Text = string.format(L[SETTINGS.Language].executor, SETTINGS.SelectedBase)

    local codeBox = Instance.new("TextBox", page); codeBox.Name = "CodeBox"; codeBox.Position = UDim2.new(0,12,0,66); codeBox.Size = UDim2.new(1,-24,0.62,-66); codeBox.BackgroundColor3 = Color3.fromRGB(28,14,40); codeBox.TextColor3 = Color3.fromRGB(240,240,240); codeBox.Font = Enum.Font.Code; codeBox.TextSize = 14; codeBox.TextWrapped = true; codeBox.MultiLine = true; codeBox.ClearTextOnFocus = false; codeBox.PlaceholderText = (SETTINGS.Language == "RU" and L.RU.placeholder or L.EN.placeholder)
    local cbCorner = Instance.new("UICorner", codeBox); cbCorner.CornerRadius = UDim.new(0,8)

    local execBtn = Instance.new("TextButton", page); execBtn.Name = "ExecBtn"; execBtn.Size = UDim2.new(0,140,0,40); execBtn.Position = UDim2.new(0.5,-70,0.86,0); execBtn.AnchorPoint = Vector2.new(0.5,0); execBtn.Font = Enum.Font.GothamBold; execBtn.TextSize = 16; execBtn.Text = (SETTINGS.Language == "RU" and L.RU.execute or L.EN.execute); execBtn.BackgroundColor3 = THEMES[SETTINGS.Theme].accent; execBtn.TextColor3 = Color3.fromRGB(255,255,255); local ebCorner = Instance.new("UICorner", execBtn); ebCorner.CornerRadius = UDim.new(0,8)

    local execDebounce = false
    execBtn.MouseButton1Click:Connect(function()
        if execDebounce then return end
        execDebounce = true
        local code = codeBox.Text or ""
        local execFn = EXECUTORS[SETTINGS.SelectedBase]
        local ok, res = false, nil
        if type(execFn) == "function" then
            ok, res = pcall(function() return execFn(code) end)
        end
        if not ok or res == false then
            -- fallback loadstring
            local ok2, err2 = pcall(function() if loadstring then loadstring(code)() end end)
            if not ok2 then
                showToast(string.format(L[SETTINGS.Language].toast_executed or "Error: %s", tostring(err2)))
            else
                showToast(string.format(L[SETTINGS.Language].toast_executed, SETTINGS.SelectedBase))
            end
        else
            showToast(string.format(L[SETTINGS.Language].toast_executed, SETTINGS.SelectedBase))
        end
        if SETTINGS.SFX then pcall(function() local s = SFX:FindFirstChild("click"); if s then s:Play() end end) end
        task.delay(0.5, function() execDebounce = false end)
    end)

    -- make placeholder / text respond to language change later
    codeBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local w = codeBox.AbsoluteSize.X
        local size = math.clamp(math.floor(w / 40), 12, 18)
        pcall(function() codeBox.TextSize = size end)
    end)
end

-- ===== BASE PAGE CONTENT =====
do
    local page = PageFrames["Base"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = L[SETTINGS.Language].tabs[2]
    local scroll = Instance.new("ScrollingFrame", page); scroll.Position = UDim2.new(0,12,0,44); scroll.Size = UDim2.new(1,-24,1,-56); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 8
    local layout = Instance.new("UIListLayout", scroll); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,8)

    for i,b in ipairs(BASES) do
        local btn = Instance.new("TextButton", scroll); btn.Size = UDim2.new(1,-12,0,40); btn.Position = UDim2.new(0,6,0,(i-1)*48); btn.BackgroundColor3 = Color3.fromRGB(28,12,36); btn.Font = Enum.Font.Gotham; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(235,235,235); btn.Text = b
        local bc = Instance.new("UICorner", btn); bc.CornerRadius = UDim.new(0,8)
        btn.MouseButton1Click:Connect(function()
            SETTINGS.SelectedBase = b
            persistSettings()
            local mainExecLabel = PageFrames["Main"]:FindFirstChild("ExecLabel")
            if mainExecLabel then mainExecLabel.Text = string.format(L[SETTINGS.Language].executor, b) end
            showToast(string.format(L[SETTINGS.Language].toast_base, b))
            if SETTINGS.SFX then pcall(function() local s = SFX:FindFirstChild("click"); if s then s:Play() end end) end
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = THEMES[SETTINGS.Theme].accent}):Play()
            task.delay(0.12, function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(28,12,36)}):Play() end)
        end)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12) end)
end

-- ===== UNIVERSAL PAGE =====
do
    local page = PageFrames["Universal"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = L[SETTINGS.Language].tabs[3]
    local infBtn = Instance.new("TextButton", page); infBtn.Size = UDim2.new(0.46,0,0,40); infBtn.Position = UDim2.new(0.27,0,0.18,0); infBtn.Text = L[SETTINGS.Language].infinite; infBtn.Font = Enum.Font.GothamBold; infBtn.TextSize = 16; infBtn.BackgroundColor3 = Color3.fromRGB(0,120,200); local ic = Instance.new("UICorner", infBtn); ic.CornerRadius = UDim.new(0,8)
    infBtn.MouseButton1Click:Connect(function()
        local ok,err = pcall(function()
            local src = game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
            loadstring(src)()
        end)
        if ok then showToast(L[SETTINGS.Language].toast_inf or L[SETTINGS.Language].infinite) else showToast("Error: "..tostring(err)) end
    end)
end

-- ===== PROFILES PAGE =====
do
    local page = PageFrames["Profiles"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = L[SETTINGS.Language].tabs[4]
    local frame = Instance.new("Frame", page); frame.Position = UDim2.new(0,12,0,44); frame.Size = UDim2.new(1,-24,1,-56); frame.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", frame); layout.Padding = UDim.new(0,8)

    local slotUI = {}
    for i=1,MAX_SLOTS do
        local slot = Instance.new("Frame", frame); slot.Size = UDim2.new(1,0,0,84); slot.BackgroundColor3 = Color3.fromRGB(24,10,30); local sc = Instance.new("UICorner", slot); sc.CornerRadius = UDim.new(0,8)
        local nameLbl = Instance.new("TextLabel", slot); nameLbl.Position = UDim2.new(0,12,0,8); nameLbl.Size = UDim2.new(0.5,-24,0,24); nameLbl.BackgroundTransparency = 1; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 16; nameLbl.TextColor3 = Color3.fromRGB(235,235,235)
        nameLbl.Text = (PROFILES[i] and PROFILES[i].Name) or L[SETTINGS.Language].empty

        local btnRename = Instance.new("TextButton", slot); btnRename.Size = UDim2.new(0,84,0,28); btnRename.Position = UDim2.new(1,-96,0,8); btnRename.Text = L[SETTINGS.Language].rename; local ruc=Instance.new("UICorner", btnRename); ruc.CornerRadius = UDim.new(0,6)
        local btnSave = Instance.new("TextButton", slot); btnSave.Size = UDim2.new(0,84,0,28); btnSave.Position = UDim2.new(1,-96,0,44); btnSave.Text = L[SETTINGS.Language].save; local sc2=Instance.new("UICorner", btnSave); sc2.CornerRadius = UDim.new(0,6)
        local btnLoad = Instance.new("TextButton", slot); btnLoad.Size = UDim2.new(0,84,0,28); btnLoad.Position = UDim2.new(1,-186,0,44); btnLoad.Text = L[SETTINGS.Language].load; local lc=Instance.new("UICorner", btnLoad); lc.CornerRadius = UDim.new(0,6)
        local btnDelete = Instance.new("TextButton", slot); btnDelete.Size = UDim2.new(0,84,0,28); btnDelete.Position = UDim2.new(1,-276,0,44); btnDelete.Text = L[SETTINGS.Language].delete; local dc=Instance.new("UICorner", btnDelete); dc.CornerRadius = UDim.new(0,6)

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
            showToast(L[SETTINGS.Language].toast_saved)
        end)

        btnLoad.MouseButton1Click:Connect(function()
            local prof = PROFILES[i]
            if not prof then showToast(L[SETTINGS.Language].empty); return end
            SETTINGS.Theme = prof.Theme or SETTINGS.Theme
            SETTINGS.Language = prof.Language or SETTINGS.Language
            if type(prof.Position) == "table" and #prof.Position >= 4 then Window.Position = UDim2.new(prof.Position[1], prof.Position[2], prof.Position[3], prof.Position[4]) end
            if type(prof.Size) == "table" and #prof.Size >= 2 then Window.Size = UDim2.new(0, math.max(MIN_SIZE.X, prof.Size[1]), 0, math.max(MIN_SIZE.Y, prof.Size[2])) end
            SETTINGS.SelectedBase = prof.SelectedBase or SETTINGS.SelectedBase
            SETTINGS.SFX = (prof.SFX == nil) and SETTINGS.SFX or not not prof.SFX
            applyTheme(SETTINGS.Theme)
            refreshTexts()
            persistSettings()
            showToast(L[SETTINGS.Language].toast_loaded_profile)
        end)

        btnDelete.MouseButton1Click:Connect(function()
            PROFILES[i] = nil
            nameLbl.Text = L[SETTINGS.Language].empty
            persistProfiles()
            showToast(L[SETTINGS.Language].toast_deleted)
        end)

        btnRename.MouseButton1Click:Connect(function()
            local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,380,0,100); modal.Position = UDim2.new(0.5,-190,0.5,-50); modal.BackgroundColor3 = Color3.fromRGB(18,12,28); modal.ZIndex = 999
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

        slotUI[i] = {frame = slot, nameLbl = nameLbl}
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() frame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12) end)
end

-- ===== SETTINGS PAGE =====
do
    local page = PageFrames["Settings"]
    local header = Instance.new("TextLabel", page); header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = L[SETTINGS.Language].tabs[5]
    local themeLabel = Instance.new("TextLabel", page); themeLabel.Position = UDim2.new(0,12,0,44); themeLabel.Size = UDim2.new(1,-24,0,20); themeLabel.BackgroundTransparency = 1; themeLabel.Font = Enum.Font.Gotham; themeLabel.TextSize = 14; themeLabel.TextColor3 = Color3.fromRGB(220,220,220); themeLabel.Text = "Themes"

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
    local ru = Instance.new("TextButton", page); ru.Size = UDim2.new(0,48,0,28); ru.Position = UDim2.new(0,140,0,148); ru.Text="🇷🇺"; local ruc = Instance.new("UICorner", ru); ruc.CornerRadius = UDim.new(0,6)
    local en = Instance.new("TextButton", page); en.Size = UDim2.new(0,48,0,28); en.Position = UDim2.new(0,200,0,148); en.Text="🇺🇸"; local enc = Instance.new("UICorner", en); enc.CornerRadius = UDim.new(0,6)
    ru.MouseButton1Click:Connect(function()
        SETTINGS.Language = "RU"
        persistSettings()
        refreshTexts()
        showToast("Language: RU")
    end)
    en.MouseButton1Click:Connect(function()
        SETTINGS.Language = "EN"
        persistSettings()
        refreshTexts()
        showToast("Language: EN")
    end)

    -- SFX toggle
    local sfxLabel = Instance.new("TextLabel", page); sfxLabel.Position = UDim2.new(0,260,0,150); sfxLabel.Size = UDim2.new(0,60,0,24); sfxLabel.BackgroundTransparency = 1; sfxLabel.Font=Enum.Font.Gotham; sfxLabel.TextColor3=Color3.fromRGB(220,220,220); sfxLabel.Text="SFX"
    local sfxBtn = Instance.new("TextButton", page); sfxBtn.Position = UDim2.new(0,320,0,148); sfxBtn.Size = UDim2.new(0,48,0,28); sfxBtn.Text = (SETTINGS.SFX and "ON" or "OFF")
    sfxBtn.MouseButton1Click:Connect(function() SETTINGS.SFX = not SETTINGS.SFX; sfxBtn.Text = (SETTINGS.SFX and "ON" or "OFF"); persistSettings() end)

    -- Export / Import
    local exportBtn = Instance.new("TextButton", page); exportBtn.Size = UDim2.new(0,100,0,30); exportBtn.Position = UDim2.new(1,-236,1,-44); exportBtn.AnchorPoint = Vector2.new(0,1); exportBtn.Text = L[SETTINGS.Language].export
    local importBtn = Instance.new("TextButton", page); importBtn.Size = UDim2.new(0,100,0,30); importBtn.Position = UDim2.new(1,-120,1,-44); importBtn.AnchorPoint = Vector2.new(0,1); importBtn.Text = L[SETTINGS.Language].import

    exportBtn.MouseButton1Click:Connect(function()
        local s = safeEncode(PROFILES)
        if s then
            local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,540,0,220); modal.Position = UDim2.new(0.5,-270,0.5,-110); modal.BackgroundColor3 = Color3.fromRGB(18,12,28); local mc = Instance.new("UICorner", modal); mc.CornerRadius = UDim.new(0,8)
            local tb = Instance.new("TextBox", modal); tb.Size = UDim2.new(1,-24,1,-64); tb.Position = UDim2.new(0,12,0,12); tb.Text = s; tb.MultiLine = true; tb.Font = Enum.Font.Code; tb.TextSize = 14
            local ok = Instance.new("TextButton", modal); ok.Size = UDim2.new(0,84,0,36); ok.Position = UDim2.new(1,-96,1,-44); ok.Text = "OK"; local okc = Instance.new("UICorner", ok); okc.CornerRadius = UDim.new(0,8)
            ok.MouseButton1Click:Connect(function() modal:Destroy() end)
        else
            showToast("Export error")
        end
    end)

    importBtn.MouseButton1Click:Connect(function()
        local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,540,0,220); modal.Position = UDim2.new(0.5,-270,0.5,-110); modal.BackgroundColor3 = Color3.fromRGB(18,12,28); local mc = Instance.new("UICorner", modal); mc.CornerRadius = UDim.new(0,8)
        local tb = Instance.new("TextBox", modal); tb.Size = UDim2.new(1,-24,1,-64); tb.Position = UDim2.new(0,12,0,12); tb.PlaceholderText = "Paste profiles JSON here"; tb.MultiLine = true; tb.Font = Enum.Font.Code; tb.TextSize = 14
        local ok = Instance.new("TextButton", modal); ok.Size = UDim2.new(0,84,0,36); ok.Position = UDim2.new(1,-96,1,-44); ok.Text = "Import"; local okc = Instance.new("UICorner", ok); okc.CornerRadius = UDim.new(0,8)
        local cancel = Instance.new("TextButton", modal); cancel.Size = UDim2.new(0,84,0,36); cancel.Position = UDim2.new(1,-196,1,-44); cancel.Text = "Cancel"; local canc = Instance.new("UICorner", cancel); canc.CornerRadius = UDim.new(0,8)
        ok.MouseButton1Click:Connect(function()
            local s = tb.Text
            local t = safeDecode(s)
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

-- ===== helper: showToast (localized) =====
function showToast(text)
    local toast = Instance.new("Frame", screenGui); toast.Size = UDim2.new(0,260,0,44); toast.Position = UDim2.new(1,-280,1,-60); toast.BackgroundColor3 = Color3.fromRGB(28,28,28); local tC = Instance.new("UICorner", toast); tC.CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", toast); label.Size = UDim2.new(1,-12,1,-12); label.Position = UDim2.new(0,6,0,6); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamBold; label.TextSize = 14; label.TextColor3 = Color3.fromRGB(255,255,255); label.Text = text; label.TextXAlignment = Enum.TextXAlignment.Left
    TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position = UDim2.new(1,-280,1,-120)}):Play()
    task.delay(3, function()
        TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        TweenService:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
        task.delay(0.35, function() pcall(function() toast:Destroy() end) end)
    end)
end

-- ===== helper: applyTheme & sfx rebuild =====
local function rebuildSFX(themeKey)
    for _,v in pairs(SFX:GetChildren()) do pcall(function() v:Destroy() end) end
    local t = THEMES[themeKey]
    if not t or not t.sfx then return end
    createSFX(t.sfx.open, "open")
    createSFX(t.sfx.close, "close")
    createSFX(t.sfx.click, "click")
end

function applyTheme(themeKey)
    local t = THEMES[themeKey] or THEMES.Default
    Window.BackgroundColor3 = t.window
    winStroke.Color = t.accent
    ToggleBtn.BackgroundColor3 = t.button
    ToggleBtn.Text = t.symbol
    -- exec button color if exists
    local execBtn = PageFrames["Main"] and PageFrames["Main"]:FindFirstChild("ExecBtn")
    if execBtn then execBtn.BackgroundColor3 = t.accent end
    rebuildSFX(themeKey)
    if SETTINGS.SFX then pcall(function() local s=SFX:FindFirstChild("open"); if s then s:Play() end end) end
end

-- ===== helper: refresh texts (language) =====
function refreshTexts()
    local lang = SETTINGS.Language or DEFAULT_LANG
    for i,name in ipairs(TAB_ORDER) do
        local btn = TabButtons[name]
        if btn then btn.Text = L[lang].tabs[i] or name end
    end
    -- main placeholder & execute text & label
    local codeBox = PageFrames["Main"] and PageFrames["Main"]:FindFirstChild("CodeBox")
    if codeBox then codeBox.PlaceholderText = L[lang].placeholder end
    local execBtn = PageFrames["Main"] and PageFrames["Main"]:FindFirstChild("ExecBtn")
    if execBtn then execBtn.Text = L[lang].execute end
    local execLabel = PageFrames["Main"] and PageFrames["Main"]:FindFirstChild("ExecLabel")
    if execLabel then execLabel.Text = string.format(L[lang].executor, SETTINGS.SelectedBase) end

    -- profiles names
    local idx = 1
    for _,child in ipairs(PageFrames["Profiles"]:GetChildren()) do
        if child:IsA("Frame") then
            local lbl = nil
            for _,c in ipairs(child:GetChildren()) do if c:IsA("TextLabel") then lbl = c break end end
            if lbl then
                lbl.Text = (PROFILES[idx] and PROFILES[idx].Name) or L[lang].empty
            end
            idx = idx + 1
            if idx > MAX_SLOTS then break end
        end
    end
end

-- ===== dragging (header/footer/toggle) =====
do
    local dragging = false
    local dragStart = Vector2.new()
    local windowOrigin = UDim2.new()
    local function beginDrag(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        dragStart = input.Position
        windowOrigin = Window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                SETTINGS.Position = { Window.Position.X.Scale, Window.Position.X.Offset, Window.Position.Y.Scale, Window.Position.Y.Offset }
                persistSettings()
            end
        end)
    end
    local function updateDrag(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(windowOrigin.X.Scale, windowOrigin.X.Offset + delta.X, windowOrigin.Y.Scale, windowOrigin.Y.Offset + delta.Y)
        end
    end

    -- header and footer drag
    Header.InputBegan:Connect(beginDrag)
    Footer.InputBegan:Connect(beginDrag)
    -- allow also dragging by ToggleBtn: if user holds toggle and moves, move window
    ToggleBtn.MouseButton1Down:Connect(function(input)
        if input then
            beginDrag(input)
        end
    end)
    UserInputService.InputChanged:Connect(updateDrag)
end

-- ===== ToggleBtn dragging (move the button itself) =====
do
    local draggingBtn = false
    local startPosBtn
    local originPosBtn
    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingBtn = true
            startPosBtn = input.Position
            originPosBtn = ToggleBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then draggingBtn = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not draggingBtn then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startPosBtn
            ToggleBtn.Position = UDim2.new(originPosBtn.X.Scale, originPosBtn.X.Offset + delta.X, originPosBtn.Y.Scale, originPosBtn.Y.Offset + delta.Y)
        end
    end)
end

-- ===== Resizer logic: resize in direction of drag (bottom-right anchor but support negative deltas) =====
do
    local resizing = false
    local startPos, startSize
    Resizer.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        resizing = true
        startPos = input.Position
        startSize = Window.AbsoluteSize
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                SETTINGS.Size = { Window.AbsoluteSize.X, Window.AbsoluteSize.Y }
                persistSettings()
            end
        end)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not resizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startPos
            local newW = math.max(MIN_SIZE.X, math.floor(startSize.X + delta.X))
            local newH = math.max(MIN_SIZE.Y, math.floor(startSize.Y + delta.Y))
            Window.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
end

-- ===== Close / Open / X button behavior =====
local isOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if isOpen then
        Window.Visible = true
        local t = TweenService:Create(Window, TweenInfo.new(0.26, Enum.EasingStyle.Back), {Size = Window.Size})
        t:Play()
        if SETTINGS.SFX then pcall(function() local s=SFX:FindFirstChild("open"); if s then s:Play() end end) end
    else
        local t = TweenService:Create(Window, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {Size = UDim2.new(0,18,0,18)})
        t:Play()
        t.Completed:Connect(function() Window.Visible = false end)
        if SETTINGS.SFX then pcall(function() local s=SFX:FindFirstChild("close"); if s then s:Play() end end) end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Window.Visible = false
    isOpen = false
    ToggleBtn.Text = L[SETTINGS.Language].open
    if SETTINGS.SFX then pcall(function() local s=SFX:FindFirstChild("close"); if s then s:Play() end end) end
end)

-- ===== Window resize reaction: adjust text sizes & placeholder updates =====
local function onWindowResize()
    SETTINGS.Size = { Window.AbsoluteSize.X, Window.AbsoluteSize.Y }
    -- adjust base text sizes
    for _,obj in ipairs(Window:GetDescendants()) do
        if obj:IsA("TextLabel") and not obj.TextScaled then
            local w = math.max(240, Window.AbsoluteSize.X)
            local size = math.clamp(math.floor(w / 60), 12, 20)
            pcall(function() obj.TextSize = size end)
        elseif obj:IsA("TextButton") and not obj.TextScaled then
            local w = math.max(240, Window.AbsoluteSize.X)
            local size = math.clamp(math.floor(w / 80), 12, 18)
            pcall(function() obj.TextSize = size end)
        elseif obj:IsA("TextBox") and not obj.TextScaled then
            local w = math.max(240, Window.AbsoluteSize.X)
            local size = math.clamp(math.floor(w / 60), 12, 18)
            pcall(function() obj.TextSize = size end)
        end
    end
    persistSettings()
end
Window:GetPropertyChangedSignal("AbsoluteSize"):Connect(onWindowResize)

-- ===== Initial apply theme & texts =====
function applyThemeAndBuild(theme)
    applyTheme(theme)
end

function refreshTexts()
    refreshTexts = refreshTexts -- no-op to satisfy linter; actual function defined earlier
end

-- define applyTheme and refreshTexts if not present (they are above)
applyTheme(SETTINGS.Theme)
refreshTexts()
rebuildSFX(SETTINGS.Theme)

-- Show Main tab by default
for k,v in pairs(PageFrames) do v.Visible = false end
PageFrames["Main"].Visible = true
TabButtons["Main"].TextColor3 = Color3.fromRGB(255,255,255)

-- Initial toast
showToast( L[SETTINGS.Language].toast_loaded )

-- Ensure profile UI texts reflect loaded profiles and language
refreshTexts()

-- Save settings on leave (best effort)
pcall(function() persistSettings(); persistProfiles() end)

-- End of script
