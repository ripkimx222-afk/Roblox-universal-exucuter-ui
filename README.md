local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

local toggle = Instance.new("TextButton", ScreenGui)
toggle.Size = UDim2.new(0,60,0,60)
toggle.Position = UDim2.new(0.05,0,0.5,0)
toggle.BackgroundColor3 = Color3.fromRGB(150,0,255)
toggle.Text = "Toggle"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.GothamBold
toggle.TextScaled = true
toggle.AutoButtonColor = false
toggle.BackgroundTransparency = 0.1
toggle.ClipsDescendants = true
toggle.ZIndex = 2
Instance.new("UICorner", toggle).CornerRadius = UDim.new(1,0)

local main = Instance.new("Frame", ScreenGui)
main.Size = UDim2.new(0,350,0,300)
main.Position = UDim2.new(0.5,-175,0.5,-150)
main.BackgroundColor3 = Color3.fromRGB(100,0,200)
main.BackgroundTransparency = 0.15
main.Visible = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0,20)

local dragBar = Instance.new("Frame", main)
dragBar.Size = UDim2.new(1,0,0,40)
dragBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", dragBar)
title.Size = UDim2.new(1,0,1,0)
title.BackgroundTransparency = 1
title.Text = "Electron"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextScaled = true

local subTitle = Instance.new("TextLabel", main)
subTitle.Size = UDim2.new(1,0,0,20)
subTitle.Position = UDim2.new(0,0,0,40)
subTitle.BackgroundTransparency = 1
subTitle.Text = "by Hikmes0"
subTitle.TextColor3 = Color3.fromRGB(200,200,200)
subTitle.Font = Enum.Font.Gotham
subTitle.TextScaled = true

local scriptBox = Instance.new("TextBox", main)
scriptBox.Size = UDim2.new(1,-20,0,120)
scriptBox.Position = UDim2.new(0,10,0,70)
scriptBox.BackgroundColor3 = Color3.fromRGB(50,0,100)
scriptBox.BackgroundTransparency = 0.2
scriptBox.TextColor3 = Color3.new(1,1,1)
scriptBox.ClearTextOnFocus = false
scriptBox.TextXAlignment = Enum.TextXAlignment.Left
scriptBox.TextYAlignment = Enum.TextYAlignment.Top
scriptBox.MultiLine = true
scriptBox.TextWrapped = true
scriptBox.TextScaled = true
Instance.new("UICorner", scriptBox).CornerRadius = UDim.new(0,12)

local executeBtn = Instance.new("TextButton", main)
executeBtn.Size = UDim2.new(0.4,0,0,40)
executeBtn.Position = UDim2.new(0.05,0,1,-50)
executeBtn.BackgroundColor3 = Color3.fromRGB(150,0,255)
executeBtn.Text = "Execute"
executeBtn.TextColor3 = Color3.new(1,1,1)
executeBtn.Font = Enum.Font.GothamBold
executeBtn.TextScaled = true
executeBtn.AutoButtonColor = true
Instance.new("UICorner", executeBtn).CornerRadius = UDim.new(0,12)

local settingsBtn = Instance.new("TextButton", main)
settingsBtn.Size = UDim2.new(0.4,0,0,40)
settingsBtn.Position = UDim2.new(0.55,0,1,-50)
settingsBtn.BackgroundColor3 = Color3.fromRGB(90,0,160)
settingsBtn.Text = "Settings"
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.TextScaled = true
settingsBtn.AutoButtonColor = true
Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0,12)

local settingsFrame = Instance.new("Frame", main)
settingsFrame.Size = UDim2.new(1,-40,0,100)
settingsFrame.Position = UDim2.new(0,20,0,200)
settingsFrame.BackgroundColor3 = Color3.fromRGB(70,0,130)
settingsFrame.Visible = false
Instance.new("UICorner", settingsFrame).CornerRadius = UDim.new(0,15)

local injectorOption = Instance.new("TextButton", settingsFrame)
injectorOption.Size = UDim2.new(1,0,0,25)
injectorOption.Position = UDim2.new(0,0,0,10)
injectorOption.BackgroundTransparency = 1
injectorOption.TextColor3 = Color3.new(1,1,1)
injectorOption.Text = "Injector: Electron"
injectorOption.Font = Enum.Font.Gotham
injectorOption.TextScaled = true

local currentInjector = "Electron"
local injectors = {"Electron","XENO","DELTA X","KRNL","Arceus X"}
local index = 1

injectorOption.MouseButton1Click:Connect(function()
	index = index + 1
	if index > #injectors then index = 1 end
	currentInjector = injectors[index]
	injectorOption.Text = "Injector: "..currentInjector
end)

local function toggleUI()
	if main.Visible then
		TweenService:Create(main, TweenInfo.new(0.25,Enum.EasingStyle.Sine,Enum.EasingDirection.Out), {Size=UDim2.new(0,350,0,0)}):Play()
		wait(0.25)
		main.Visible = false
	else
		main.Visible = true
		main.Size = UDim2.new(0,350,0,0)
		TweenService:Create(main, TweenInfo.new(0.25,Enum.EasingStyle.Sine,Enum.EasingDirection.Out), {Size=UDim2.new(0,350,0,300)}):Play()
	end
end

toggle.MouseButton1Click:Connect(toggleUI)

local dragging,dragInput,dragStart,startPos
local function update(input,frame)
	local delta = input.Position - dragStart
	local vp = workspace.CurrentCamera.ViewportSize
	local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
	newPos = UDim2.new(newPos.X.Scale, math.clamp(newPos.X.Offset,0,vp.X-frame.AbsoluteSize.X), newPos.Y.Scale, math.clamp(newPos.Y.Offset,0,vp.Y-frame.AbsoluteSize.Y))
	frame.Position = newPos
end

local function enableDrag(frame,button)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	button.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input,frame) end
	end)
end

enableDrag(main,dragBar)
enableDrag(toggle,toggle)

settingsBtn.MouseButton1Click:Connect(function()
	settingsFrame.Visible = not settingsFrame.Visible
end)

scriptBox.Focused:Connect(function()
	TweenService:Create(main,TweenInfo.new(0.2),{Position=main.Position-UDim2.new(0,0,0,80)}):Play()
end)
scriptBox.FocusLost:Connect(function()
	TweenService:Create(main,TweenInfo.new(0.2),{Position=UDim2.new(0.5,-175,0.5,-150)}):Play()
end)
