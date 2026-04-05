--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// STATES
local VALID_KEY = "FREE_KEY"
local keyVerified = false
local premiumKeyValid = false

local espEnabled = true
local espSettings = {
	hitbox=false, health=true, distance=true,
	wall=true, highlight=true, id=false, name=true
}

local noclipEnabled = false
local espCache = {}

local aiMode = "NORMAL"
local aiRunning = false
local aiCooldown = {}

--// BLUR
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 12
blur.Enabled = false

--// GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false

--========================
-- 🥀 MINI ICON
--========================
local mini = Instance.new("TextButton", gui)
mini.Size = UDim2.new(0,60,0,60)
mini.Position = UDim2.new(0,20,1,-80)
mini.Text = "🥀"
mini.Visible = false

local dragging=false local dragStart local startPos

mini.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 then
		dragging=true dragStart=i.Position startPos=mini.Position
	end
end)

mini.InputEnded:Connect(function() dragging=false end)

UIS.InputChanged:Connect(function(i)
	if dragging then
		local d=i.Position-dragStart
		mini.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end
end)

--========================
-- 🔔 NOTIFY
--========================
local function notify(msg)
	local n=Instance.new("TextLabel",gui)
	n.Size=UDim2.new(0,260,0,40)
	n.Position=UDim2.new(0.5,-130,0.8,0)
	n.BackgroundColor3=Color3.fromRGB(30,30,30)
	n.TextColor3=Color3.new(1,1,1)
	n.Text=msg
	task.delay(2,function() if n then n:Destroy() end end)
end

--========================
-- 🔐 KEY UI
--========================
local keyFrame=Instance.new("Frame",gui)
keyFrame.Size=UDim2.new(0,300,0,180)
keyFrame.Position=UDim2.new(0.5,-150,0.5,-90)

local keyBox=Instance.new("TextBox",keyFrame)
keyBox.Size=UDim2.new(0.8,0,0,40)
keyBox.Position=UDim2.new(0.1,0,0.4,0)

local keyBtn=Instance.new("TextButton",keyFrame)
keyBtn.Size=UDim2.new(0.8,0,0,40)
keyBtn.Position=UDim2.new(0.1,0,0.7,0)
keyBtn.Text="Unlock"

local keyClose=Instance.new("TextButton",keyFrame)
keyClose.Size=UDim2.new(0,30,0,30)
keyClose.Position=UDim2.new(1,-35,0,5)
keyClose.Text="X"

--========================
-- 🖥 MAIN UI
--========================
local main=Instance.new("Frame",gui)
main.Size=UDim2.new(0,600,0,320)
main.Position=UDim2.new(0.5,-300,0.5,-160)
main.Visible=false

local close=Instance.new("TextButton",main)
close.Size=UDim2.new(0,30,0,30)
close.Position=UDim2.new(1,-35,0,5)
close.Text="—"

local sidebar=Instance.new("Frame",main)
sidebar.Size=UDim2.new(0,150,1,-40)
sidebar.Position=UDim2.new(0,0,0,40)

local content=Instance.new("Frame",main)
content.Size=UDim2.new(1,-150,1,-40)
content.Position=UDim2.new(0,150,0,40)

--========================
-- 🎨 TOGGLE
--========================
local function createToggle(parent,name,state,callback)
	local btn=Instance.new("TextButton",parent)
	btn.Size=UDim2.new(1,0,0,30)

	local function update()
		btn.Text=name.." : "..(state and "ON" or "OFF")
		btn.BackgroundColor3=state and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
	end

	update()

	btn.MouseButton1Click:Connect(function()
		state=not state
		update()
		callback(state)
	end)
end

--========================
-- 🔴 ESP
--========================
local function clearESP(c)
	if espCache[c] then
		for _,v in pairs(espCache[c]) do v:Destroy() end
	end
	espCache[c]=nil
end

