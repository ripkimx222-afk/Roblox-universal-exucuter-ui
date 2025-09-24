local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function New(class, props, parent)
	local o = Instance.new(class)
	if props then for k,v in pairs(props) do o[k] = v end end
	if parent then o.Parent = parent end
	return o
end

local gui = New("ScreenGui", {Name="SafeInjectorUI", ResetOnSpawn=false, IgnoreGuiInset=true}, playerGui)

local toggle = New("TextButton", {
	Size = UDim2.new(0,76,0,76),
	Position = UDim2.new(0.04,0,0.78,0),
	AnchorPoint = Vector2.new(0,0),
	BackgroundColor3 = Color3.fromRGB(110,50,210),
	BackgroundTransparency = 0.06,
	AutoButtonColor = false,
	Text = "toggle",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Color3.new(1,1,1),
	ZIndex = 60,
}, gui)
New("UICorner", {CornerRadius=UDim.new(1,0)}, toggle)
New("UIStroke", {Thickness=1, Transparency=0.4}, toggle)

local main = New("Frame", {
	Size = UDim2.new(0,640,0,460),
	Position = UDim2.new(0.5,-320,0.45,-230),
	AnchorPoint = Vector2.new(0.5,0.5),
	BackgroundColor3 = Color3.fromRGB(34,18,90),
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	ZIndex = 50,
}, gui)
New("UICorner", {CornerRadius=UDim.new(0,18)}, main)
local mainGrad = New("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(98,40,210)), ColorSequenceKeypoint.new(1, Color3.fromRGB(35,10,120))}, Rotation=30}, main)
local noise = New("ImageLabel", {Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Image="rbxassetid://3570695787", ImageTransparency=0.92, ScaleType=Enum.ScaleType.Tile, TileSize=UDim2.new(0,72,0,72), ZIndex=49}, main)

local topBar = New("Frame", {Size=UDim2.new(1,0,0,50), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, ZIndex=51}, main)
local title = New("TextLabel", {Parent=topBar, Size=UDim2.new(0.6,-20,1,0), Position=UDim2.new(0,12,0,0), BackgroundTransparency=1, Text="Electron", Font=Enum.Font.GothamBlack, TextSize=22, TextColor3=Color3.new(1,1,1), TextXAlignment=Enum.TextXAlignment.Left, ZIndex=52})
local subtitle = New("TextLabel", {Parent=topBar, Size=UDim2.new(0.4,-20,1,0), Position=UDim2.new(0.6,12,0,0), BackgroundTransparency=1, Text="by Hikmes0", Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(220,220,255), TextXAlignment=Enum.TextXAlignment.Right, ZIndex=52})

local btnClose = New("TextButton", {Size=UDim2.new(0,36,0,34), Position=UDim2.new(1,-46,0,8), AnchorPoint=Vector2.new(1,0), BackgroundColor3=Color3.fromRGB(200,60,80), Text="✕", Font=Enum.Font.GothamBold, TextSize=18, TextColor3=Color3.new(1,1,1), ZIndex=52}, topBar)
New("UICorner", {CornerRadius=UDim.new(0,8)}, btnClose)
local btnMin = New("TextButton", {Size=UDim2.new(0,36,0,34), Position=UDim2.new(1,-92,0,8), AnchorPoint=Vector2.new(1,0), BackgroundColor3=Color3.fromRGB(120,120,120), Text="—", Font=Enum.Font.GothamBold, TextSize=18, TextColor3=Color3.new(1,1,1), ZIndex=52}, topBar)
New("UICorner", {CornerRadius=UDim.new(0,8)}, btnMin)

local tabsFrame = New("Frame", {Size=UDim2.new(0,260,1,-64), Position=UDim2.new(0,16,0,64), BackgroundTransparency=1, ZIndex=51}, main)
local contentFrame = New("Frame", {Size=UDim2.new(1,-300,1,-64), Position=UDim2.new(0,300,0,64), BackgroundTransparency=1, ZIndex=51}, main)

local function MakeTabButton(text, posY)
	local b = New("TextButton", {Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,0,posY), BackgroundColor3=Color3.fromRGB(75,34,160), BorderSizePixel=0, Font=Enum.Font.Gotham, Text=text, TextSize=16, TextColor3=Color3.fromRGB(245,245,255), ZIndex=52}, tabsFrame)
	New("UICorner", {CornerRadius=UDim.new(0,10)}, b)
	return b
