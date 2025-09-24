local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function New(class, props, parent)
	local obj = Instance.new(class)
	if props then for k,v in pairs(props) do obj[k] = v end end
	if parent then obj.Parent = parent end
	return obj
end

local screen = New("ScreenGui", {Name = "UniversalExecutorUI_final", ResetOnSpawn = false, IgnoreGuiInset = true}, playerGui)

local DEFAULT_W, DEFAULT_H = 760, 520
local MIN_W, MIN_H = 360, 260
local MAX_W, MAX_H = 1400, 980

local Themes = {
	["Purple Black"] = {
		Background = Color3.fromRGB(34,18,90),
		Accent = Color3.fromRGB(150,90,220),
		Text = Color3.fromRGB(245,245,255)
	},
	["Pay to Win"] = {
		Background = Color3.fromRGB(10,10,10),
		Accent = Color3.fromRGB(255,220,0),
		Text = Color3.fromRGB(255,255,230)
	},
	["Cyber Blue"] = {
		Background = Color3.fromRGB(12,16,28),
		Accent = Color3.fromRGB(0,180,255),
		Text = Color3.fromRGB(200,240,255)
	},
	["Pastel Dream"] = {
		Background = Color3.fromRGB(245,230,255),
		Accent = Color3.fromRGB(255,150,200),
		Text = Color3.fromRGB(40,40,60)
	},
	["Neo Mint"] = {
		Background = Color3.fromRGB(8,20,18),
		Accent = Color3.fromRGB(120,255,200),
		Text = Color3.fromRGB(220,255,240)
	}
}
local CurrentTheme = "Purple Black"

local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
local main = New("Frame", {
	Size = UDim2.new(0, DEFAULT_W, 0, DEFAULT_H),
	Position = UDim2.new(0, math.floor((vp.X - DEFAULT_W)/2), 0, math.floor((vp.Y - DEFAULT_H)/2)),
	AnchorPoint = Vector2.new(0,0),
	BackgroundColor3 = Themes[CurrentTheme].Background,
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	ZIndex = 90,
	Visible = true,
	ClipsDescendants = true
}, screen)
New("UICorner", {CornerRadius = UDim.new(0,16)}, main)
New("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(98,40,210)), ColorSequenceKeypoint.new(1, Color3.fromRGB(35,10,120))}, Rotation = 24}, main)

local bgTile = New("ImageLabel", {Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Image = "rbxassetid://3570695787", ImageTransparency = 0.92, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.new(0,72,0,72), ZIndex = 88}, main)

local topBar = New("Frame", {Parent = main, Size = UDim2.new(1,0,0,56), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1})
local title = New("TextLabel", {Parent = topBar, Size = UDim2.new(0.6, -24, 1, 0), Position = UDim2.new(0, 16, 0, 0), BackgroundTransparency = 1, Text = "Electron", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Themes[CurrentTheme].Text, TextXAlignment = Enum.TextXAlignment.Left})
local subtitle = New("TextLabel", {Parent = topBar, Size = UDim2.new(0.4, -24, 1, 0), Position = UDim2.new(0.6, 12, 0, 0), BackgroundTransparency = 1, Text = "by Hikmes0", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Themes[CurrentTheme].Text, TextXAlignment = Enum.TextXAlignment.Right})

local btnClose = New("TextButton", {Parent = topBar, Size = UDim2.new(0,36,0,36), Position = UDim2.new(1,-46,0,10), AnchorPoint = Vector2.new(1,0), BackgroundColor3 = Color3.fromRGB(200,60,80), Text = "✕", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1,1,1)}, topBar)
New("UICorner", {CornerRadius = UDim.new(0,10)}, btnClose)
local btnMin = New("TextButton", {Parent = topBar, Size = UDim2.new(0,36,0,36), Position = UDim2.new(1,-92,0,10), AnchorPoint = Vector2.new(1,0), BackgroundColor3 = Color3.fromRGB(100,100,100), Text = "—", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1,1,1)}, topBar)
New("UICorner", {CornerRadius = UDim.new(0,10)}, btnMin)

