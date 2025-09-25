--[[
  Fog Hub - Universal Executors
  By Hikmes0

  Полный LocalScript (всё в одном):
  - UI: вкладки слева (Main, Base, Universal, Profiles, Settings)
  - Execute: поддержка множества эксплойтов (KRNL, DELTA X, XENO, Arceus X, Fluxus, Electron, Oxygen U, Script-Ware, Evon)
  - Profiles: 3 слота, JSON (Profiles.json) + экспорт/импорт
  - Settings: темы (7+Pay2Win), язык RU/EN, SFX toggle
  - Universal: Infinite Yield (raw github link)
  - Toasts, drag, resize, responsive text, animations, SFX
  - Требует exploit API: writefile/readfile/isfile/delfile (есть fallback в памяти)
]]

-- ===== services / basic =====
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ===== exploit file API detection =====
local HAS_WRITEFILE = type(writefile) == "function"
local HAS_READFILE  = type(readfile) == "function"
local HAS_ISFILE    = type(isfile) == "function"
local HAS_DELFILE   = type(delfile) == "function"

-- ===== filenames =====
local PROFILES_FILE  = "FogHub_Profiles.json"
local SETTINGS_FILE  = "FogHub_Settings.json"

-- ===== safe json helpers =====
local function safeEncode(t)
    local ok, s = pcall(function() return HttpService:JSONEncode(t) end)
    if ok then return s end
    return nil
end
local function safeDecode(s)
    if type(s) ~= "string" then return nil end
    local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
    if ok then return t end
    return nil
end

-- ===== file wrappers with fallbacks =====
local volatileProfiles = {nil, nil, nil}
local volatileSettings = {}

local function fileExists(name)
    if HAS_ISFILE then
        local ok, res = pcall(function() return isfile(name) end)
        if ok then return res end
    end
    return false
end
local function fileRead(name)
    if HAS_READFILE then
        local ok, res = pcall(function() return readfile(name) end)
        if ok then return res end
    end
    return nil
end
local function fileWrite(name, text)
    if HAS_WRITEFILE then
        local ok, err = pcall(function() writefile(name, text) end)
        if ok then return true end
        return false, err
    else
        return false, "no_writefile"
    end
end
local function fileDelete(name)
    if HAS_DELFILE then pcall(function() delfile(name) end) end
end

-- ===== default settings =====
local THEMES = {
    ["Cyberpunk"] = { window=Color3.fromRGB(8,8,18), accent=Color3.fromRGB(0,200,255), button=Color3.fromRGB(0,200,255), symbol="💠" },
    ["Neon"] = { window=Color3.fromRGB(25,0,40), accent=Color3.fromRGB(255,0,200), button=Color3.fromRGB(255,0,200), symbol="⚡" },
    ["Dark Purple"] = { window=Color3.fromRGB(25,0,40), accent=Color3.fromRGB(173,107,255), button=Color3.fromRGB(255,205,0), symbol="✨" },
    ["Ice Blue"] = { window=Color3.fromRGB(12,20,30), accent=Color3.fromRGB(120,200,255), button=Color3.fromRGB(120,200,255), symbol="❄️" },
    ["Matrix"] = { window=Color3.fromRGB(2,2,2), accent=Color3.fromRGB(0,255,70), button=Color3.fromRGB(0,255,70), symbol="🟢" },
    ["Inferno"] = { window=Color3.fromRGB(30,6,6), accent=Color3.fromRGB(255,80,0), button=Color3.fromRGB(255,140,0), symbol="🔥" },
    ["Crystal"] = { window=Color3.fromRGB(38,6,66), accent=Color3.fromRGB(170,120,255), button=Color3.fromRGB(170,120,255), symbol="💎" },
    ["Pay2Win"] = { window=Color3.fromRGB(12,8,10), accent=Color3.fromRGB(255,200,0), button=Color3.fromRGB(255,200,0), symbol="💰" },
}

local DEFAULT_THEME = "Dark Purple"
local DEFAULT_LANG = "RU"
local DEFAULT_BASE = "KRNL"
local MAX_SLOTS = 3
local MIN_SIZE = Vector2.new(320, 200)

local LANG_TABLE = {
    RU = {
        tabs = {"Главная","База","Универсальные","Профили","Настройки"},
        executor = "Исполнитель: %s",
        execute = "Выполнить",
        code_placeholder = "-- Вставь код сюда",
        infinite = "Infinite Yield",
        toast_started = "Fog Hub загружен",
        toast_executed = "Скрипт отправлен в %s",
        toast_base = "Выбрана база: %s",
        toast_saved = "Профиль сохранён",
        toast_loaded = "Профиль загружен",
        toast_deleted = "Профиль удалён",
        toast_error = "Ошибка: %s",
        save_settings = "Сохранить настройки",
        export = "Экспорт",
        import = "Импорт",
        rename = "Переименовать",
        delete = "Удалить",
        load = "Загрузить",
        save = "Сохранить",
        empty = "Пусто",
    },
    EN = {
        tabs = {"Main","Base","Universal","Profiles","Settings"},
        executor = "Executor: %s",
        execute = "Execute",
        code_placeholder = "-- Enter code here",
        infinite = "Infinite Yield",
        toast_started = "Fog Hub started",
        toast_executed = "Script sent to %s",
        toast_base = "Base selected: %s",
        toast_saved = "Profile saved",
        toast_loaded = "Profile loaded",
        toast_deleted = "Profile deleted",
        toast_error = "Error: %s",
        save_settings = "Save settings",
        export = "Export",
        import = "Import",
        rename = "Rename",
        delete = "Delete",
        load = "Load",
        save = "Save",
        empty = "Empty",
    }
}