end

local tabInjector = MakeTabButton("Injector", 0)
local tabBases = MakeTabButton("Bases", 46)
local tabSettings = MakeTabButton("Settings", 92)

local pages = {}
for i=1,3 do pages[i] = New("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false, ZIndex=51}, contentFrame) end
pages[1].Visible = true

local function activateTab(index)
	for i,p in ipairs(pages) do p.Visible = (i==index) end
	for i,b in ipairs({tabInjector, tabBases, tabSettings}) do
		local col = (i==index) and Color3.fromRGB(150,90,220) or Color3.fromRGB(75,34,160)
		b.BackgroundColor3 = col
	end
end

tabInjector.MouseButton1Click:Connect(function() activateTab(1) end)
tabBases.MouseButton1Click:Connect(function() activateTab(2) end)
tabSettings.MouseButton1Click:Connect(function() activateTab(3) end)

-- Injector page
local scriptBox = New("TextBox", {Parent=pages[1], Size=UDim2.new(1,-24,0,260), Position=UDim2.new(0,12,0,12), BackgroundTransparency=0.82, ClearTextOnFocus=false, MultiLine=true, TextWrapped=true, Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(245,245,245), PlaceholderText="Paste safe Lua snippet for testing (simulation only)"}, pages[1])
New("UICorner", {CornerRadius=UDim.new(0,12)}, scriptBox)
local execBtn = New("TextButton", {Parent=pages[1], Size=UDim2.new(0,200,0,44), Position=UDim2.new(0,12,1,-56), BackgroundColor3=Color3.fromRGB(95,35,200), Font=Enum.Font.GothamBold, Text="Execute", TextSize=18, TextColor3=Color3.fromRGB(245,245,245)}, pages[1])
New("UICorner", {CornerRadius=UDim.new(0,12)}, execBtn)
local execStatus = New("TextLabel", {Parent=pages[1], Size=UDim2.new(1,-24,0,20), Position=UDim2.new(0,12,1,-28), BackgroundTransparency=1, Text="Ready.", Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(230,230,255), TextXAlignment=Enum.TextXAlignment.Left}, pages[1])

-- Bases page
local basesList = New("Frame", {Parent=pages[2], Size=UDim2.new(1,-24,1,-24), Position=UDim2.new(0,12,0,12), BackgroundTransparency=1}, pages[2])
local bases = {"XENO", "DELTA X", "KRNL", "Arceus X"}
local selectedBase = bases[1]
local baseButtons = {}
for i,name in ipairs(bases) do
	local b = New("TextButton", {Parent=basesList, Size=UDim2.new(1,0,0,42), Position=UDim2.new(0,0,0,(i-1)*48), BackgroundColor3=Color3.fromRGB(95,45,170), BorderSizePixel=0, Font=Enum.Font.Gotham, Text=name, TextSize=16, TextColor3=Color3.fromRGB(240,240,255)}, basesList)
	New("UICorner", {CornerRadius=UDim.new(0,10)}, b)
	table.insert(baseButtons, b)
	b.MouseButton1Click:Connect(function()
		selectedBase = name
		for j,bb in ipairs(baseButtons) do bb.BackgroundColor3 = (bb==b) and Color3.fromRGB(150,90,220) or Color3.fromRGB(95,45,170) end
	end)
end
baseButtons[1].BackgroundColor3 = Color3.fromRGB(150,90,220)

-- Settings page
local settingsPage = pages[3]
local colorLabel = New("TextLabel", {Parent=settingsPage, Size=UDim2.new(1, -24, 0, 20), Position=UDim2.new(0,12,0,12), BackgroundTransparency=1, Font=Enum.Font.GothamBold, Text="Background color (RGB)", TextSize=15, TextColor3=Color3.fromRGB(240,240,240), TextXAlignment=Enum.TextXAlignment.Left}, settingsPage)

local function MakeSlider(parent, y, minv, maxv, init)
	local holder = New("Frame", {Parent=parent, Size=UDim2.new(1,-24,0,36), Position=UDim2.new(0,12,0,y), BackgroundTransparency=1}, parent)
	local label = New("TextLabel", {Parent=holder, Size=UDim2.new(0.42,0,1,0), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=14, Text="Value", TextColor3=Color3.fromRGB(240,240,240), TextXAlignment=Enum.TextXAlignment.Left}, holder)
	local valBox = New("TextBox", {Parent=holder, Size=UDim2.new(0.18,0,0.84,0), Position=UDim2.new(0.82,0,0.08,0), BackgroundTransparency=0.75, ClearTextOnFocus=false, Text=tostring(init), Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(230,230,230), TextXAlignment=Enum.TextXAlignment.Center}, holder)
	New("UICorner", {CornerRadius=UDim.new(0,8)}, valBox)
	local rail = New("Frame", {Parent=holder, Size=UDim2.new(0.56,0,0,10), Position=UDim2.new(0.44,0,0.5,-5), BackgroundColor3=Color3.fromRGB(70,30,150), BorderSizePixel=0}, holder)
	New("UICorner", {CornerRadius=UDim.new(0,8)}, rail)
	local knob = New("Frame", {Parent=rail, Size=UDim2.new(0,0,1,0), Position=UDim2.new((init-minv)/(maxv-minv),0,0,0), BackgroundColor3=Color3.fromRGB(150,90,220), BorderSizePixel=0}, rail)
	New("UICorner", {CornerRadius=UDim.new(0,8)}, knob)
	local dragging = false
	local function setFromX(x)
		local absX = math.clamp(x - rail.AbsolutePosition.X, 0, rail.AbsoluteSize.X)
		local frac = absX / math.max(1, rail.AbsoluteSize.X)
		local value = minv + frac * (maxv - minv)
		knob.Size = UDim2.new(frac,0,1,0)
		valBox.Text = ("%d"):format(math.floor(value + 0.5))
		return value
	end
	rail.InputBegan:Connect(function(input)
		if not main.Visible then return end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	rail.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then setFromX(input.Position.X) end
		end
	end)
	rail.InputEnded:Connect(function(input)
		if input.UserInputState == Enum.UserInputState.End then dragging = false end
	end)
	valBox.Focused:Connect(function() end)
	valBox.FocusLost:Connect(function()
		local num = tonumber(valBox.Text) or init
		if num < minv then num = minv end
		if num > maxv then num = maxv end
		local frac = (num - minv)/(maxv - minv)
		knob.Size = UDim2.new(frac,0,1,0)
		valBox.Text = ("%d"):format(num)
	end)
	return {get=function() return tonumber(valBox.Text) or init end, set=function(v) valBox.Text = tostring(math.floor(v+0.5)) local frac=(v-minv)/(maxv-minv) knob.Size = UDim2.new(frac,0,1,0) end}
end

local rSlider = MakeSlider(settingsPage, 44, 0, 255, 98)
local gSlider = MakeSlider(settingsPage, 92, 0, 255, 40)
local bSlider = MakeSlider(settingsPage, 140, 0, 255, 210)
local alphaSlider = MakeSlider(settingsPage, 188, 0, 100, math.floor((1-main.BackgroundTransparency)*100))

local preview = New("Frame", {Parent=settingsPage, Size=UDim2.new(0,240,0,110), Position=UDim2.new(1,-260,0,44), BackgroundColor3=Color3.fromRGB(98,40,210), BackgroundTransparency=main.BackgroundTransparency, BorderSizePixel=0}, settingsPage)
New("UICorner", {CornerRadius=UDim.new(0,12)}, preview)

local applyBtn = New("TextButton", {Parent=settingsPage, Size=UDim2.new(0,160,0,36), Position=UDim2.new(1,-260,0,166), BackgroundColor3=Color3.fromRGB(95,35,200), Font=Enum.Font.GothamBold, Text="Apply", TextSize=16, TextColor3=Color3.fromRGB(245,245,245)}, settingsPage)
New("UICorner", {CornerRadius=UDim.new(0,10)}, applyBtn)

local collapseBtn = New("TextButton", {Parent=topBar, Size=UDim2.new(0,34,0,34), Position=UDim2.new(1,-136,0,8), AnchorPoint=Vector2.new(1,0), BackgroundColor3=Color3.fromRGB(70,70,70), Text="▤", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Color3.new(1,1,1)}, topBar)
New("UICorner", {CornerRadius=UDim.new(0,8)}, collapseBtn)

-- Resizer bottom-right
local resizer = New("ImageButton", {Parent=main, Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-34,1,-34), BackgroundTransparency=1, Image="", ZIndex=52})
local resGrip = New("Frame", {Parent=resizer, Size=UDim2.new(1,1,1,1), BackgroundColor3=Color3.fromRGB(150,50,210), BackgroundTransparency=0.15}, resizer)
New("UICorner", {CornerRadius=UDim.new(0,8)}, resGrip)

