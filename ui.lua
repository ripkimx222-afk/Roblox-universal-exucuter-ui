-- Working Enhanced UI (safe simulation). Place as LocalScript under StarterGui or StarterPlayerScripts.

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

local screen = New("ScreenGui", {Name = "EnhancedUI_v3", ResetOnSpawn = false, IgnoreGuiInset = true}, playerGui)

local toggle = New("TextButton", {
	Size = UDim2.new(0,72,0,72),
	Position = UDim2.new(0.06,0,0.78,0),
	BackgroundColor3 = Color3.fromRGB(116,60,213),
	BackgroundTransparency = 0.06,
	AutoButtonColor = false,
	BorderSizePixel = 0,
	Text = "toggle",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Color3.new(1,1,1),
	ZIndex = 60,
}, screen)
New("UICorner", {CornerRadius = UDim.new(1,0)}, toggle)
New("UIStroke", {Thickness = 1, Transparency = 0.36}, toggle)

local main = New("Frame", {
	Size = UDim2.new(0,680,0,480),
	Position = UDim2.new(0.5,-340,0.5,-240),
	AnchorPoint = Vector2.new(0.5,0.5),
	BackgroundColor3 = Color3.fromRGB(34,18,90),
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
	ZIndex = 50,
}, screen)
New("UICorner", {CornerRadius = UDim.new(0,18)}, main)
New("UIGradient", {Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(98,40,210)), ColorSequenceKeypoint.new(1, Color3.fromRGB(35,10,120))}, Rotation = 28}, main)
New("ImageLabel", {Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Image = "rbxassetid://3570695787", ImageTransparency = 0.92, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.new(0,72,0,72), ZIndex = 49}, main)

local topBar = New("Frame", {Size = UDim2.new(1,0,0,52), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, ZIndex = 51}, main)
New("TextLabel", {Parent = topBar, Size = UDim2.new(0.6,-24,1,0), Position = UDim2.new(0,16,0,0), BackgroundTransparency = 1, Text = "Electron", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Color3.new(1,1,1), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52}, topBar)
New("TextLabel", {Parent = topBar, Size = UDim2.new(0.4,-24,1,0), Position = UDim2.new(0.6,12,0,0), BackgroundTransparency = 1, Text = "by Hikmes0", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(220,220,255), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 52}, topBar)

local btnClose = New("TextButton", {Size = UDim2.new(0,36,0,36), Position = UDim2.new(1,-46,0,8), AnchorPoint = Vector2.new(1,0), BackgroundColor3 = Color3.fromRGB(200,60,80), Text = "✕", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1,1,1), ZIndex = 52}, topBar)
New("UICorner", {CornerRadius = UDim.new(0,10)}, btnClose)
local btnMin = New("TextButton", {Size = UDim2.new(0,36,0,36), Position = UDim2.new(1,-92,0,8), AnchorPoint = Vector2.new(1,0), BackgroundColor3 = Color3.fromRGB(100,100,100), Text = "—", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1,1,1), ZIndex = 52}, topBar)
New("UICorner", {CornerRadius = UDim.new(0,10)}, btnMin)
local collapseBtn = New("TextButton", {Size = UDim2.new(0,34,0,34), Position = UDim2.new(1,-138,0,8), AnchorPoint = Vector2.new(1,0), BackgroundColor3 = Color3.fromRGB(75,75,75), Text = "▤", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1), ZIndex = 52}, topBar)
New("UICorner", {CornerRadius = UDim.new(0,10)}, collapseBtn)

local tabsFrame = New("Frame", {Size = UDim2.new(0,260,1,-72), Position = UDim2.new(0,16,0,64), BackgroundTransparency = 1, ZIndex = 51}, main)
local contentFrame = New("Frame", {Size = UDim2.new(1,-300,1,-72), Position = UDim2.new(0,300,0,64), BackgroundTransparency = 1, ZIndex = 51}, main)