local leftTabs = New("Frame", {Parent = main, Size = UDim2.new(0,160,1,-72), Position = UDim2.new(0,12,0,64), BackgroundTransparency = 1})
local contentArea = New("Frame", {Parent = main, Size = UDim2.new(1,-200,1,-72), Position = UDim2.new(0,188,0,64), BackgroundTransparency = 1})
New("UICorner", {CornerRadius = UDim.new(0,12)}, contentArea)

local function MakeTabButton(text, y)
	local b = New("TextButton", {Parent = leftTabs, Size = UDim2.new(1,0,0,44), Position = UDim2.new(0,0,0,y), BackgroundColor3 = Color3.fromRGB(75,34,160), BorderSizePixel = 0, Font = Enum.Font.Gotham, Text = text, TextSize = 16, TextColor3 = Color3.fromRGB(245,245,245)})
	New("UICorner", {CornerRadius = UDim.new(0,10)}, b)
	return b
end

local tabMainBtn = MakeTabButton("Main", 0)
local tabExecBtn = MakeTabButton("Executors", 56)
local tabSettingsBtn = MakeTabButton("Settings", 112)
local tabDiscBtn = MakeTabButton("Disclaimer", 168)
local tabIndicator = New("Frame", {Parent = leftTabs, Size = UDim2.new(0,6,0,44), Position = UDim2.new(0,0,0,0), BackgroundColor3 = Themes[CurrentTheme].Accent})
New("UICorner", {CornerRadius = UDim.new(0,6)}, tabIndicator)

local pages = {}
for i = 1, 4 do
	pages[i] = New("Frame", {Parent = contentArea, Size = UDim2.new(1,0,1,0), Position = UDim2.new(1,0,0,0), BackgroundTransparency = 1, Visible = false})
end
pages[1].Visible = true
pages[1].Position = UDim2.new(0,0,0,0)

local function switchTab(btn, index)
	for i = 1, #pages do
		local p = pages[i]
		if i == index then
			p.Visible = true
			p.Position = UDim2.new(1,0,0,0)
			TweenService:Create(p, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()
		else
			if p.Visible then
				TweenService:Create(p, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(-1,0,0,0)}):Play()
				task.delay(0.16, function() p.Visible = false end)
			end
		end
	end
	TweenService:Create(tabIndicator, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {Position = UDim2.new(0,0,0,btn.Position.Y.Offset)}):Play()
	for _, tb in ipairs({tabMainBtn, tabExecBtn, tabSettingsBtn, tabDiscBtn}) do
		tb.BackgroundColor3 = (tb == btn) and Themes[CurrentTheme].Accent or Color3.fromRGB(75,34,160)
	end
end

tabMainBtn.MouseButton1Click:Connect(function() switchTab(tabMainBtn, 1) end)
tabExecBtn.MouseButton1Click:Connect(function() switchTab(tabExecBtn, 2) end)
tabSettingsBtn.MouseButton1Click:Connect(function() switchTab(tabSettingsBtn, 3) end)
tabDiscBtn.MouseButton1Click:Connect(function() switchTab(tabDiscBtn, 4) end)

local mainPage = pages[1]
local codeBox = New("TextBox", {
	Parent = mainPage,
	Size = UDim2.new(1, -36, 1, -120),
	Position = UDim2.new(0, 18, 0, 12),
	BackgroundColor3 = Color3.fromRGB(28,12,65),
	BackgroundTransparency = 0,
	MultiLine = true,
	ClearTextOnFocus = false,
	TextWrapped = true,
	Font = Enum.Font.Code,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(245,245,255),
	PlaceholderText = "Paste Lua here..."
})
New("UICorner", {CornerRadius = UDim.new(0,10)}, codeBox)

