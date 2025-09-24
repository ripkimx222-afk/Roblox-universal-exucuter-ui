local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "UniversalExecutorUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local function make(obj, props, parent)
    local inst = Instance.new(obj)
    for k,v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

-- Toggle button
local toggle = make("TextButton", {
    Size = UDim2.new(0,70,0,70),
    Position = UDim2.new(0,20,0.8,0),
    BackgroundColor3 = Color3.fromRGB(120,60,210),
    Text = "toggle",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Draggable = true
}, gui)
make("UICorner",{CornerRadius=UDim.new(1,0)},toggle)

-- Main window
local main = make("Frame",{
    Size = UDim2.new(0,540,0,440),
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.new(0.5,0,0.5,0),
    BackgroundColor3 = Color3.fromRGB(40,10,100),
    Visible = false
},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},main)

-- Top bar
local topbar = make("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(30,0,70)},main)
make("UICorner",{CornerRadius=UDim.new(0,16)},topbar)
local title = make("TextLabel",{
    Text="Universal Executor",
    Size=UDim2.new(1,-100,1,0),
    BackgroundTransparency=1,
    Font=Enum.Font.GothamBold,
    TextSize=18,
    TextColor3=Color3.new(1,1,1),
    TextXAlignment=Enum.TextXAlignment.Left,
    Position=UDim2.new(0,10,0,0)
},topbar)

local closeBtn = make("TextButton",{
    Text="X",Size=UDim2.new(0,40,0,40),
    BackgroundTransparency=1,
    TextColor3=Color3.new(1,0.3,0.3),
    Font=Enum.Font.GothamBold,
    TextSize=20,
    Position=UDim2.new(1,-40,0,0)
},topbar)

-- Tabs
local tabFrame = make("Frame",{Size=UDim2.new(0,120,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=Color3.fromRGB(25,0,60)},main)
local contentFrame = make("Frame",{Size=UDim2.new(1,-120,1,-40),Position=UDim2.new(0,120,0,40),BackgroundColor3=Color3.fromRGB(50,20,120)},main)
make("UICorner",{CornerRadius=UDim.new(0,12)},contentFrame)

local tabs = {}
local currentTab = nil

local function addTab(name)
    local btn = make("TextButton",{
        Size=UDim2.new(1,0,0,40),
        BackgroundColor3=Color3.fromRGB(80,40,160),
        Text=name,
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.Gotham,
        TextSize=16
    },tabFrame)
    local frame = make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},contentFrame)
    tabs[name] = {button=btn,frame=frame}
    btn.MouseButton1Click:Connect(function()
        if currentTab then tabs[currentTab].frame.Visible=false end
        currentTab = name
        frame.Visible = true
        for _,t in pairs(tabs) do
            t.button.BackgroundColor3 = Color3.fromRGB(80,40,160)
        end
        btn.BackgroundColor3 = Color3.fromRGB(150,90,220)
    end)
    return frame
end

-- Tab: Injector
local injectorTab = addTab("Injector")
local execBox = make("TextBox",{
    Size=UDim2.new(1,-40,1,-100),
    Position=UDim2.new(0,20,0,20),
    BackgroundColor3=Color3.fromRGB(25,0,50),
    Text="",
    TextWrapped=true,
    ClearTextOnFocus=false,
    TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.Code,
    TextSize=16,
    MultiLine=true
},injectorTab)
make("UICorner",{CornerRadius=UDim.new(0,8)},execBox)

local execBtn = make("TextButton",{
    Size=UDim2.new(0,120,0,40),
    Position=UDim2.new(0.5,-60,1,-60),
    BackgroundColor3=Color3.fromRGB(150,90,220),
    Text="Execute",
    TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold,
    TextSize=18
},injectorTab)
make("UICorner",{CornerRadius=UDim.new(0,8)},execBtn)

local execStatus = make("TextLabel",{
    Size=UDim2.new(1,0,0,30),
    Position=UDim2.new(0,0,1,-30),
    BackgroundTransparency=1,
    Text="",
    TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.Gotham,
    TextSize=14
},injectorTab)