local function MakeTabButton(text, y)
	local b = New("TextButton", {Size = UDim2.new(1,0,0,44), Position = UDim2.new(0,0,0,y), BackgroundColor3 = Color3.fromRGB(75,34,160), BorderSizePixel = 0, Font = Enum.Font.Gotham, Text = text, TextSize = 16, TextColor3 = Color3.fromRGB(245,245,245), ZIndex = 52}, tabsFrame)
	New("UICorner", {CornerRadius = UDim.new(0,10)}, b)
	return b
end

local tabInjector = MakeTabButton("Injector", 0)
local tabBases = MakeTabButton("Bases", 54)
local tabSettings = MakeTabButton("Settings", 108)

local pages = {}
for i=1,3 do pages[i] = New("Frame", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, ZIndex = 51}, contentFrame) end
pages[1].Visible = true

local function activateTab(index)
	for i,p in ipairs(pages) do p.Visible = (i==index) end
	for i,b in ipairs({tabInjector, tabBases, tabSettings}) do
		b.BackgroundColor3 = (i==index) and Color3.fromRGB(150,90,220) or Color3.fromRGB(75,34,160)
	end
end

tabInjector.MouseButton1Click:Connect(function() activateTab(1) end)
tabBases.MouseButton1Click:Connect(function() activateTab(2) end)
tabSettings.MouseButton1Click:Connect(function() activateTab(3) end)

local execBox = New("TextBox", {Parent = pages[1], Size = UDim2.new(1,-24,0,260), Position = UDim2.new(0,12,0,12), BackgroundColor3 = Color3.fromRGB(28,12,65), BackgroundTransparency = 0, ClearTextOnFocus = false, MultiLine = true, TextWrapped = true, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(250,250,250), PlaceholderText = "Paste Lua for local testing (simulation only)"}, pages[1])
New("UICorner", {CornerRadius = UDim.new(0,12)}, execBox)

local execBtn = New("TextButton", {Parent = pages[1], Size = UDim2.new(0,220,0,46), Position = UDim2.new(0,12,1,-60), BackgroundColor3 = Color3.fromRGB(95,35,200), Font = Enum.Font.GothamBold, Text = "Execute", TextSize = 18, TextColor3 = Color3.fromRGB(245,245,245), ZIndex = 52}, pages[1])
New("UICorner", {CornerRadius = UDim.new(0,12)}, execBtn)
local execStatus = New("TextLabel", {Parent = pages[1], Size = UDim2.new(1,-24,0,20), Position = UDim2.new(0,12,1,-32), BackgroundTransparency = 1, Text = "Ready.", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(230,230,255), TextXAlignment = Enum.TextXAlignment.Left}, pages[1])

local basesList = New("Frame", {Parent = pages[2], Size = UDim2.new(1,-24,1,-24), Position = UDim2.new(0,12,0,12), BackgroundTransparency = 1}, pages[2])
local bases = {"XENO", "DELTA X", "KRNL", "Arceus X"}
local selectedBase = bases[1]
local baseButtons = {}
for i,name in ipairs(bases) do
	local b = New("TextButton", {Parent = basesList, Size = UDim2.new(1,0,0,44), Position = UDim2.new(0,0,0,(i-1)*52), BackgroundColor3 = Color3.fromRGB(95,45,170), BorderSizePixel = 0, Font = Enum.Font.Gotham, Text = name, TextSize = 16, TextColor3 = Color3.fromRGB(240,240,245)}, basesList)
	New("UICorner", {CornerRadius = UDim.new(0,12)}, b)
	table.insert(baseButtons, b)
	b.MouseButton1Click:Connect(function()
		selectedBase = name
		for _,bb in ipairs(baseButtons) do bb.BackgroundColor3 = (bb==b) and Color3.fromRGB(150,90,220) or Color3.fromRGB(95,45,170) end
	end)
end
baseButtons[1].BackgroundColor3 = Color3.fromRGB(150,90,220)

