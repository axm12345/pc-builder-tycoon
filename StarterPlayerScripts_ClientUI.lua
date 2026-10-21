--[[
	ClientUI (LocalScript)
	PLACE THIS IN: StarterPlayer > StarterPlayerScripts
	RENAME TO: ClientUI

	Builds the entire UI purely from code -- Shop tab, My Build tab, and the
	Client Requests board -- so there's nothing to hand-build in Studio.
	This is intentionally simple/functional so it's easy to reskin later
	once you want to make it match your room-customization art style.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PCPartsData = require(ReplicatedStorage:WaitForChild("PCPartsData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyPartEvent        = Remotes:WaitForChild("BuyPart")
local AssemblePartEvent   = Remotes:WaitForChild("AssemblePart")
local NewRequestEvent     = Remotes:WaitForChild("NewRequest")
local FulfillRequestEvent = Remotes:WaitForChild("FulfillRequest")
local NotifyEvent         = Remotes:WaitForChild("Notify")
local SyncDataEvent       = Remotes:WaitForChild("SyncData")

----------------------------------------------------------------------
-- State mirrored from the server
----------------------------------------------------------------------
local state = {
	cash = 0,
	owned = {},
	assembled = {},
	currentRequest = nil,
}

----------------------------------------------------------------------
-- Base GUI
----------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PCBuilderUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 560, 0, 400)
mainFrame.Position = UDim2.new(0.5, -280, 1, -420)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainFrame

-- Top bar: cash display + tab buttons
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 44)
topBar.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = topBar

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(0, 140, 1, 0)
cashLabel.Position = UDim2.new(0, 12, 0, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextSize = 18
cashLabel.TextColor3 = Color3.fromRGB(90, 220, 120)
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Text = "$0"
cashLabel.Parent = topBar

local tabNames = { "Shop", "My Build", "Requests" }
local tabButtons = {}
local contentPages = {}

local tabsHolder = Instance.new("Frame")
tabsHolder.Size = UDim2.new(0, 330, 1, 0)
tabsHolder.Position = UDim2.new(1, -342, 0, 0)
tabsHolder.BackgroundTransparency = 1
tabsHolder.Parent = topBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
tabLayout.Parent = tabsHolder

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -16, 1, -56)
contentArea.Position = UDim2.new(0, 8, 0, 50)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

local function showTab(name)
	for tabName, page in pairs(contentPages) do
		page.Visible = (tabName == name)
	end
	for tabName, btn in pairs(tabButtons) do
		btn.BackgroundColor3 = (tabName == name)
			and Color3.fromRGB(70, 120, 220)
			or Color3.fromRGB(40, 40, 46)
	end
end

for _, name in ipairs(tabNames) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 100, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(240, 240, 240)
	btn.Text = name
	btn.Parent = tabsHolder

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	btn.MouseButton1Click:Connect(function()
		showTab(name)
	end)

	tabButtons[name] = btn
end

----------------------------------------------------------------------
-- SHOP PAGE
----------------------------------------------------------------------
local shopPage = Instance.new("ScrollingFrame")
shopPage.Size = UDim2.new(1, 0, 1, 0)
shopPage.BackgroundTransparency = 1
shopPage.ScrollBarThickness = 6
shopPage.CanvasSize = UDim2.new(0, 0, 0, 0)
shopPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopPage.Parent = contentArea
contentPages["Shop"] = shopPage

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 10)
shopLayout.Parent = shopPage

local partButtons = {} -- partButtons[category][partId] = { buyBtn, equipBtn }

local function categoryColor(category)
	local colors = {
		CPU = Color3.fromRGB(220, 90, 90),
		GPU = Color3.fromRGB(90, 180, 220),
		RAM = Color3.fromRGB(200, 180, 90),
		Case = Color3.fromRGB(140, 140, 150),
		RGB = Color3.fromRGB(200, 90, 220),
	}
	return colors[category] or Color3.fromRGB(150, 150, 150)
end

for _, category in ipairs(PCPartsData.Categories) do
	local sectionLabel = Instance.new("TextLabel")
	sectionLabel.Size = UDim2.new(1, 0, 0, 24)
	sectionLabel.BackgroundTransparency = 1
	sectionLabel.Font = Enum.Font.GothamBold
	sectionLabel.TextSize = 16
	sectionLabel.TextColor3 = categoryColor(category)
	sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	sectionLabel.Text = category
	sectionLabel.LayoutOrder = 1
	sectionLabel.Parent = shopPage

	partButtons[category] = {}

	for i, part in ipairs(PCPartsData.Parts[category]) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
		row.LayoutOrder = i + 1
		row.Parent = shopPage

		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 8)
		rc.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.45, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextSize = 13
		nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = part.name .. "  (PWR " .. part.power .. " / STY " .. part.style .. ")"
		nameLabel.Parent = row

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 90, 0, 28)
		buyBtn.Position = UDim2.new(1, -200, 0.5, -14)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextSize = 12
		buyBtn.Text = part.price == 0 and "Owned" or ("Buy $" .. part.price)
		buyBtn.BackgroundColor3 = Color3.fromRGB(70, 160, 90)
		buyBtn.TextColor3 = Color3.new(1, 1, 1)
		buyBtn.Parent = row
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = buyBtn

		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(0, 90, 0, 28)
		equipBtn.Position = UDim2.new(1, -100, 0.5, -14)
		equipBtn.Font = Enum.Font.GothamBold
		equipBtn.TextSize = 12
		equipBtn.Text = "Equip"
		equipBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 220)
		equipBtn.TextColor3 = Color3.new(1, 1, 1)
		equipBtn.Parent = row
		local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0, 6); ec.Parent = equipBtn

		buyBtn.MouseButton1Click:Connect(function()
			BuyPartEvent:FireServer(category, part.id)
		end)

		equipBtn.MouseButton1Click:Connect(function()
			AssemblePartEvent:FireServer(category, part.id)
		end)

		partButtons[category][part.id] = { buyBtn = buyBtn, equipBtn = equipBtn, price = part.price }
	end