local executeButton = New("TextButton", {
	Parent = mainPage,
	Size = UDim2.new(0, 140, 0, 44),
	Position = UDim2.new(0, 18, 1, -64),
	BackgroundColor3 = Themes[CurrentTheme].Accent,
	Font = Enum.Font.GothamBold,
	Text = "Execute",
	TextSize = 16,
	TextColor3 = Themes[CurrentTheme].Text
})
New("UICorner", {CornerRadius = UDim.new(0,10)}, executeButton)

local statusLabel = New("TextLabel", {
	Parent = mainPage,
	Size = UDim2.new(1, -200, 0, 26),
	Position = UDim2.new(0, 170, 1, -54),
	BackgroundTransparency = 1,
	Text = "Status: Ready",
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextColor3 = Color3.fromRGB(220,220,240),
	TextXAlignment = Enum.TextXAlignment.Left
})

local execPage = pages[2]
local bases = {"XENO", "DELTA X", "KRNL", "Arceus X", "Fluxus"}
local baseButtons = {}
local selectedBase = bases[1]

local function isAvailable(name)
	if name == "XENO" then return (type(syn) ~= "nil") end
	if name == "DELTA X" then return (type(delta) ~= "nil") end
	if name == "KRNL" then return (type(KRNL) ~= "nil") end
	if name == "Arceus X" then return (type(ArceusX) ~= "nil") end
	if name == "Fluxus" then return (type(fluxus) ~= "nil") end
	return false
end

for i, name in ipairs(bases) do
	local btn = New("TextButton", {
		Parent = execPage,
		Size = UDim2.new(1, -28, 0, 44),
		Position = UDim2.new(0, 14, 0, (i-1)*54 + 14),
		BackgroundColor3 = Color3.fromRGB(95,45,170),
		Font = Enum.Font.Gotham,
		TextSize = 16,
		TextColor3 = Color3.new(1,1,1)
	})
	New("UICorner", {CornerRadius = UDim.new(0,8)}, btn)
	if not isAvailable(name) then
		btn.Text = name .. " (not available)"
		btn.BackgroundColor3 = Color3.fromRGB(70,40,80)
		btn.AutoButtonColor = false
	else
		btn.Text = name
	end
	table.insert(baseButtons, btn)
	btn.MouseButton1Click:Connect(function()
		if not isAvailable(name) then
			selectedBase = "XENO"
			statusLabel.Text = "Status: chosen unavailable -> default XENO"
			for _, b in ipairs(baseButtons) do b.BackgroundColor3 = Color3.fromRGB(95,45,170) end
			for _, b in ipairs(baseButtons) do
				if b.Text:match("^XENO") then b.BackgroundColor3 = Themes[CurrentTheme].Accent; break end
			end
			switchTab(tabMainBtn, 1)
			return
		end
		selectedBase = name
		for _, b in ipairs(baseButtons) do b.BackgroundColor3 = Color3.fromRGB(95,45,170) end
		btn.BackgroundColor3 = Themes[CurrentTheme].Accent
		statusLabel.Text = "Status: selected base: " .. selectedBase
		switchTab(tabMainBtn, 1)
	end)
end

local settingsPage = pages[3]