local settingsPage = pages[3]
local function MakeSlider(parent, y, labelText, minv, maxv, init)
	local holder = New("Frame", {Parent = parent, Size = UDim2.new(1,-28,0,46), Position = UDim2.new(0,14,0,y), BackgroundTransparency = 1}, parent)
	local label = New("TextLabel", {Parent = holder, Size = UDim2.new(0.46,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = labelText, TextSize = 14, TextColor3 = Color3.fromRGB(240,240,240), TextXAlignment = Enum.TextXAlignment.Left}, holder)
	local valBox = New("TextBox", {Parent = holder, Size = UDim2.new(0.16,0,0.72,0), Position = UDim2.new(0.82,0,0.14,0), BackgroundColor3 = Color3.fromRGB(26,12,60), BackgroundTransparency = 0.06, ClearTextOnFocus = false, Text = tostring(init), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(245,245,245), TextXAlignment = Enum.TextXAlignment.Center}, holder)
	New("UICorner", {CornerRadius = UDim.new(0,8)}, valBox)
	local rail = New("Frame", {Parent = holder, Size = UDim2.new(0.66,0,0,12), Position = UDim2.new(0.34,0,0.5,-6), BackgroundColor3 = Color3.fromRGB(58,24,140), BorderSizePixel = 0}, holder)
	New("UICorner", {CornerRadius = UDim.new(0,8)}, rail)
	local knob = New("Frame", {Parent = rail, Size = UDim2.new((init-minv)/(maxv-minv),0,1,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = Color3.fromRGB(150,90,220), BorderSizePixel = 0}, rail)
	New("UICorner", {CornerRadius = UDim.new(0,8)}, knob)
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
	valBox.FocusLost:Connect(function()
		local num = tonumber(valBox.Text) or init
		if num < minv then num = minv end
		if num > maxv then num = maxv end
		local frac = (num - minv)/(maxv - minv)
		knob.Size = UDim2.new(frac,0,1,0)
		valBox.Text = ("%d"):format(num)
	end)
	return {get = function() return tonumber(valBox.Text) or init end, set = function(v) valBox.Text = tostring(math.floor(v+0.5)) local frac=(v-minv)/(maxv-minv) knob.Size = UDim2.new(math.clamp(frac,0,1),0,1,0) end, isActive = function() return dragging end}
end

local rS = MakeSlider(settingsPage, 16, "Red", 0, 255, 98)
local gS = MakeSlider(settingsPage, 72, "Green", 0, 255, 40)
local bS = MakeSlider(settingsPage, 128, "Blue", 0, 255, 210)
local aS = MakeSlider(settingsPage, 184, "Opacity (%)", 0, 100, math.floor((1-main.BackgroundTransparency)*100))

local preview = New("Frame", {Parent = settingsPage, Size = UDim2.new(0,260,0,120), Position = UDim2.new(1,-290,0,24), BackgroundColor3 = Color3.fromRGB(98,40,210), BackgroundTransparency = main.BackgroundTransparency, BorderSizePixel = 0}, settingsPage)
New("UICorner", {CornerRadius = UDim.new(0,12)}, preview)
local applyBtn = New("TextButton", {Parent = settingsPage, Size = UDim2.new(0,160,0,40), Position = UDim2.new(1,-290,0,156), BackgroundColor3 = Color3.fromRGB(95,35,200), Font = Enum.Font.GothamBold, Text = "Apply", TextSize = 16, TextColor3 = Color3.fromRGB(245,245,245)}, settingsPage)
New("UICorner", {CornerRadius = UDim.new(0,10)}, applyBtn)

local resizer = New("ImageButton", {Parent = main, Size = UDim2.new(0,30,0,30), Position = UDim2.new(1,-36,1,-36), BackgroundTransparency = 1, ZIndex = 52}, main)
local resGrip = New("Frame", {Parent = resizer, Size = UDim2.new(1,1,1,1), BackgroundColor3 = Color3.fromRGB(150,50,210), BackgroundTransparency = 0.12}, resizer)
New("UICorner", {CornerRadius = UDim.new(0,8)}, resGrip)

local function centerPositionFor(size)
	local vp = workspace.CurrentCamera.ViewportSize
	local x = math.floor((vp.X - size.X.Offset)/2)
	local y = math.floor((vp.Y - size.Y.Offset)/2)
	return UDim2.new(0, x, 0, y)
end

local function openFromCenter()
	local targetW = player:GetAttribute("ESUI_MainW") or main.Size.X.Offset
	local targetH = player:GetAttribute("ESUI_MainH") or main.Size.Y.Offset
	local targetSize = UDim2.new(0, targetW, 0, targetH)
	local centerPos = centerPositionFor(targetSize)

	local startSize = UDim2.new(0,28,0,28)
	main.Size = startSize
	main.Position = centerPos
	main.Visible = true
	local tweenProps = {Size = targetSize, Position = centerPos}
	TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), tweenProps):Play()