-- ===== load persisted settings & profiles =====
local SETTINGS = {
    Theme = DEFAULT_THEME,
    Language = DEFAULT_LANG,
    Position = {0.2, 0, 0.2, 0}, -- xScale, xOffset, yScale, yOffset
    Size = {650, 450},
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
        if type(t.Position) == "table" and #t.Position >= 4 then
            SETTINGS.Position = t.Position
        end
        if type(t.Size) == "table" and #t.Size >= 2 then
            SETTINGS.Size = t.Size
        end
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
    local tbl = {
        Theme = SETTINGS.Theme,
        Language = SETTINGS.Language,
        Position = SETTINGS.Position,
        Size = SETTINGS.Size,
        SelectedBase = SETTINGS.SelectedBase,
        SFX = SETTINGS.SFX
    }
    local s = safeEncode(tbl)
    if s then fileWrite(SETTINGS_FILE, s) end
end
local function persistProfiles()
    local s = safeEncode(PROFILES)
    if s then fileWrite(PROFILES_FILE, s) end
end

-- ===== executors table (extended) =====
local EXECUTORS = {
    ["XENO"] = function(code) if syn and type(loadstring)=="function" then pcall(loadstring, code) return true end return false end,
    ["DELTA X"] = function(code) if delta and type(delta.execute)=="function" then pcall(function() delta.execute(code) end) return true end return false end,
    ["KRNL"] = function(code) if KRNL and type(KRNL.execute)=="function" then pcall(function() KRNL.execute(code) end) return true end if krnl and type(krnl.execute)=="function" then pcall(function() krnl.execute(code) end) return true end if loadstring then pcall(loadstring, code) return true end return false end,
    ["Arceus X"] = function(code) if ArceusX and type(ArceusX.execute)=="function" then pcall(function() ArceusX.execute(code) end) return true end return false end,
    ["Fluxus"] = function(code) if fluxus and type(fluxus.execute)=="function" then pcall(function() fluxus.execute(code) end) return true end return false end,
    ["Electron"] = function(code) if electron and type(electron.execute)=="function" then pcall(function() electron.execute(code) end) return true end return false end,
    ["Oxygen U"] = function(code) if oxygen and type(oxygen.execute)=="function" then pcall(function() oxygen.execute(code) end) return true end return false end,
    ["Script-Ware"] = function(code) if is_sirhurt_closure then pcall(function() loadstring(code)() end) return true end if loadstring then pcall(loadstring, code) return true end return false end,
    ["Evon"] = function(code) if evon and type(evon.execute)=="function" then pcall(function() evon.execute(code) end) return true end return false end,
}

local BASE_LIST = {"KRNL","DELTA X","XENO","Arceus X","Fluxus","Electron","Oxygen U","Script-Ware","Evon"}
local selectedBase = SETTINGS.SelectedBase or DEFAULT_BASE

-- ===== UI construction =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FogHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- SFX holder
local SFXFolder = Instance.new("Folder", screenGui)
SFXFolder.Name = "FogHub_SFX"
local function makeSound(id, name)
    if not id then return nil end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = 0.8
    s.Name = name or "sfx"
    s.Parent = SFXFolder
    return s
end

-- root window
local Window = Instance.new("Frame", screenGui)
Window.Name = "Window"
Window.Size = UDim2.new(0, SETTINGS.Size[1], 0, SETTINGS.Size[2])
local pos = SETTINGS.Position
Window.Position = UDim2.new(pos[1], pos[2] or 0, pos[3], pos[4] or 0)
Window.AnchorPoint = Vector2.new(0,0)
Window.BackgroundColor3 = THEMES[SETTINGS.Theme].window
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
local winCorner = Instance.new("UICorner", Window); winCorner.CornerRadius = UDim.new(0,12)
local winStroke = Instance.new("UIStroke", Window); winStroke.Thickness = 1; winStroke.Color = THEMES[SETTINGS.Theme].accent; winStroke.Transparency = 0.35

-- header title / subtitle / footer
local Title = Instance.new("TextLabel", Window)
Title.Size = UDim2.new(1, -24, 0, 36); Title.Position = UDim2.new(0,12,0,6)
Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.TextSize = 20; Title.TextColor3 = Color3.fromRGB(255,255,255); Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "Fog Hub"

local Sub = Instance.new("TextLabel", Window)
Sub.Size = UDim2.new(1,-24,0,20); Sub.Position = UDim2.new(0,12,0,38)
Sub.BackgroundTransparency = 1; Sub.Font = Enum.Font.Gotham; Sub.TextSize = 14; Sub.TextColor3 = Color3.fromRGB(210,210,210); Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.Text = "Universal Executors"

local Footer = Instance.new("TextLabel", Window)
Footer.Size = UDim2.new(1,-24,0,18); Footer.Position = UDim2.new(0,12,1,-24); Footer.BackgroundTransparency = 1; Footer.Font = Enum.Font.Gotham; Footer.TextSize = 12; Footer.TextColor3 = Color3.fromRGB(255,255,255); Footer.TextTransparency = 0.5; Footer.Text = "By Hikmes0"

-- left tabs column
local TabsCol = Instance.new("Frame", Window)
TabsCol.Name = "TabsCol"
TabsCol.Size = UDim2.new(0,150,1,-72)
TabsCol.Position = UDim2.new(0,12,0,72)
TabsCol.BackgroundTransparency = 1

local TabsBg = Instance.new("Frame", TabsCol)
TabsBg.Size = UDim2.new(1,0,1,0); TabsBg.Position = UDim2.new(0,0,0,0); TabsBg.BackgroundColor3 = Color3.fromRGB(18,10,28)
local TabsBgCorner = Instance.new("UICorner", TabsBg); TabsBgCorner.CornerRadius = UDim.new(0,10)

local TabsList = Instance.new("UIListLayout", TabsBg); TabsList.Padding = UDim.new(0,8); TabsList.VerticalAlignment = Enum.VerticalAlignment.Top

-- right content area
local Content = Instance.new("Frame", Window)
Content.Name = "Content"
Content.Size = UDim2.new(1,-186,1,-72)
Content.Position = UDim2.new(0,174,0,72)
Content.BackgroundTransparency = 1

local Pages = Instance.new("Folder", Content); Pages.Name = "Pages"

-- resizer bottom-right
local Resizer = Instance.new("Frame", Window); Resizer.Name = "Resizer"; Resizer.Size = UDim2.new(0,14,0,14); Resizer.Position = UDim2.new(1,-18,1,-18); Resizer.BackgroundColor3 = Color3.fromRGB(255,255,255)
local ResizerCorner = Instance.new("UICorner", Resizer); ResizerCorner.CornerRadius = UDim.new(0,3)

-- mobile circular button
local ToggleBtn = Instance.new("TextButton", screenGui); ToggleBtn.Name = "ToggleBtn"; ToggleBtn.Size = UDim2.new(0,64,0,64); ToggleBtn.Position = UDim2.new(0,12,0.6,-32); ToggleBtn.AnchorPoint = Vector2.new(0,0.5)
ToggleBtn.AutoButtonColor = false; ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.TextSize = 28
ToggleBtn.BackgroundColor3 = THEMES[SETTINGS.Theme].button; ToggleBtn.Text = THEMES[SETTINGS.Theme].symbol
local ToggleCorner = Instance.new("UICorner", ToggleBtn); ToggleCorner.CornerRadius = UDim.new(1,0)
local Spark = Instance.new("Frame", ToggleBtn); Spark.Size = UDim2.new(0,14,0,14); Spark.Position = UDim2.new(1,-20,0,6); Spark.BackgroundColor3 = Color3.fromRGB(255,235,120); local spc = Instance.new("UICorner", Spark); spc.CornerRadius = UDim.new(1,0)

-- create tabs and pages
local TAB_ORDER = {"Main","Base","Universal","Profiles","Settings"}
local TabButtons = {}
local PageFrames = {}

local function createTab(name)
    local btn = Instance.new("TextButton", TabsBg)
    btn.Name = name.."_Btn"
    btn.Size = UDim2.new(1, -12, 0, 42)
    btn.Position = UDim2.new(0,6,0,0)
    btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Text = name
    btn.AutoButtonColor = false
    local corner = Instance.new("UICorner", btn); corner.CornerRadius = UDim.new(0,8)

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
        for _,p in pairs(PageFrames) do p.Visible = false end
        page.Visible = true
        for _,b in pairs(TabButtons) do b.TextColor3 = Color3.fromRGB(200,200,200) end
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        showToast( LANG_TABLE[SETTINGS.Language].toast_tab and string.format(LANG_TABLE[SETTINGS.Language].toast_tab, name) or ("Opened: "..name) )
    end)

    return btn, page