local function MakeSlider(parent, y, labelText, minv, maxv, init)
	local holder = New("Frame", {Parent = parent, Size = UDim2.new(1, -28, 0, 44), Position = UDim2.new(0, 14, 0, y), BackgroundTransparency = 1})
	local label = New("TextLabel", {Parent = holder, Size = UDim2.new(0.34, 0, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, Text = labelText, TextColor3 = Color3.fromRGB(235,235,240), TextXAlignment = Enum.TextXAlignment.Left})
	local valBox = New("TextBox", {Parent = holder, Size = UDim2.new(0.12, 0, 0.64, 0), Position = UDim2.new(0.86, 0, 0.18, 0), BackgroundColor3 = Color3.fromRGB(26,12,60), BackgroundTransparency = 0.04, ClearTextOnFocus = false, Text = tostring(init), Font = Enum.Font.Code, TextSize = 14, TextColor3 = Color3.fromRGB(240,240,240), TextXAlignment = Enum.TextXAlignment.Center})
	New("UICorner", {CornerRadius = UDim.new(0,6)}, valBox)
	local rail = New("Frame", {Parent = holder, Size = UDim2.new(0.5, 0, 0, 12), Position = UDim2.new(0.36, 0, 0.5, -6), BackgroundColor3 = Color3.fromRGB(58,24,140), BorderSizePixel = 0})
	New("UICorner", {CornerRadius = UDim.new(0,8)}, rail)
	local knob = New("Frame", {Parent = rail, Size = UDim2.new((init-minv)/(maxv-minv), 0, 1, 0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = Themes[CurrentTheme].Accent})
	New("UICorner", {CornerRadius = UDim.new(0,8)}, knob)
	local dragging = false
	local inputRef = nil
	local function setFromX(x)
		local absX = math.clamp(x - rail.AbsolutePosition.X, 0, rail.AbsoluteSize.X)
		local frac = absX / math.max(1, rail.AbsoluteSize.X)
		local value = minv + frac * (maxv - minv)
		knob.Size = UDim2.new(frac, 0, 1, 0)
		valBox.Text = ("%d"):format(math.floor(value + 0.5))
		return value
	end
	rail.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			inputRef = input
			setFromX(input.Position.X)
		end
	end)
	rail.InputChanged:Connect(function(input)
		if dragging and input == inputRef then
			setFromX(input.Position.X)
		end
	end)
	rail.InputEnded:Connect(function(input)
		if input == inputRef then dragging = false; inputRef = nil end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == inputRef then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				setFromX(input.Position.X)
			end
		end
	end)
	valBox.FocusLost:Connect(function()
		local num = tonumber(valBox.Text) or init
		num = math.clamp(num, minv, maxv)
		local frac = (num - minv) / (maxv - minv)
		knob.Size = UDim2.new(frac, 0, 1, 0)
		valBox.Text = ("%d"):format(num)
	end)
	return {
		get = function() return tonumber(valBox.Text) or init end,
		set = function(v) valBox.Text = tostring(math.floor(math.clamp(v, minv, maxv) + 0.5)); local frac = (math.clamp(v, minv, maxv) - minv) / (maxv - minv); knob.Size = UDim2.new(frac, 0, 1, 0) end,
		isDragging = function() return dragging end,
		_knob = knob
	}
end

local rSlider = MakeSlider(settingsPage, 12, "Red", 0, 255, 34)
local gSlider = MakeSlider(settingsPage, 70, "Green", 0, 255, 18)
local bSlider = MakeSlider(settingsPage, 128, "Blue", 0, 255, 90)
local aSlider = MakeSlider(settingsPage, 186, "Opacity (%)", 0, 100, math.floor((1 - main.BackgroundTransparency) * 100))
local focusOffsetSlider = MakeSlider(settingsPage, 244, "Focus Offset (px)", -360, 360, -80)

local previewBox = New("Frame", {Parent = settingsPage, Size = UDim2.new(0, 260, 0, 120), Position = UDim2.new(1, -280, 0, 14), BackgroundColor3 = main.BackgroundColor3, BackgroundTransparency = main.BackgroundTransparency})
New("UICorner", {CornerRadius = UDim.new(0,10)}, previewBox)
local applyBtn = New("TextButton", {Parent = settingsPage, Size = UDim2.new(0,140,0,36), Position = UDim2.new(1, -280, 0, 148), BackgroundColor3 = Themes[CurrentTheme].Accent, Text = "Apply", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Themes[CurrentTheme].Text})
New("UICorner", {CornerRadius = UDim.new(0,8)}, applyBtn)

local focusToggle = New("TextButton", {Parent = settingsPage, Size = UDim2.new(0, 140, 0, 32), Position = UDim2.new(1, -280, 0, 188), BackgroundColor3 = Color3.fromRGB(70,70,70), Text = "Focus offset: OFF", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(240,240,240)})
New("UICorner", {CornerRadius = UDim.new(0,8)}, focusToggle)

local resetPosBtn = New("TextButton", {Parent = settingsPage, Size = UDim2.new(0, 140, 0, 32), Position = UDim2.new(1, -280, 0, 228), BackgroundColor3 = Color3.fromRGB(95,45,170), Text = "Reset position", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.new(1,1,1)})
New("UICorner", {CornerRadius = UDim.new(0,8)}, resetPosBtn)

local langToggle = New("TextButton", {Parent = settingsPage, Size = UDim2.new(0,140,0,32), Position = UDim2.new(1,-280,0,268), BackgroundColor3 = Color3.fromRGB(95,45,170), Text = "Language: RU", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.new(1,1,1)})
New("UICorner", {CornerRadius = UDim.new(0,8)}, langToggle)

local function updatePreview()
	local r,g,b = rSlider.get(), gSlider.get(), bSlider.get()
	local a = aSlider.get()
	previewBox.BackgroundColor3 = Color3.fromRGB(r,g,b)
	previewBox.BackgroundTransparency = 1 - a/100
end

rSlider.set(rSlider.get()); gSlider.set(gSlider.get()); bSlider.set(bSlider.get()); aSlider.set(aSlider.get()); focusOffsetSlider.set(focusOffsetSlider.get())
updatePreview()

applyBtn.MouseButton1Click:Connect(function()
	local r, g, b = rSlider.get(), gSlider.get(), bSlider.get()
	local a = aSlider.get()
	main.BackgroundColor3 = Color3.fromRGB(r,g,b)
	main.BackgroundTransparency = 1 - a/100
	previewBox.BackgroundColor3 = main.BackgroundColor3
	previewBox.BackgroundTransparency = main.BackgroundTransparency
end)

local focusOffsetEnabled = false
focusToggle.MouseButton1Click:Connect(function()
	focusOffsetEnabled = not focusOffsetEnabled
	focusToggle.Text = "Focus offset: " .. (focusOffsetEnabled and "ON" or "OFF")
	focusToggle.BackgroundColor3 = focusOffsetEnabled and Themes[CurrentTheme].Accent or Color3.fromRGB(70,70,70)
end)

resetPosBtn.MouseButton1Click:Connect(function()
	local vp = workspace.CurrentCamera.ViewportSize
	main.Position = UDim2.new(0, math.floor((vp.X - main.AbsoluteSize.X)/2), 0, math.floor((vp.Y - main.AbsoluteSize.Y)/2))
end)

local isRussian = true
local function setLanguage(russian)
	isRussian = russian
	if isRussian then
		tabMainBtn.Text = "Главная"
		tabExecBtn.Text = "Инжекторы"
		tabSettingsBtn.Text = "Настройки"
		tabDiscBtn.Text = "Дисклеймер"
		btnClose.Text = "✕"
		btnMin.Text = "—"
		executeButton.Text = "Выполнить"
		langToggle.Text = "Язык: RU"
		resetPosBtn.Text = "Сбросить позицию"
		applyBtn.Text = "Применить"
		focusToggle.Text = "Смещение фокуса: " .. (focusOffsetEnabled and "ВКЛ" or "ВЫКЛ")
		statusLabel.Text = "Статус: Готов"
		if disclaimerLabel then
			disclaimerLabel.Text = "Скрипт создан исключительно в развлекательных целях\nЗлоупотреблять им нельзя\nВерсия: Beta — со временем он улучшится"
		end
	else
		tabMainBtn.Text = "Main"
		tabExecBtn.Text = "Executors"
		tabSettingsBtn.Text = "Settings"
		tabDiscBtn.Text = "Disclaimer"
		btnClose.Text = "✕"
		btnMin.Text = "—"
		executeButton.Text = "Execute"
		langToggle.Text = "Language: EN"
		resetPosBtn.Text = "Reset position"
		applyBtn.Text = "Apply"
		focusToggle.Text = "Focus offset: " .. (focusOffsetEnabled and "ON" or "OFF")
		statusLabel.Text = "Status: Ready"
		if disclaimerLabel then
			disclaimerLabel.Text = "This script is created solely for entertainment purposes\nDo not abuse it\nVersion: Beta — it will improve over time"
		end
	end
end

langToggle.MouseButton1Click:Connect(function()
	setLanguage(not isRussian)
end)

local discPage = pages[4]
local disclaimerLabel = New("TextLabel", {
	Parent = discPage,
	Size = UDim2.new(1, -24, 1, -24),
	Position = UDim2.new(0, 12, 0, 12),
	BackgroundTransparency = 1,
	Text = "Скрипт создан исключительно в развлекательных целях\nЗлоупотреблять им нельзя\nВерсия: Beta — со временем он улучшится",
	TextWrapped = true,
	Font = Enum.Font.Gotham,
	TextSize = 16,
	TextColor3 = Color3.new(1,1,1),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top
})

local resizerBR = New("Frame", {Parent = main, Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -18, 1, -18), BackgroundTransparency = 1})
local gripBR = New("Frame", {Parent = resizerBR, Size = UDim2.new(1, 1, 1, 1), BackgroundColor3 = Themes[CurrentTheme].Accent, BackgroundTransparency = 0.12})
New("UICorner", {CornerRadius = UDim.new(0,8)}, gripBR)