end

----------------------------------------------------------------------
-- MY BUILD PAGE
----------------------------------------------------------------------
local buildPage = Instance.new("Frame")
buildPage.Size = UDim2.new(1, 0, 1, 0)
buildPage.BackgroundTransparency = 1
buildPage.Visible = false
buildPage.Parent = contentArea
contentPages["My Build"] = buildPage

local buildLayout = Instance.new("UIListLayout")
buildLayout.Padding = UDim.new(0, 8)
buildLayout.Parent = buildPage

local buildStatLabel = Instance.new("TextLabel")
buildStatLabel.Size = UDim2.new(1, 0, 0, 40)
buildStatLabel.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
buildStatLabel.Font = Enum.Font.GothamBold
buildStatLabel.TextSize = 16
buildStatLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
buildStatLabel.Text = "Power: 0   |   Style: 0"
buildStatLabel.Parent = buildPage
local bslc = Instance.new("UICorner"); bslc.CornerRadius = UDim.new(0, 8); bslc.Parent = buildStatLabel

local currentPartsLabels = {}
for _, category in ipairs(PCPartsData.Categories) do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.Gotham
	row.TextSize = 14
	row.TextColor3 = categoryColor(category)
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Text = category .. ": --"
	row.Parent = buildPage
	currentPartsLabels[category] = row
end

----------------------------------------------------------------------
-- REQUESTS PAGE
----------------------------------------------------------------------
local requestsPage = Instance.new("Frame")
requestsPage.Size = UDim2.new(1, 0, 1, 0)
requestsPage.BackgroundTransparency = 1
requestsPage.Visible = false
requestsPage.Parent = contentArea
contentPages["Requests"] = requestsPage

local requestCard = Instance.new("Frame")
requestCard.Size = UDim2.new(1, 0, 0, 220)
requestCard.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
requestCard.Parent = requestsPage
local rcc = Instance.new("UICorner"); rcc.CornerRadius = UDim.new(0, 10); rcc.Parent = requestCard

local clientNameLabel = Instance.new("TextLabel")
clientNameLabel.Size = UDim2.new(1, -20, 0, 26)
clientNameLabel.Position = UDim2.new(0, 10, 0, 8)
clientNameLabel.BackgroundTransparency = 1
clientNameLabel.Font = Enum.Font.GothamBold
clientNameLabel.TextSize = 16
clientNameLabel.TextColor3 = Color3.fromRGB(90, 180, 255)
clientNameLabel.TextXAlignment = Enum.TextXAlignment.Left
clientNameLabel.Text = "No client message yet..."
clientNameLabel.Parent = requestCard

local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, -20, 0, 80)
messageLabel.Position = UDim2.new(0, 10, 0, 36)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextSize = 14
messageLabel.TextWrapped = true
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.Text = ""
messageLabel.Parent = requestCard