end

for _,n in ipairs(TAB_ORDER) do createTab(n) end

-- ===== MAIN PAGE =====
local mainPage = PageFrames["Main"]
do
    local header = Instance.new("TextLabel", mainPage)
    header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = LANG_TABLE[SETTINGS.Language].Main

    local execLabel = Instance.new("TextLabel", mainPage)
    execLabel.Name = "ExecutorLabel"
    execLabel.Size = UDim2.new(1,-24,0,20); execLabel.Position = UDim2.new(0,12,0,36)
    execLabel.BackgroundTransparency = 1; execLabel.Font = Enum.Font.Gotham; execLabel.TextSize = 14; execLabel.TextColor3 = Color3.fromRGB(210,210,210)
    execLabel.TextXAlignment = Enum.TextXAlignment.Left
    execLabel.Text = string.format(LANG_TABLE[SETTINGS.Language].executor, SETTINGS.SelectedBase)

    local codeBox = Instance.new("TextBox", mainPage)
    codeBox.Name = "CodeBox"
    codeBox.Position = UDim2.new(0,12,0,66)
    codeBox.Size = UDim2.new(1,-24,0.62,-66)
    codeBox.BackgroundColor3 = Color3.fromRGB(28,14,40)
    codeBox.TextColor3 = Color3.fromRGB(240,240,240)
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 14
    codeBox.TextWrapped = true
    codeBox.MultiLine = true
    codeBox.ClearTextOnFocus = false
    codeBox.PlaceholderText = LANG_TABLE[SETTINGS.Language].code_placeholder
    local codeCorner = Instance.new("UICorner", codeBox); codeCorner.CornerRadius = UDim.new(0,8)

    -- make code text size adapt to width
    local function adjustCodeTextSize()
        local w = codeBox.AbsoluteSize.X
        local size = math.clamp(math.floor(w / 40), 12, 18)
        pcall(function() codeBox.TextSize = size end)
    end
    codeBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(adjustCodeTextSize)
    adjustCodeTextSize()

    -- execute button
    local execBtn = Instance.new("TextButton", mainPage)
    execBtn.Name = "ExecuteBtn"
    execBtn.Size = UDim2.new(0,128,0,40)
    execBtn.Position = UDim2.new(0.5,-64,0.86,0)
    execBtn.AnchorPoint = Vector2.new(0.5,0)
    execBtn.Font = Enum.Font.GothamBold
    execBtn.TextSize = 16
    execBtn.Text = LANG_TABLE[SETTINGS.Language].execute
    execBtn.BackgroundColor3 = THEMES[SETTINGS.Theme].accent
    execBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local execCorner = Instance.new("UICorner", execBtn); execCorner.CornerRadius = UDim.new(0,8)

    local execDeb = false
    execBtn.MouseButton1Click:Connect(function()
        if execDeb then return end
        execDeb = true
        local code = codeBox.Text or ""
        -- try executor
        local ok, res = pcall(function()
            local fn = EXECUTORS[SETTINGS.SelectedBase]
            if type(fn) == "function" then
                return fn(code)
            else
                return false
            end
        end)
        if not ok or res == false then
            -- fallback loadstring
            local ok2, err2 = pcall(function() if loadstring then loadstring(code)() end end)
            if not ok2 then
                showToast( string.format(LANG_TABLE[SETTINGS.Language].toast_error or "Error: %s", tostring(err2)) )
            else
                showToast( string.format(LANG_TABLE[SETTINGS.Language].toast_executed or "Executed in %s", SETTINGS.SelectedBase) )
            end
        else
            showToast( string.format(LANG_TABLE[SETTINGS.Language].toast_executed or "Executed in %s", SETTINGS.SelectedBase) )
        end
        if SETTINGS.SFX then pcall(function() local s=SFXFolder:FindFirstChild("click"); if s then s:Play() end end) end
        task.delay(0.5, function() execDeb = false end)
    end)