local handleRight = New("Frame", {Parent = main, Size = UDim2.new(0, 12, 1, 0), Position = UDim2.new(1, -12, 0, 0), BackgroundTransparency = 1})
local handleLeft = New("Frame", {Parent = main, Size = UDim2.new(0, 12, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
local handleTop = New("Frame", {Parent = main, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
local handleBottom = New("Frame", {Parent = main, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundTransparency = 1})

local resizing = false
local resizeMode = nil
local rStartPos = nil
local rStartSize = nil
local rStartMainPos = nil

local function beginResize(mode, input)
	resizing = true
	resizeMode = mode
	rStartPos = input.Position
	rStartSize = {X = main.Size.X.Offset, Y = main.Size.Y.Offset}
	rStartMainPos = {X = main.Position.X.Offset, Y = main.Position.Y.Offset}
	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			resizing = false
			resizeMode = nil
		end
	end)
end

handleRight.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginResize("right", input) end end)
handleLeft.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginResize("left", input) end end)
handleTop.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginResize("top", input) end end)
handleBottom.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginResize("bottom", input) end end)
resizerBR.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginResize("corner", input) end end)

UserInputService.InputChanged:Connect(function(input)
	if not resizing then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local dx = input.Position.X - rStartPos.X
	local dy = input.Position.Y - rStartPos.Y
	if resizeMode == "right" then
		local newW = math.clamp(rStartSize.X + dx, MIN_W, MAX_W)
		main.Size = UDim2.new(0, newW, 0, main.Size.Y.Offset)
	elseif resizeMode == "bottom" then
		local newH = math.clamp(rStartSize.Y + dy, MIN_H, MAX_H)
		main.Size = UDim2.new(0, main.Size.X.Offset, 0, newH)
	elseif resizeMode == "left" then
		local desired = rStartSize.X - dx
		local newW = math.clamp(desired, MIN_W, MAX_W)
		local widthDiff = rStartSize.X - newW
		local newX = rStartMainPos.X + widthDiff
		main.Size = UDim2.new(0, newW, 0, main.Size.Y.Offset)
		main.Position = UDim2.new(0, newX, 0, main.Position.Y.Offset)
	elseif resizeMode == "top" then
		local desired = rStartSize.Y - dy
		local newH = math.clamp(desired, MIN_H, MAX_H)
		local heightDiff = rStartSize.Y - newH
		local newY = rStartMainPos.Y + heightDiff
		main.Size = UDim2.new(0, main.Size.X.Offset, 0, newH)
		main.Position = UDim2.new(0, main.Position.X.Offset, 0, newY)
	elseif resizeMode == "corner" then
		local newW = math.clamp(rStartSize.X + dx, MIN_W, MAX_W)
		local newH = math.clamp(rStartSize.Y + dy, MIN_H, MAX_H)
		main.Size = UDim2.new(0, newW, 0, newH)
	end
end)