local function SaveState()
	player:SetAttribute("UI_ToggleX", toggle.Position.X.Scale)
	player:SetAttribute("UI_ToggleY", toggle.Position.Y.Scale)
	player:SetAttribute("UI_MainX", main.Position.X.Scale)
	player:SetAttribute("UI_MainXOff", main.Position.X.Offset)
	player:SetAttribute("UI_MainY", main.Position.Y.Scale)
	player:SetAttribute("UI_MainYOff", main.Position.Y.Offset)
	player:SetAttribute("UI_MainW", main.Size.X.Offset)
	player:SetAttribute("UI_MainH", main.Size.Y.Offset)
	player:SetAttribute("UI_BG_R", rSlider.get())
	player:SetAttribute("UI_BG_G", gSlider.get())
	player:SetAttribute("UI_BG_B", bSlider.get())
	player:SetAttribute("UI_BG_A", alphaSlider.get())
	player:SetAttribute("UI_SelectedBase", selectedBase)
end

local function LoadState()
	local tx,ty = player:GetAttribute("UI_ToggleX"), player:GetAttribute("UI_ToggleY")
	if type(tx)=="number" and type(ty)=="number" then toggle.Position = UDim2.new(tx,0,ty,0) end
	local mx = player:GetAttribute("UI_MainX"); local mxoff = player:GetAttribute("UI_MainXOff")
	local my = player:GetAttribute("UI_MainY"); local myoff = player:GetAttribute("UI_MainYOff")
	local mw = player:GetAttribute("UI_MainW"); local mh = player:GetAttribute("UI_MainH")
	if type(mw)=="number" and type(mh)=="number" then main.Size = UDim2.new(0,mw,0,mh) end
	if type(mx)=="number" and type(mxoff)=="number" and type(my)=="number" and type(myoff)=="number" then main.Position = UDim2.new(mx, mxoff, my, myoff) end
	local r = player:GetAttribute("UI_BG_R"); local g = player:GetAttribute("UI_BG_G"); local b = player:GetAttribute("UI_BG_B"); local a = player:GetAttribute("UI_BG_A")
	if type(r)=="number" and type(g)=="number" and type(b)=="number" then
		rSlider.set(r); gSlider.set(g); bSlider.set(b)
		local alpha = (type(a)=="number") and a or math.floor((1-main.BackgroundTransparency)*100)
		alphaSlider.set(alpha)
		preview.BackgroundColor3 = Color3.fromRGB(r,g,b)
		preview.BackgroundTransparency = 1 - alpha/100
		main.BackgroundColor3 = Color3.fromRGB(r,g,b)
		main.BackgroundTransparency = 1 - alpha/100
	end
	local sb = player:GetAttribute("UI_SelectedBase")
	if type(sb)=="string" then
		selectedBase = sb
		for _,bb in ipairs(baseButtons) do bb.BackgroundColor3 = (bb.Text==sb) and Color3.fromRGB(150,90,220) or Color3.fromRGB(95,45,170) end
	end