local reqStatsLabel = Instance.new("TextLabel")
reqStatsLabel.Size = UDim2.new(1, -20, 0, 40)
reqStatsLabel.Position = UDim2.new(0, 10, 0, 118)
reqStatsLabel.BackgroundTransparency = 1
reqStatsLabel.Font = Enum.Font.GothamBold
reqStatsLabel.TextSize = 14
reqStatsLabel.TextColor3 = Color3.fromRGB(240, 200, 90)
reqStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
reqStatsLabel.Text = ""
reqStatsLabel.Parent = requestCard

local fulfillBtn = Instance.new("TextButton")
fulfillBtn.Size = UDim2.new(0, 200, 0, 40)
fulfillBtn.Position = UDim2.new(0, 10, 1, -50)
fulfillBtn.Font = Enum.Font.GothamBold
fulfillBtn.TextSize = 15
fulfillBtn.Text = "Deliver Build"
fulfillBtn.BackgroundColor3 = Color3.fromRGB(70, 160, 90)
fulfillBtn.TextColor3 = Color3.new(1, 1, 1)
fulfillBtn.Parent = requestCard
local fbc = Instance.new("UICorner"); fbc.CornerRadius = UDim.new(0, 8); fbc.Parent = fulfillBtn

fulfillBtn.MouseButton1Click:Connect(function()
	FulfillRequestEvent:FireServer()
end)

----------------------------------------------------------------------
-- Toast notifications
----------------------------------------------------------------------
local function showToast(text)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(0, 320, 0, 40)
	toast.Position = UDim2.new(0.5, -160, 0, 20)
	toast.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 13
	toast.TextWrapped = true
	toast.Text = text
	toast.BackgroundTransparency = 0.1
	toast.Parent = screenGui
	local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 8); tc.Parent = toast

	task.delay(3, function()
		local tween = TweenService:Create(toast, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		toast:Destroy()
	end)
end

----------------------------------------------------------------------
-- Render state -> UI
----------------------------------------------------------------------
local function render()
	cashLabel.Text = "$" .. state.cash

	-- Shop buttons: show Owned/Equipped where relevant
	for category, parts in pairs(partButtons) do
		for partId, btns in pairs(parts) do
			local owned = state.owned[category] and state.owned[category][partId]
			local equipped = state.assembled[category] == partId

			if owned then
				btns.buyBtn.Text = "Owned"
				btns.buyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
			else
				btns.buyBtn.Text = btns.price == 0 and "Free" or ("Buy $" .. btns.price)
				btns.buyBtn.BackgroundColor3 = Color3.fromRGB(70, 160, 90)
			end

			btns.equipBtn.Text = equipped and "Equipped" or "Equip"
			btns.equipBtn.BackgroundColor3 = equipped and Color3.fromRGB(90, 90, 200) or Color3.fromRGB(70, 120, 220)
		end
	end

	-- My Build page
	local totalPower, totalStyle = 0, 0
	for _, category in ipairs(PCPartsData.Categories) do
		local partId = state.assembled[category]
		local part = partId and PCPartsData.GetPart(category, partId)
		if part then
			totalPower += part.power
			totalStyle += part.style
			currentPartsLabels[category].Text = category .. ": " .. part.name
		else
			currentPartsLabels[category].Text = category .. ": --"
		end
	end
	buildStatLabel.Text = ("Power: %d   |   Style: %d"):format(totalPower, totalStyle)

	-- Requests page
	if state.currentRequest then
		local req = state.currentRequest
		clientNameLabel.Text = req.clientName .. "  [" .. req.tierName .. "]"
		messageLabel.Text = req.message
		reqStatsLabel.Text = ("Needs: Power >= %d, Style >= %d   |   Reward: $%d"):format(req.needPower, req.needStyle, req.reward)
	else
		clientNameLabel.Text = "No active request"
		messageLabel.Text = "Check back soon -- a new client will message you shortly."
		reqStatsLabel.Text = ""
	end
end

----------------------------------------------------------------------
-- Remote listeners
----------------------------------------------------------------------
SyncDataEvent.OnClientEvent:Connect(function(data)
	state.cash = data.cash
	state.owned = data.owned
	state.assembled = data.assembled
	state.currentRequest = data.currentRequest
	render()
end)

NewRequestEvent.OnClientEvent:Connect(function(request)
	state.currentRequest = request
	render()
	showToast(request.clientName .. " sent you a message!")
end)

NotifyEvent.OnClientEvent:Connect(function(text)
	showToast(text)
end)

showTab("Shop")
render()