local dragMain = false
local dragStart = nil
local dragOrigin = nil
topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragMain = true
		dragStart = input.Position
		dragOrigin = {X = main.Position.X.Offset, Y = main.Position.Y.Offset}
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragMain = false
			end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragMain and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(0, dragOrigin.X + delta.X, 0, dragOrigin.Y + delta.Y)
	end
end)

local toggle = New("TextButton", {
	Size = UDim2.new(0,72,0,72),
	Position = UDim2.new(0.04, 0, 0.82, 0),
	BackgroundColor3 = Themes[CurrentTheme].Accent,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "✨",
	Font = Enum.Font.GothamBlack,
	TextSize = 42,
	TextColor3 = Themes[CurrentTheme].Text,
	ZIndex = 100
}, screen)
New("UICorner", {CornerRadius = UDim.new(1,0)}, toggle)
New("UIStroke", {Thickness = 1, Transparency = 0.36}, toggle)

local toggleDrag = false
local toggleStart = nil
local toggleOrigin = nil
toggle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		toggleDrag = true
		toggleStart = input.Position
		toggleOrigin = {X = toggle.Position.X.Offset, Y = toggle.Position.Y.Offset}
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				toggleDrag = false
			end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if toggleDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - toggleStart
		toggle.Position = UDim2.new(0, toggleOrigin.X + delta.X, 0, toggleOrigin.Y + delta.Y)
	end