end

LoadState()

local function UpdatePreview()
	local r,g,b = rSlider.get(), gSlider.get(), bSlider.get()
	local a = alphaSlider.get()
	preview.BackgroundColor3 = Color3.fromRGB(r,g,b)
	preview.BackgroundTransparency = 1 - a/100
end

rSlider.set(rSlider.get()); gSlider.set(gSlider.get()); bSlider.set(bSlider.get()); alphaSlider.set(alphaSlider.get())
UpdatePreview()

applyBtn.MouseButton1Click:Connect(function()
	local r,g,b = rSlider.get(), gSlider.get(), bSlider.get()
	local a = alphaSlider.get()
	main.BackgroundColor3 = Color3.fromRGB(r,g,b)
	main.BackgroundTransparency = 1 - a/100
	preview.BackgroundColor3 = Color3.fromRGB(r,g,b)
	preview.BackgroundTransparency = 1 - a/100
	SaveState()
end)

-- interactivity and behavior
local function PressAnim(btn)
	local t1 = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Size = btn.Size - UDim2.new(0,6,0,6)})
	t1:Play()
	t1.Completed:Wait()
	TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = btn.Size}):Play()
end

btnClose.MouseButton1Click:Connect(function()
	PressAnim(btnClose)
	main.Visible = false
end)
btnMin.MouseButton1Click:Connect(function()
	PressAnim(btnMin)
	main.Visible = not main.Visible
end)
collapseBtn.MouseButton1Click:Connect(function()
	PressAnim(collapseBtn)
	if contentFrame.Visible then
		contentFrame.Visible = false
		tabsFrame.Visible = false
	else
		contentFrame.Visible = true
		tabsFrame.Visible = true
	end
end)