-- Tab: Bases
local basesTab = addTab("Bases")
local bases = {"XENO","DELTA X","KRNL","Arceus X","Fluxus"}
local baseButtons = {}
local selectedBase = "XENO"
for i,base in ipairs(bases) do
    local b = make("TextButton",{
        Size=UDim2.new(1,-40,0,40),
        Position=UDim2.new(0,20,0,(i-1)*50+20),
        BackgroundColor3=Color3.fromRGB(95,45,170),
        Text=base,
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.Gotham,
        TextSize=16
    },basesTab)
    make("UICorner",{CornerRadius=UDim.new(0,8)},b)
    baseButtons[#baseButtons+1]=b
end

-- Tab: Settings (Transparency + RGB sliders)
local settingsTab = addTab("Settings")

local function slider(name, posY, min, max, default, callback)
    local label = make("TextLabel",{
        Size=UDim2.new(0,80,0,30),
        Position=UDim2.new(0,20,0,posY),
        BackgroundTransparency=1,
        Text=name,
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.Gotham,
        TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left
    },settingsTab)
    local box = make("TextBox",{
        Size=UDim2.new(0,60,0,30),
        Position=UDim2.new(0,100,0,posY),
        BackgroundColor3=Color3.fromRGB(80,40,160),
        Text=tostring(default),
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.Code,
        TextSize=14
    },settingsTab)
    make("UICorner",{CornerRadius=UDim.new(0,6)},box)
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            val = math.clamp(val,min,max)
            callback(val)
        end
    end)
    return box
end

local transBox = slider("Transparency",20,0,1,0,function(v) main.BackgroundTransparency=v end)
local rBox = slider("Red",60,0,255,40,function(v) main.BackgroundColor3=Color3.fromRGB(v,main.BackgroundColor3.G*255,main.BackgroundColor3.B*255) end)
local gBox = slider("Green",100,0,255,10,function(v) main.BackgroundColor3=Color3.fromRGB(main.BackgroundColor3.R*255,v,main.BackgroundColor3.B*255) end)
local bBox = slider("Blue",140,0,255,100,function(v) main.BackgroundColor3=Color3.fromRGB(main.BackgroundColor3.R*255,main.BackgroundColor3.G*255,v) end)

-- Executors
local executors = {
    ["XENO"] = function(code)
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
            loadstring(code)()
            return "XENO"
        else
            loadstring(code)()
            return "Fallback"
        end
    end,
    ["DELTA X"] = function(code)
        if delta and delta.execute then
            delta.execute(code)
            return "DELTA X"
        else
            loadstring(code)()
            return "Fallback"
        end
    end,
    ["KRNL"] = function(code)
        if KRNL and KRNL.execute then
            KRNL.execute(code)
            return "KRNL"
        else
            loadstring(code)()
            return "Fallback"
        end
    end,
    ["Arceus X"] = function(code)
        if ArceusX and ArceusX.execute then
            ArceusX.execute(code)
            return "Arceus X"
        else
            loadstring(code)()
            return "Fallback"
        end
    end,
    ["Fluxus"] = function(code)
        if fluxus and fluxus.execute then
            fluxus.execute(code)
            return "Fluxus"
        else
            loadstring(code)()
            return "Fallback"
        end
    end
}

execBtn.MouseButton1Click:Connect(function()
    local code = execBox.Text
    local executor = executors[selectedBase]
    if executor then
        execStatus.Text = "Выполняется..."
        local used = executor(code)
        execStatus.Text = "Готово! Используется: "..used
    else
        execStatus.Text = "Неподдерживаемая база"
    end
end)

for _, button in ipairs(baseButtons) do
    button.MouseButton1Click:Connect(function()
        selectedBase = button.Text
        for _, b in ipairs(baseButtons) do
            b.BackgroundColor3 = (b == button) and Color3.fromRGB(150,90,220) or Color3.fromRGB(95,45,170)
        end
    end)
end

-- Open/close with animation
local function openUI()
    main.Visible = true
    main.Size = UDim2.new(0,0,0,0)
    main.Position = UDim2.new(0.5,0,0.5,0)
    TweenService:Create(main,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,540,0,440)}):Play()
end
local function closeUI()
    TweenService:Create(main,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.2)
    main.Visible=false
end

toggle.MouseButton1Click:Connect(function()
    if main.Visible then
        closeUI()
    else
        openUI()
    end
end)
closeBtn.MouseButton1Click:Connect(function() closeUI() end)

-- Default tab
tabs["Injector"].frame.Visible=true
currentTab="Injector"
tabs["Injector"].button.BackgroundColor3=Color3.fromRGB(150,90,220)