end

local function closeToCenter()
	local cur = main.Size
	local endSize = UDim2.new(0,28,0,28)
	local centerPos = centerPositionFor(cur)
	TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Size = endSize, Position = centerPos}):Play()
	delay(0.22, function() main.Visible = false end)
end

local function saveState()
	player:SetAttribute("ESUI_ToggleX", toggle.Position.X.Scale)
	player:SetAttribute("ESUI_ToggleY", toggle.Position.Y.Scale)
	player:SetAttribute("ESUI_MainXOff", main.Position.X.Offset)
	player:SetAttribute("ESUI_MainYOff", main.Position.Y.Offset)
	player:SetAttribute("ESUI_MainW", main.Size.X.Offset)
	player:SetAttribute("ESUI_MainH", main.Size.Y.Offset)
	player:SetAttribute("ESUI_R", rS.get())
	player:SetAttribute("ESUI_G", gS.get())
	player:SetAttribute("ESUI_B", bS.get())
	player:SetAttribute("ESUI_A", aS.get())
	player:SetAttribute("ESUI_SelectedBase", selectedBase)
end

local function loadState()
	local tx = player:GetAttribute("ESUI_ToggleX")
	local ty = player:GetAttribute("ESUI_ToggleY")
	if type(tx)=="number" and type(ty)=="number" then toggle.Position = UDim2.new(tx,0,ty,0) end
	local mx = player:GetAttribute("ESUI_MainXOff")
	local my = player:GetAttribute("ESUI_MainYOff")
	local mw = player:GetAttribute("ESUI_MainW")
	local mh = player:GetAttribute("ESUI_MainH")
	if type(mw)=="number" and type(mh)=="number" then main.Size = UDim2.new(0,mw,0,mh) end
	if type(mx)=="number" and type(my)=="number" then main.Position = UDim2.new(0,mx,0,my) end
	local r = player:GetAttribute("ESUI_R"); local g = player:GetAttribute("ESUI_G"); local b = player:GetAttribute("ESUI_B"); local a = player:GetAttribute("ESUI_A")
	if type(r)=="number" and type(g)=="number" and type(b)=="number" then
		rS.set(r); gS.set(g); bS.set(b)
		aS.set((type(a)=="number") and a or math.floor((1-main.BackgroundTransparency)*100))
		local alpha = 1 - aS.get()/100
		main.BackgroundColor3 = Color3.fromRGB(r,g,b)
		main.BackgroundTransparency = alpha
		preview.BackgroundColor3 = Color3.fromRGB(r,g,b)
		preview.BackgroundTransparency = alpha
	end
	local sb = player:GetAttribute("ESUI_SelectedBase")
	if type(sb)=="string" then
		selectedBase = sb
		for _,bb in ipairs(baseButtons) do bb.BackgroundColor3 = (bb.Text==sb) and Color3.fromRGB(150,90,220) or Color3.fromRGB(95,45,170) end
	end
end

loadState()

local function updatePreview()
	local r,g,b = rS.get(), gS.get(), bS.get()
	local a = aS.get()
	preview.BackgroundColor3 = Color3.fromRGB(r,g,b)
	preview.BackgroundTransparency = 1 - a/100
end

rS.set(rS.get()); gS.set(gS.get()); bS.set(bS.get()); aS.set(aS.get())
updatePreview()