end)

local function openUI()
	local savedW = player:GetAttribute("UEUI_W") or DEFAULT_W
	local savedH = player:GetAttribute("UEUI_H") or DEFAULT_H
	if not player:GetAttribute("UEUI_X") then
		local vp = workspace.CurrentCamera.ViewportSize
		main.Position = UDim2.new(0, math.floor((vp.X - savedW)/2), 0, math.floor((vp.Y - savedH)/2))
	end
	local curPos = main.Position
	main.Size = UDim2.new(0, 28, 0, 28)
	main.Position = curPos
	main.Visible = true
	TweenService:Create(main, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, savedW, 0, savedH)}):Play()
end

local function closeUI()
	local savedW = main.Size.X.Offset
	local savedH = main.Size.Y.Offset
	TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 28, 0, 28)}):Play()
	task.delay(0.18, function()
		main.Visible = false
		main.Size = UDim2.new(0, savedW, 0, savedH)
	end)
end

toggle.MouseButton1Click:Connect(function()
	if main.Visible then
		closeUI()
	else
		openUI()
	end
end)
btnClose.MouseButton1Click:Connect(function() closeUI() end)
btnMin.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

local function updateFontSizes()
	local h = main.AbsoluteSize.Y
	if h == 0 then return end
	local codeSize = math.clamp(math.floor(h * 0.028), 9, 18)
	local btnSize = math.clamp(math.floor(h * 0.03), 12, 20)
	local smallSize = math.clamp(math.floor(h * 0.022), 10, 16)
	if codeBox then codeBox.TextSize = codeSize; codeBox.TextScaled = false end
	if executeButton then executeButton.TextSize = btnSize end
	if statusLabel then statusLabel.TextSize = smallSize end
	for _, tb in ipairs({tabMainBtn, tabExecBtn, tabSettingsBtn, tabDiscBtn}) do
		if tb then tb.TextSize = math.clamp(math.floor(h * 0.028), 12, 18) end
	end
end

main:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateFontSizes)
task.defer(updateFontSizes)