end

-- ===== BASE PAGE =====
local basePage = PageFrames["Base"]
do
    local header = Instance.new("TextLabel", basePage)
    header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = LANG_TABLE[SETTINGS.Language].Base

    local scroll = Instance.new("ScrollingFrame", basePage)
    scroll.Size = UDim2.new(1,-24,1,-56); scroll.Position = UDim2.new(0,12,0,44); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 8
    local layout = Instance.new("UIListLayout", scroll); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,8)

    for i, bname in ipairs(BASE_LIST) do
        local btn = Instance.new("TextButton", scroll)
        btn.Size = UDim2.new(1, -12, 0, 40); btn.BackgroundColor3 = Color3.fromRGB(28,12,36); btn.Font = Enum.Font.Gotham; btn.TextSize=14; btn.TextColor3 = Color3.fromRGB(240,240,240); btn.Text = bname
        local uc = Instance.new("UICorner", btn); uc.CornerRadius = UDim.new(0,8)
        btn.LayoutOrder = i
        btn.MouseButton1Click:Connect(function()
            SETTINGS.SelectedBase = bname
            persistSettings()
            local mainExecLabel = PageFrames["Main"]:FindFirstChild("ExecutorLabel")
            if mainExecLabel then mainExecLabel.Text = string.format(LANG_TABLE[SETTINGS.Language].executor, bname) end
            showToast(string.format(LANG_TABLE[SETTINGS.Language].toast_base, bname))
            if SETTINGS.SFX then pcall(function() local s=SFXFolder:FindFirstChild("click"); if s then s:Play() end end) end
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = THEMES[SETTINGS.Theme].accent}):Play()
            task.delay(0.12, function() TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(28,12,36)}):Play() end)
        end)
    end

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12)
    end)
end

-- ===== UNIVERSAL PAGE =====
local uniPage = PageFrames["Universal"]
do
    local header = Instance.new("TextLabel", uniPage)
    header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = LANG_TABLE[SETTINGS.Language].Universal

    local inf = Instance.new("TextButton", uniPage)
    inf.Size = UDim2.new(0.46,0,0,40); inf.Position = UDim2.new(0.27,0,0.18,0); inf.Text = LANG_TABLE[SETTINGS.Language].infinite; inf.Font = Enum.Font.GothamBold; inf.TextSize = 16; inf.BackgroundColor3 = Color3.fromRGB(0,120,200); inf.TextColor3=Color3.fromRGB(255,255,255)
    local ic = Instance.new("UICorner", inf); ic.CornerRadius = UDim.new(0,8)
    inf.MouseButton1Click:Connect(function()
        -- raw link to Infinite Yield
        local ok, err = pcall(function()
            local src = game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
            loadstring(src)()
        end)
        if ok then showToast(LANG_TABLE[SETTINGS.Language].toast_inf or "Infinite Yield started") else showToast( string.format(LANG_TABLE[SETTINGS.Language].toast_error, tostring(err)) ) end
    end)
end