applyBtn.MouseButton1Click:Connect(function()
	local r,g,b = rS.get(), gS.get(), bS.get()
	local a = aS.get()
	main.BackgroundColor3 = Color3.fromRGB(r,g,b)
	main.BackgroundTransparency = 1 - a/100
	preview.BackgroundColor3 = Color3.fromRGB(r,g,b)
	preview.BackgroundTransparency = 1 - a/100
	saveState()
end)

local function pressAnim(btn)
	local orig = btn.Size
	local t1 = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Size = orig - UDim2.new(0,8,0,8)})
	t1:Play(); t1.Completed:Wait()
	TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = orig}):Play()
end

btnClose.MouseButton1Click:Connect(function() pressAnim(btnClose) closeToCenter() end)
btnMin.MouseButton1Click:Connect(function() pressAnim(btnMin) main.Visible = not main.Visible end)
collapseBtn.MouseButton1Click:Connect(function() pressAnim(collapseBtn) contentFrame.Visible = not contentFrame.Visible tabsFrame.Visible = not tabsFrame.Visible end)

local function toggleOpenClose()
	if main.Visible then closeToCenter() else openFromCenter() end
end

toggle.MouseButton1Click:Connect(function() pressAnim(toggle) toggleOpenClose() end)

local function MakeDraggable(control, area, clamp)
	local dragging = false; local dragStart; local startPos; local dragInput
	area.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = control.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	area.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
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
			saveState()
		end
	end)
end

MakeDraggable(main, topBar, true)

local draggingToggle = false; local tStart; local tPos; local tInput
toggle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingToggle = true; tStart = input.Position; tPos = toggle.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then draggingToggle = false end end)
	end
end)
toggle.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then tInput = input end end)
UserInputService.InputChanged:Connect(function(input)
	if draggingToggle and input == tInput then
		local delta = input.Position - tStart
		local vp = workspace.CurrentCamera.ViewportSize
		local newX = math.clamp(tPos.X.Scale + delta.X / vp.X, 0, 1)
		local newY = math.clamp(tPos.Y.Scale + delta.Y / vp.Y, 0, 1)
		toggle.Position = UDim2.new(newX, 0, newY, 0)
		saveState()
	end
end)

local resizing = false; local resStart; local resSize; local resInput
resizer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true; resStart = input.Position; resSize = main.Size
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then resizing = false end end)
	end
end)
resizer.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then resInput = input end end)
UserInputService.InputChanged:Connect(function(input)
	if resizing and input == resInput then
		local delta = input.Position - resStart
		local newW = math.clamp(resSize.X.Offset + delta.X, 360, 1400)
		local newH = math.clamp(resSize.Y.Offset + delta.Y, 260, 980)
		main.Size = UDim2.new(0, newW, 0, newH)
		saveState()
	end
end)

execBtn.MouseButton1Click:Connect(function()
	local code = execBox.Text or ""
	execStatus.Text = "Simulating execution via "..selectedBase.."..."
	print("[SIM] base:", selectedBase)
	print("[SIM] preview:", string.sub(code,1,400))
	TweenService:Create(execBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0.6}):Play()
	delay(0.12, function() TweenService:Create(execBtn, TweenInfo.new(0.18), {BackgroundTransparency = 0}):Play() end)
	delay(1.1, function() execStatus.Text = "Ready. (Simulation done)" end)
end)

execBox.Focused:Connect(function()
	local vp = workspace.CurrentCamera.ViewportSize
	if main.AbsoluteSize.Y == 0 then main:GetPropertyChangedSignal("AbsoluteSize"):Wait() end
	if main.AbsoluteSize.Y > vp.Y - 160 then
		local shiftY = -(main.AbsoluteSize.Y - (vp.Y - 160))
		TweenService:Create(main, TweenInfo.new(0.18), {Position = main.Position + UDim2.new(0,0,0,shiftY)}):Play()
	else
		TweenService:Create(main, TweenInfo.new(0.18), {Position = main.Position + UDim2.new(0,0,0,-80)}):Play()
	end
end)
execBox.FocusLost:Connect(function() saveState() end)

RunService.Heartbeat:Connect(function() updatePreview() end)

openFromCenter()