local function createESP(plr,c)
	if not espEnabled or espCache[c] then return end
	
	local hum=c:FindFirstChildOfClass("Humanoid")
	local head=c:FindFirstChild("Head")
	local root=c:FindFirstChild("HumanoidRootPart")
	if not hum or not head or not root then return end

	local objs={}

	if espSettings.highlight then
		local hl=Instance.new("Highlight",c)
		hl.DepthMode=espSettings.wall and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
		table.insert(objs,hl)
	end

	if espSettings.name or espSettings.health or espSettings.distance then
		local bill=Instance.new("BillboardGui",head)
		bill.Size=UDim2.new(0,200,0,50)
		bill.AlwaysOnTop=true

		local txt=Instance.new("TextLabel",bill)
		txt.Size=UDim2.new(1,0,1,0)
		txt.BackgroundTransparency=1

		RunService.RenderStepped:Connect(function()
			local info={}
			if espSettings.name then table.insert(info,plr.Name) end
			if espSettings.health then table.insert(info,"HP:"..math.floor(hum.Health)) end
			if espSettings.distance and player.Character then
				local myRoot=player.Character:FindFirstChild("HumanoidRootPart")
				if myRoot then
					table.insert(info,math.floor((myRoot.Position-root.Position).Magnitude).."m")
				end
			end
			txt.Text=table.concat(info," | ")
		end)

		table.insert(objs,bill)
	end

	espCache[c]=objs
end

local function refreshESP()
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=player and plr.Character then
			clearESP(plr.Character)
			createESP(plr,plr.Character)
		end
	end
end

--========================
-- 🧠 AI
--========================
local function startAI()
	RunService.RenderStepped:Connect(function()
		if not aiRunning then return end
		
		local myRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not myRoot then return end

		for _,plr in ipairs(Players:GetPlayers()) do
			if plr~=player and plr.Character then
				local root=plr.Character:FindFirstChild("HumanoidRootPart")
				local head=plr.Character:FindFirstChild("Head")
				if root and head then
					local dist=(myRoot.Position-root.Position).Magnitude

					if dist<25 and not aiCooldown[plr] then
						aiCooldown[plr]=tick()
						notify("⚠ "..plr.Name.." gần bạn")
					end

					local dot=head.CFrame.LookVector:Dot((myRoot.Position-head.Position).Unit)
					if dot>0.8 and not aiCooldown[plr.."aim"] then
						aiCooldown[plr.."aim"]=tick()
						notify("🎯 "..plr.Name.." nhắm bạn")
					end
				end
			end
		end

		for k,v in pairs(aiCooldown) do
			if tick()-v>3 then aiCooldown[k]=nil end
		end
	end)
end

--========================
-- 🎯 CAMERA (FIX FULL)
--========================
local currentSpectate=nil

local function spectate(plr)
	if plr and plr.Character then
		local hum=plr.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			currentSpectate=plr
			camera.CameraType=Enum.CameraType.Custom
			camera.CameraSubject=hum
		end
	end
end

local function returnToSelf()
	local char=player.Character
	if not char then return end

	local hum=char:FindFirstChildOfClass("Humanoid")
	if hum then
		currentSpectate=nil
		camera.CameraType=Enum.CameraType.Custom
		camera.CameraSubject=hum
		task.wait()
		camera.CameraSubject=hum
	end
end

player.CharacterAdded:Connect(function()
	task.wait(0.3)
	returnToSelf()
end)