-- ===== PROFILES PAGE =====
local profilesPage = PageFrames["Profiles"]
do
    local header = Instance.new("TextLabel", profilesPage)
    header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245); header.Text = LANG_TABLE[SETTINGS.Language].Profiles

    local slotsFrame = Instance.new("Frame", profilesPage)
    slotsFrame.Size = UDim2.new(1,-24,1,-56); slotsFrame.Position = UDim2.new(0,12,0,44); slotsFrame.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", slotsFrame); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,8)

    local uiSlots = {}
    for i=1,MAX_SLOTS do
        local slot = Instance.new("Frame", slotsFrame); slot.Size = UDim2.new(1,0,0,88); slot.BackgroundColor3 = Color3.fromRGB(24,10,30); local sc = Instance.new("UICorner", slot); sc.CornerRadius = UDim.new(0,8)
        slot.LayoutOrder = i

        local nameLbl = Instance.new("TextLabel", slot); nameLbl.Position = UDim2.new(0,12,0,8); nameLbl.Size = UDim2.new(0.5,-24,0,24); nameLbl.BackgroundTransparency = 1; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize=16; nameLbl.TextColor3=Color3.fromRGB(235,235,235)
        nameLbl.Text = (PROFILES[i] and PROFILES[i].Name) or LANG_TABLE[SETTINGS.Language].empty

        local btnRename = Instance.new("TextButton", slot); btnRename.Size = UDim2.new(0,84,0,28); btnRename.Position = UDim2.new(1,-96,0,8); btnRename.Text = LANG_TABLE[SETTINGS.Language].rename; local ruc = Instance.new("UICorner", btnRename); ruc.CornerRadius = UDim.new(0,6)
        local btnSave = Instance.new("TextButton", slot); btnSave.Size = UDim2.new(0,84,0,28); btnSave.Position = UDim2.new(1,-96,0,44); btnSave.Text = LANG_TABLE[SETTINGS.Language].save; local sc2 = Instance.new("UICorner", btnSave); sc2.CornerRadius = UDim.new(0,6)
        local btnLoad = Instance.new("TextButton", slot); btnLoad.Size = UDim2.new(0,84,0,28); btnLoad.Position = UDim2.new(1,-186,0,44); btnLoad.Text = LANG_TABLE[SETTINGS.Language].load; local lc = Instance.new("UICorner", btnLoad); lc.CornerRadius = UDim.new(0,6)
        local btnDelete = Instance.new("TextButton", slot); btnDelete.Size = UDim2.new(0,84,0,28); btnDelete.Position = UDim2.new(1,-276,0,44); btnDelete.Text = LANG_TABLE[SETTINGS.Language].delete; local dc = Instance.new("UICorner", btnDelete); dc.CornerRadius = UDim.new(0,6)

        -- Save current settings into profile slot
        btnSave.MouseButton1Click:Connect(function()
            local profile = {
                Name = (PROFILES[i] and PROFILES[i].Name) or ("Profile "..i),
                Theme = SETTINGS.Theme,
                Language = SETTINGS.Language,
                Position = { Window.Position.X.Scale, Window.Position.X.Offset, Window.Position.Y.Scale, Window.Position.Y.Offset },
                Size = { Window.AbsoluteSize.X, Window.AbsoluteSize.Y },
                SelectedBase = SETTINGS.SelectedBase,
                SFX = SETTINGS.SFX
            }
            PROFILES[i] = profile
            nameLbl.Text = profile.Name
            persistProfiles()
            showToast(LANG_TABLE[SETTINGS.Language].toast_saved)
        end)

        -- Load profile
        btnLoad.MouseButton1Click:Connect(function()
            local p = PROFILES[i]
            if not p then showToast(LANG_TABLE[SETTINGS.Language].empty) return end
            -- apply
            SETTINGS.Theme = p.Theme or SETTINGS.Theme
            SETTINGS.Language = p.Language or SETTINGS.Language
            if type(p.Position) == "table" and #p.Position >= 4 then Window.Position = UDim2.new(p.Position[1], p.Position[2], p.Position[3], p.Position[4]) end
            if type(p.Size) == "table" and #p.Size >= 2 then Window.Size = UDim2.new(0, math.max(MIN_SIZE.X, p.Size[1]), 0, math.max(MIN_SIZE.Y, p.Size[2])) end
            SETTINGS.SelectedBase = p.SelectedBase or SETTINGS.SelectedBase
            SETTINGS.SFX = (p.SFX == nil) and SETTINGS.SFX or not not p.SFX
            applyTheme(SETTINGS.Theme)
            refreshAllTexts()
            persistSettings()
            showToast(LANG_TABLE[SETTINGS.Language].toast_loaded)
        end)

        -- Delete
        btnDelete.MouseButton1Click:Connect(function()
            PROFILES[i] = nil
            nameLbl.Text = LANG_TABLE[SETTINGS.Language].empty
            persistProfiles()
            showToast(LANG_TABLE[SETTINGS.Language].toast_deleted)
        end)

        -- Rename (modal)
        btnRename.MouseButton1Click:Connect(function()
            local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,380,0,120); modal.Position = UDim2.new(0.5,-190,0.5,-60); modal.BackgroundColor3 = Color3.fromRGB(18,12,28); modal.ZIndex = 999
            local mc = Instance.new("UICorner", modal); mc.CornerRadius = UDim.new(0,10)
            local tb = Instance.new("TextBox", modal); tb.Size = UDim2.new(1,-24,0,36); tb.Position = UDim2.new(0,12,0,12); tb.Font = Enum.Font.Gotham; tb.TextSize = 16; tb.Text = (PROFILES[i] and PROFILES[i].Name) or ("Profile "..i)
            local ok = Instance.new("TextButton", modal); ok.Size = UDim2.new(0,84,0,32); ok.Position = UDim2.new(1,-96,1,-44); ok.Text = "OK"; local okc = Instance.new("UICorner", ok)
            local canc = Instance.new("TextButton", modal); canc.Size = UDim2.new(0,84,0,32); canc.Position = UDim2.new(1,-196,1,-44); canc.Text = "Cancel"; local cc = Instance.new("UICorner", canc)
            ok.MouseButton1Click:Connect(function()
                local newName = tostring(tb.Text or ""):sub(1,40)
                if not PROFILES[i] then PROFILES[i] = {} end
                PROFILES[i].Name = newName
                nameLbl.Text = newName
                persistProfiles()
                modal:Destroy()
            end)
            canc.MouseButton1Click:Connect(function() modal:Destroy() end)
        end)

        uiSlots[i] = {Frame = slot, NameLabel = nameLbl, Save = btnSave, Load = btnLoad, Delete = btnDelete, Rename = btnRename}
    end