local isOpen = true
toggle.MouseButton1Click:Connect(function()
	PressAnim(toggle)
	if main.Visible then
		TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Size=UDim2.new(0,0,0,0)}):Play()
		wait(0.18)
		main.Visible = false
	else
		main.Visible = true
		TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=main.Size}):Play()
	end
end)

local function MakeDraggable(control, area, clamp)
	local dragging=false; local dragStart; local startPos; local dragInput
	area.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true; dragStart=input.Position; startPos=control.Position
			input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
		end
	end)
	area.InputChanged:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input==dragInput then
			local delta = input.Position - dragStart
			local newX = startPos.X.Offset + delta.X
			local newY = startPos.Y.Offset + delta.Y
			if clamp then
				local vp = workspace.CurrentCamera.ViewportSize
				newX = math.clamp(newX, 0, vp.X - control.AbsoluteSize.X)
				newY = math.clamp(newY, 0, vp.Y - control.AbsoluteSize.Y)
				control.Position = UDim2.new(0, newX, 0, newY)
			else
				control.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
			end
		end
	end)
end

MakeDraggable(main, topBar, true)
MakeDraggable(toggle, toggle, true)

local resizing=false; local resStart; local resSize; local resInput
resizer.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		resizing=true; resStart=input.Position; resSize=main.Size
		input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then resizing=false end end)
	end
end)
resizer.InputChanged:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then resInput=input end
end)
UserInputService.InputChanged:Connect(function(input)
	if resizing and input==resInput then
		local delta = input.Position - resStart
		local newW = math.clamp(resSize.X.Offset + delta.X, 360, 1200)
		local newH = math.clamp(resSize.Y.Offset + delta.Y, 260, 900)
		main.Size = UDim2.new(0, newW, 0, newH)
		SaveState()
	end
end)

execBtn.MouseButton1Click:Connect(function()
	local code = scriptBox.Text or ""
	execStatus.Text = "Simulating execution via "..selectedBase.."..."
	print("[SIMULATION] base:", selectedBase)
	print("[SIMULATION] script preview:", string.sub(code,1,300))
	TweenService:Create(execBtn, TweenInfo.new(0.12), {BackgroundTransparency=0.6}):Play()
	delay(0.12, function() TweenService:Create(execBtn, TweenInfo.new(0.18), {BackgroundTransparency=0}):Play() end)
	delay(1.1, function() execStatus.Text = "Ready. (Simulation complete)" end)
end)

scriptBox.Focused:Connect(function()
	TweenService:Create(main, TweenInfo.new(0.18), {Position = main.Position + UDim2.new(0,0,0,-90)}):Play()
end)
scriptBox.FocusLost:Connect(function()
	LoadState()
end)

toggle:GetPropertyChangedSignal("Position"):Connect(SaveState)
main:GetPropertyChangedSignal("Position"):Connect(SaveState)
main:GetPropertyChangedSignal("Size"):Connect(SaveState)

RunService.Heartbeat:Connect(function()
	UpdatePreview()
end)

SaveState()