--========================
-- 🧊 NOCLIP
--========================
RunService.Stepped:Connect(function()
	if noclipEnabled and player.Character then
		for _,v in pairs(player.Character:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide=false end
		end
	end
end)

--========================
-- TAB
--========================
local function createTab(name,y,func)
	local btn=Instance.new("TextButton",sidebar)
	btn.Size=UDim2.new(1,0,0,35)
	btn.Position=UDim2.new(0,0,0,y)
	btn.Text=name
	btn.MouseButton1Click:Connect(func)
end

-- ESP
createTab("ESP",0,function()
	content:ClearAllChildren()
	Instance.new("UIListLayout",content)

	createToggle(content,"ESP",espEnabled,function(v) espEnabled=v refreshESP() end)
	createToggle(content,"Hitbox",espSettings.hitbox,function(v) espSettings.hitbox=v refreshESP() end)
	createToggle(content,"Máu",espSettings.health,function(v) espSettings.health=v refreshESP() end)
	createToggle(content,"Khoảng cách",espSettings.distance,function(v) espSettings.distance=v refreshESP() end)
	createToggle(content,"Xuyên tường",espSettings.wall,function(v) espSettings.wall=v refreshESP() end)
	createToggle(content,"Highlight",espSettings.highlight,function(v) espSettings.highlight=v refreshESP() end)
	createToggle(content,"ID",espSettings.id,function(v) espSettings.id=v refreshESP() end)
	createToggle(content,"Tên",espSettings.name,function(v) espSettings.name=v refreshESP() end)
end)

-- AI
createTab("A.I",70,function()
	content:ClearAllChildren()
	Instance.new("UIListLayout",content)

	local mode=Instance.new("TextButton",content)
	mode.Size=UDim2.new(1,0,0,30)
	mode.Text="Mode: "..aiMode

	mode.MouseButton1Click:Connect(function()
		aiMode=(aiMode=="NORMAL") and "PREMIUM" or "NORMAL"
		mode.Text="Mode: "..aiMode
	end)

	if aiMode=="PREMIUM" then
		local txt=Instance.new("TextLabel",content)
		txt.Size=UDim2.new(1,0,1,0)
		txt.Text="🤖 AI PRO\nUpdate Soon..."
		txt.BackgroundTransparency=1
		return
	end

	createToggle(content,"AI",aiRunning,function(v)
		aiRunning=v
		if v then startAI() end
	end)
end)

-- CAMERA
createTab("Camera",140,function()
	content:ClearAllChildren()
	Instance.new("UIListLayout",content)

	local back=Instance.new("TextButton",content)
	back.Size=UDim2.new(1,0,0,35)
	back.Text="🔙 Quay về bản thân"
	back.BackgroundColor3=Color3.fromRGB(0,120,0)
	back.MouseButton1Click:Connect(returnToSelf)

	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=player then
			local b=Instance.new("TextButton",content)
			b.Size=UDim2.new(1,0,0,30)
			b.Text="👁 "..plr.Name
			b.MouseButton1Click:Connect(function() spectate(plr) end)
		end
	end
end)

-- NOCLIP
createTab("Noclip",175,function()
	content:ClearAllChildren()
	Instance.new("UIListLayout",content)

	createToggle(content,"Noclip",noclipEnabled,function(v)
		noclipEnabled=v
	end)
end)

-- PREMIUM
createTab("Premium",210,function()
	content:ClearAllChildren()
	Instance.new("UIListLayout",content)

	local status=Instance.new("TextLabel",content)
	status.Size=UDim2.new(1,0,0,40)
	status.BackgroundTransparency=1

	local box=Instance.new("TextBox",content)
	box.Size=UDim2.new(1,0,0,35)
	box.PlaceholderText="Nhập premium key..."

	local btn=Instance.new("TextButton",content)
	btn.Size=UDim2.new(1,0,0,35)
	btn.Text="Xác nhận"

	local function update()
		if premiumKeyValid then
			status.Text="⏳ Premium: Đợi cập nhật..."
		else
			status.Text="🔒 Premium: Locked"
		end
	end

	update()

	btn.MouseButton1Click:Connect(function()
		if box.Text=="PREMIUM_KEY" then
			premiumKeyValid=true
			update()
			notify("⏳ Đợi bản cập nhật Premium")
		else
			notify("❌ Sai key")
		end
	end)
end)

--========================
-- KEY LOGIC
--========================
keyBtn.MouseButton1Click:Connect(function()
	if keyBox.Text==VALID_KEY then
		keyVerified=true
		keyFrame.Visible=false
		main.Visible=true
		blur.Enabled=true
	else
		notify("Sai key")
	end
end)

keyClose.MouseButton1Click:Connect(function()
	keyFrame.Visible=false
	mini.Visible=true
end)

mini.MouseButton1Click:Connect(function()
	mini.Visible=false
	if keyVerified then
		main.Visible=true
	else
		keyFrame.Visible=true
	end
end)

close.MouseButton1Click:Connect(function()
	main.Visible=false
	mini.Visible=true
	blur.Enabled=false
end)