local executors = {
	["XENO"] = function(code)
		if syn and syn.protect_gui then pcall(function() syn.protect_gui(screen) end) end
		if type(loadstring) == "function" then
			pcall(function() loadstring(code or "")() end)
		end
		return "XENO"
	end,
	["DELTA X"] = function(code)
		if delta and type(delta.execute) == "function" then
			pcall(function() delta.execute(code or "") end)
			return "DELTA X"
		end
		if type(loadstring) == "function" then pcall(function() loadstring(code or "")() end) end
		return "Fallback"
	end,
	["KRNL"] = function(code)
		if KRNL and type(KRNL.execute) == "function" then
			pcall(function() KRNL.execute(code or "") end)
			return "KRNL"
		end
		if type(loadstring) == "function" then pcall(function() loadstring(code or "")() end) end
		return "Fallback"
	end,
	["Arceus X"] = function(code)
		if ArceusX and type(ArceusX.execute) == "function" then
			pcall(function() ArceusX.execute(code or "") end)
			return "Arceus X"
		end
		if type(loadstring) == "function" then pcall(function() loadstring(code or "")() end) end
		return "Fallback"
	end,
	["Fluxus"] = function(code)
		if fluxus and type(fluxus.execute) == "function" then
			pcall(function() fluxus.execute(code or "") end)
			return "Fluxus"
		end
		if type(loadstring) == "function" then pcall(function() loadstring(code or "")() end) end
		return "Fallback"
	end
}

executeButton.MouseButton1Click:Connect(function()
	local code = codeBox.Text or ""
	local executor = executors[selectedBase] or executors["XENO"]
	statusLabel.Text = isRussian and "Статус: Выполняется..." or "Status: Running..."
	local ok, res = pcall(function() return executor(code) end)
	if ok then
		local used = res or (isAvailable and isAvailable(selectedBase) and selectedBase or "Fallback")
		statusLabel.Text = (isRussian and "Статус: Готов! Используется: " or "Status: Done! Used: ") .. tostring(used)
	else
		statusLabel.Text = isRussian and "Статус: Ошибка при выполнении" or "Status: Execution error"
		warn("Executor error:", res)
	end
end)

local function saveState()
	if main.AbsoluteSize.X == 0 then main:GetPropertyChangedSignal("AbsoluteSize"):Wait() end
	player:SetAttribute("UEUI_W", main.Size.X.Offset)
	player:SetAttribute("UEUI_H", main.Size.Y.Offset)
	player:SetAttribute("UEUI_X", main.Position.X.Offset)
	player:SetAttribute("UEUI_Y", main.Position.Y.Offset)
	player:SetAttribute("UEUI_TOGGLE_X", toggle.Position.X.Offset)
	player:SetAttribute("UEUI_TOGGLE_Y", toggle.Position.Y.Offset)
	player:SetAttribute("UEUI_LANG_RU", isRussian and 1 or 0)
	player:SetAttribute("UEUI_FOCUS_ENABLED", focusOffsetEnabled and 1 or 0)
	player:SetAttribute("UEUI_FOCUS_OFFSET", focusOffsetSlider.get() or -80)
end

local function loadState()
	local w = player:GetAttribute("UEUI_W")
	local h = player:GetAttribute("UEUI_H")
	local x = player:GetAttribute("UEUI_X")
	local y = player:GetAttribute("UEUI_Y")
	local tx = player:GetAttribute("UEUI_TOGGLE_X")
	local ty = player:GetAttribute("UEUI_TOGGLE_Y")
	local lr = player:GetAttribute("UEUI_LANG_RU")
	local fe = player:GetAttribute("UEUI_FOCUS_ENABLED")
	local fo = player:GetAttribute("UEUI_FOCUS_OFFSET")
	if type(w) == "number" and type(h) == "number" then main.Size = UDim2.new(0, w, 0, h) end
	if type(x) == "number" and type(y) == "number" then main.Position = UDim2.new(0, x, 0, y) end
	if type(tx) == "number" and type(ty) == "number" then toggle.Position = UDim2.new(0, tx, 0, ty) end
	if type(lr) == "number" then setLanguage(lr == 1) end
	if type(fe) == "number" then focusOffsetEnabled = (fe == 1); focusToggle.Text = focusOffsetEnabled and "Focus offset: ON" or "Focus offset: OFF" end
	if