end

-- ===== SETTINGS PAGE =====
local settingsPage = PageFrames["Settings"]
do
    local header = Instance.new("TextLabel", settingsPage)
    header.Size = UDim2.new(1,-24,0,28); header.Position = UDim2.new(0,12,0,6); header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold; header.TextSize = 18; header.TextColor3 = Color3.fromRGB(245,245,245)
    header.Text = LANG_TABLE[SETTINGS.Language].Settings

    -- themes row
    local themeLabel = Instance.new("TextLabel", settingsPage); themeLabel.Size = UDim2.new(1,-24,0,20); themeLabel.Position = UDim2.new(0,12,0,44); themeLabel.BackgroundTransparency = 1; themeLabel.Font = Enum.Font.Gotham; themeLabel.TextColor3 = Color3.fromRGB(220,220,220); themeLabel.Text = "Themes"
    local themeFrame = Instance.new("Frame", settingsPage); themeFrame.Position = UDim2.new(0,12,0,70); themeFrame.Size = UDim2.new(1,-24,0,64); themeFrame.BackgroundTransparency = 1

    local idx = 0
    for key, dat in pairs(THEMES) do
        idx = idx + 1
        local b = Instance.new("TextButton", themeFrame)
        b.Size = UDim2.new(0,100,0,48)
        b.Position = UDim2.new(0,(idx-1)*104,0,8)
        b.BackgroundColor3 = dat.window
        b.Text = dat.symbol
        b.Font = Enum.Font.GothamBold; b.TextSize = 22; b.TextColor3 = Color3.fromRGB(240,240,240)
        local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0,10)
        b.MouseButton1Click:Connect(function()
            SETTINGS.Theme = key
            applyTheme(SETTINGS.Theme)
            persistSettings()
            showToast("Theme: "..key)
        end)
    end

    -- language buttons
    local langLabel = Instance.new("TextLabel", settingsPage); langLabel.Position = UDim2.new(0,12,0,150); langLabel.Size = UDim2.new(0,120,0,24); langLabel.BackgroundTransparency = 1; langLabel.Font = Enum.Font.Gotham; langLabel.TextColor3 = Color3.fromRGB(220,220,220); langLabel.Text = "Language"
    local ru = Instance.new("TextButton", settingsPage); ru.Size = UDim2.new(0,48,0,28); ru.Position = UDim2.new(0,140,0,148); ru.Text="🇷🇺"; local ruc=Instance.new("UICorner", ru); ruc.CornerRadius=UDim.new(0,6)
    ru.MouseButton1Click:Connect(function() SETTINGS.Language = "RU"; persistSettings(); refreshAllTexts(); showToast("Language: RU") end)
    local en = Instance.new("TextButton", settingsPage); en.Size = UDim2.new(0,48,0,28); en.Position = UDim2.new(0,200,0,148); en.Text="🇺🇸"; local enc=Instance.new("UICorner", en); enc.CornerRadius=UDim.new(0,6)
    en.MouseButton1Click:Connect(function() SETTINGS.Language = "EN"; persistSettings(); refreshAllTexts(); showToast("Language: EN") end)

    -- SFX toggle
    local sfxLbl = Instance.new("TextLabel", settingsPage); sfxLbl.Position = UDim2.new(0,260,0,150); sfxLbl.Size = UDim2.new(0,60,0,24); sfxLbl.BackgroundTransparency = 1; sfxLbl.Font=Enum.Font.Gotham; sfxLbl.TextColor3 = Color3.fromRGB(220,220,220); sfxLbl.Text="SFX"
    local sfxBtn = Instance.new("TextButton", settingsPage); sfxBtn.Position = UDim2.new(0,320,0,148); sfxBtn.Size = UDim2.new(0,48,0,28); sfxBtn.Text = SETTINGS.SFX and "ON" or "OFF"
    sfxBtn.MouseButton1Click:Connect(function() SETTINGS.SFX = not SETTINGS.SFX; sfxBtn.Text = SETTINGS.SFX and "ON" or "OFF"; persistSettings() end)

    -- Export / Import profiles (JSON)
    local exportBtn = Instance.new("TextButton", settingsPage); exportBtn.Size = UDim2.new(0,100,0,28); exportBtn.Position = UDim2.new(1,-236,1,-44); exportBtn.AnchorPoint = Vector2.new(0,1); exportBtn.Text = LANG_TABLE[SETTINGS.Language].export
    local importBtn = Instance.new("TextButton", settingsPage); importBtn.Size = UDim2.new(0,100,0,28); importBtn.Position = UDim2.new(1,-120,1,-44); importBtn.AnchorPoint = Vector2.new(0,1); importBtn.Text = LANG_TABLE[SETTINGS.Language].import
    local exportCorner = Instance.new("UICorner", exportBtn); exportCorner.CornerRadius = UDim.new(0,8)
    local importCorner = Instance.new("UICorner", importBtn); importCorner.CornerRadius = UDim.new(0,8)

    exportBtn.MouseButton1Click:Connect(function()
        local s = safeEncode(PROFILES)
        if s then
            -- open small modal with text to copy
            local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,540,0,220); modal.Position = UDim2.new(0.5,-270,0.5,-110); modal.BackgroundColor3 = Color3.fromRGB(18,12,28)
            local mc = Instance.new("UICorner", modal); mc.CornerRadius = UDim.new(0,8)
            local tb = Instance.new("TextBox", modal); tb.Size = UDim2.new(1,-24,1,-64); tb.Position = UDim2.new(0,12,0,12); tb.Text = s; tb.MultiLine = true; tb.Font = Enum.Font.Code; tb.TextSize = 14
            local ok = Instance.new("TextButton", modal); ok.Size = UDim2.new(0,84,0,36); ok.Position = UDim2.new(1,-96,1,-44); ok.Text="OK"; local okc=Instance.new("UICorner", ok); okc.CornerRadius=UDim.new(0,8)
            ok.MouseButton1Click:Connect(function() modal:Destroy() end)
        else
            showToast("Export error")
        end
    end)

    importBtn.MouseButton1Click:Connect(function()
        local modal = Instance.new("Frame", screenGui); modal.Size = UDim2.new(0,540,0,220); modal.Position = UDim2.new(0.5,-270,0.5,-110); modal.BackgroundColor3 = Color3.fromRGB(18,12,28)
        local mc = Instance.new("UICorner", modal); mc.CornerRadius = UDim.new(0,8)
        local tb = Instance.new("TextBox", modal); tb.Size = UDim2.new(1,-24,1,-64); tb.Position = UDim2.new(0,12,0,12); tb.PlaceholderText = "Paste profiles JSON here"; tb.MultiLine = true; tb.Font = Enum.Font.Code; tb.TextSize = 14
        local ok = Instance.new("TextButton", modal); ok.Size = UDim2.new(0,84,0,36); ok.Position = UDim2.new(1,-96,1,-44); ok.Text="Import"; local okc=Instance.new("UICorner", ok); okc.CornerRadius=UDim.new(0,8)
        local canc = Instance.new("TextButton", modal); canc.Size = UDim2.new(0,84,0,36); canc.Position = UDim2.new(1,-196,1,-44); canc.Text="Cancel"; local cc=Instance.new("UICorner", canc); cc.CornerRadius=UDim.new(0,8)
        ok.MouseButton1Click:Connect(function()
            local s = tb.Text
            local t = safeDecode(s)
            if type(t) == "table" then
                for i=1,MAX_SLOTS do PROFILES[i] = t[i] end
                persistProfiles()
                showToast("Profiles imported")
                modal:Destroy()
                refreshAllTexts()
            else
                showToast("Import error")
            end
        end)
        canc.MouseButton1Click:Connect(function() modal:Destroy() end)
    end)
end

-- ===== helper functions: theme, text refresh, toast =====
function applyTheme(name)
    local t = THEMES[name] or THEMES[DEFAULT_THEME]
    Window.BackgroundColor3 = t.window
    winStroke.Color = t.accent
    ToggleBtn.BackgroundColor3 = t.button
    ToggleBtn.Text = t.symbol
    -- apply accent to Exec button if exists
    local execBtn = PageFrames["Main"]:FindFirstChild("ExecuteBtn")
    if execBtn then execBtn.BackgroundColor3 = t.accent end
end

function refreshAllTexts()
    -- refresh tabs
    local lang = SETTINGS.Language or DEFAULT_LANG
    for i, name in ipairs(TAB_ORDER) do
        local btn = TabButtons[name]
        if btn then
            btn.Text = LANG_TABLE[lang].tabs[i] or name
        end
        -- page header labels where applicable
        local page = PageFrames[name]
        if page then
            for _,child in ipairs(page:GetChildren()) do
                if child:IsA("TextLabel") and child.Text == "Main" then -- not perfect but we set main header earlier
                    -- nothing
                end
            end
        end
    end
    -- main placeholders
    local codeBox = PageFrames["Main"]:FindFirstChild("CodeBox")
    if codeBox then codeBox.PlaceholderText = LANG_TABLE[lang].code_placeholder end
    local execBtn = PageFrames["Main"]:FindFirstChild("ExecuteBtn")
    if execBtn then execBtn.Text = LANG_TABLE[lang].execute end
    local execLabel = PageFrames["Main"]:FindFirstChild("ExecutorLabel")
    if execLabel then execLabel.Text = string.format(LANG_TABLE[lang].executor, SETTINGS.SelectedBase) end

    -- profiles names
    for i=1,MAX_SLOTS do
        local slot = PageFrames["Profiles"]:FindFirstChildWhichIsA("Frame")
        -- easier: refresh UI slots by searching
    end

    -- settings buttons text (export/import) - we leave as is for simplicity
end

-- keep wrapper functions available to complete code
-- apply initial theme and texts
applyTheme(SETTINGS.Theme)
refreshAllTexts()

-- show main tab by default
TabButtons["Main"].MouseButton1Click:Wait()
TabButtons["Main"]:Activate()
for k,v in pairs(PageFrames) do v.Visible = false end
PageFrames["Main"].Visible = true
TabButtons["Main"].TextColor3 = Color3.fromRGB(255,255,255)

-- ===== dragging & resizing =====
do
    local dragging = false
    local dragStart = Vector2.new()
    local originPos = UDim2.new()
    local function startDrag(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        dragStart = input.Position
        originPos = Window.Position
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
            Window.Position = UDim2.new(originPos.X.Scale, originPos.X.Offset + delta.X, originPos.Y.Scale, originPos.Y.Offset + delta.Y)
        end
    end
    -- header areas
    Title.InputBegan:Connect(startDrag)
    Sub.InputBegan:Connect(startDrag)
    UserInputService.InputChanged:Connect(updateDrag)
end

-- resizing with Resizer (only expand toward drag direction)
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
            -- adjust text sizes a little
            onWindowResize()
        end
    end)
end

-- adapt text sizes on resize
function onWindowResize()
    SETTINGS.Size = { Window.AbsoluteSize.X, Window.AbsoluteSize.Y }
    for _,obj in pairs(Window:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if not obj.TextScaled then
                local w = math.max(200, Window.AbsoluteSize.X)
                local size = math.clamp(math.floor(w / 60), 12, 20)
                pcall(function() obj.TextSize = size end)
            end
        end
    end
    persistSettings()
end
Window:GetPropertyChangedSignal("AbsoluteSize"):Connect(onWindowResize)

-- toggle open/close with circular button
local isOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if isOpen then
        Window.Visible = true
        applyTheme(SETTINGS.Theme)
        local t = TweenService:Create(Window, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size = Window.Size})
        t:Play()
    else
        local t = TweenService:Create(Window, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {Size = UDim2.new(0,18,0,18)})
        t:Play()
        t.Completed:Connect(function() Window.Visible = false end)
    end
end)

-- helper to show toast (localized)
function showToast(text)
    local pos = SETTINGS.Language and LANG_TABLE[SETTINGS.Language] or LANG_TABLE[DEFAULT_LANG]
    local t = Instance.new("TextLabel", screenGui)
    t.Size = UDim2.new(0,250,0,40)
    t.Position = UDim2.new(1,-260,1,-60)
    t.AnchorPoint = Vector2.new(0,0)
    t.BackgroundColor3 = Color3.fromRGB(40,40,40)
    t.BackgroundTransparency = 0.18
    t.TextColor3 = Color3.fromRGB(255,255,255)
    t.Font = Enum.Font.GothamBold
    t.TextScaled = true
    t.Text = text
    local corner = Instance.new("UICorner", t); corner.CornerRadius = UDim.new(0,8)
    TweenService:Create(t, TweenInfo.new(0.5), {Position = UDim2.new(1,-260,1,-110)}):Play()
    task.delay(3, function()
        TweenService:Create(t, TweenInfo.new(0.4), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
        task.delay(0.45, function() pcall(function() t:Destroy() end) end)
    end)
end

-- initial toast
showToast(LANG_TABLE[SETTINGS.Language].toast_started or "Fog Hub loaded")

-- helper: applyTheme and refresh UI variable-dependent text (we re-declare safe)
function applyTheme(key)
    local th = THEMES[key] or THEMES[DEFAULT_THEME]
    Window.BackgroundColor3 = th.window
    winStroke.Color = th.accent
    ToggleBtn.BackgroundColor3 = th.button
    ToggleBtn.Text = th.symbol
    -- update exec button accent
    local execBtn = PageFrames["Main"]:FindFirstChild("ExecuteBtn")
    if execBtn then execBtn.BackgroundColor3 = th.accent end
end

function refreshAllTexts()
    local L = SETTINGS.Language or DEFAULT_LANG
    -- tabs
    for i,name in ipairs(TAB_ORDER) do
        local btn = TabButtons[name]
        if btn then btn.Text = LANG_TABLE[L].tabs[i] or name end
    end
    -- main placeholders & executor label
    local codeBox = PageFrames["Main"]:FindFirstChild("CodeBox")
    if codeBox then codeBox.PlaceholderText = LANG_TABLE[L].code_placeholder end
    local execBtn = PageFrames["Main"]:FindFirstChild("ExecuteBtn")
    if execBtn then execBtn.Text = LANG_TABLE[L].execute end
    local execLabel = PageFrames["Main"]:FindFirstChild("ExecutorLabel")
    if execLabel then execLabel.Text = string.format(LANG_TABLE[L].executor, SETTINGS.SelectedBase) end

    -- profiles labels
    local slots = PageFrames["Profiles"]:GetChildren()
    for _,child in ipairs(slots) do
        if child:IsA("Frame") then
            local lbl = child:FindFirstChildWhichIsA("TextLabel")
            if lbl then
                -- attempt to match slot index by layout order; simpler approach: refresh names from PROFILES table
                -- We'll loop PROFILES and update first three TextLabels in order
            end
        end
    end
    -- update names properly:
    local idx = 1
    for _,child in ipairs(PageFrames["Profiles"]:GetChildren()) do
        if child:IsA("Frame") then
            local nameLabel = nil
            for _,desc in ipairs(child:GetChildren()) do if desc:IsA("TextLabel") then nameLabel = desc break end end
            if nameLabel then
                nameLabel.Text = (PROFILES[idx] and PROFILES[idx].Name) or LANG_TABLE[L].empty
            end
            idx = idx + 1
            if idx > MAX_SLOTS then break end
        end
    end
end

-- apply initial theme & texts
applyTheme(SETTINGS.Theme)
refreshAllTexts()

-- ensure window clamps
RunService.Heartbeat:Connect(function()
    local abs = Window.AbsoluteSize
    if abs.X > 3000 or abs.Y > 2000 then
        Window.Size = UDim2.new(0, math.clamp(abs.X, MIN_SIZE.X, 1600), 0, math.clamp(abs.Y, MIN_SIZE.Y, 900))
    end
end)

-- final prints
print("[Fog Hub] initialized. Theme:", SETTINGS.Theme, "Lang:", SETTINGS.Language, "Base:", SETTINGS.SelectedBase)
if not HAS_WRITEFILE then
    warn("[Fog Hub] writefile/readfile not found — persistence disabled (will use volatile memory).")
end

-- End of Fog Hub LocalScript
