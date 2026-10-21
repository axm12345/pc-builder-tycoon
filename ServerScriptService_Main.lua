--[[
	Main (Script)
	PLACE THIS IN: ServerScriptService
	RENAME TO: Main

	This is the brain of the game. It:
	  1. Sets up leaderstats (Cash) for every player
	  2. Loads/saves player data with DataStoreService
	  3. Creates the RemoteEvents players need (no manual Studio setup needed)
	  4. Handles buying parts, assembling a PC, and fulfilling client requests
	  5. Runs the "client hustle" loop -- periodically sends each player a
	     random request they can fulfill for cash

	NOTE: DataStores don't work in Studio's default "Play" mode unless you
	enable API Services: Home > Game Settings > Security > "Enable Studio
	Access to API Services". Turn that on or saving will silently fail.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local PCPartsData = require(ReplicatedStorage:WaitForChild("PCPartsData"))
local RequestsData = require(ReplicatedStorage:WaitForChild("RequestsData"))

local PlayerDataStore = DataStoreService:GetDataStore("PCBuilderTycoon_v1")

----------------------------------------------------------------------
-- Remote Events (created here so you don't have to build them by hand)
----------------------------------------------------------------------
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function newRemote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	return r
end

local BuyPartEvent        = newRemote("BuyPart")        -- client -> server
local AssemblePartEvent   = newRemote("AssemblePart")   -- client -> server
local NewRequestEvent     = newRemote("NewRequest")     -- server -> client
local FulfillRequestEvent = newRemote("FulfillRequest") -- client -> server
local NotifyEvent         = newRemote("Notify")         -- server -> client (toast messages)
local SyncDataEvent       = newRemote("SyncData")       -- server -> client (full state refresh)

----------------------------------------------------------------------
-- In-memory player state: profiles[player] = {
--   cash = number,
--   owned = { CPU = {[partId]=true, ...}, GPU = {...}, ... },
--   assembled = { CPU = partId, GPU = partId, RAM = partId, Case = partId, RGB = partId },
--   currentRequest = { clientName, message, tierName, needPower, needStyle, reward } or nil,
-- }
----------------------------------------------------------------------
local profiles = {}

local function computeTotals(assembled)
	local totalPower, totalStyle = 0, 0
	for category, partId in pairs(assembled) do
		local part = PCPartsData.GetPart(category, partId)
		if part then
			totalPower += part.power
			totalStyle += part.style
		end
	end
	return totalPower, totalStyle
end

local function pushFullSync(player)
	local profile = profiles[player]
	if not profile then return end
	SyncDataEvent:FireClient(player, {
		cash = profile.cash,
		owned = profile.owned,
		assembled = profile.assembled,
		currentRequest = profile.currentRequest,
	})
end

----------------------------------------------------------------------
-- Load / Save
----------------------------------------------------------------------
local function defaultProfile()
	local owned = {}
	for _, category in ipairs(PCPartsData.Categories) do
		owned[category] = { [PCPartsData.Parts[category][1].id] = true } -- everyone starts owning the free part
	end
	return {
		cash = 200, -- starting cash
		owned = owned,
		assembled = PCPartsData.GetDefaultLoadout(),
		currentRequest = nil,
	}
end

local function loadProfile(player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		profiles[player] = data
	else
		profiles[player] = defaultProfile()
	end
end

local function saveProfile(player)
	local profile = profiles[player]
	if not profile then return end
	pcall(function()
		PlayerDataStore:SetAsync("Player_" .. player.UserId, profile)
	end)
end

----------------------------------------------------------------------
-- Leaderstats (the little Cash label that shows in the Players list)
----------------------------------------------------------------------
local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = profiles[player].cash
	cash.Parent = leaderstats
end

local function refreshLeaderstat(player)
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Cash") then
		ls.Cash.Value = profiles[player].cash
	end
end

----------------------------------------------------------------------
-- Request generation (the "hustle" loop)
----------------------------------------------------------------------
local function pickTierForProfile(profile)
	-- Scale difficulty loosely to how strong the player's best owned parts are,
	-- so new players get Easy/Medium requests and veterans get Hard/Elite ones.
	local bestPower, bestStyle = 0, 0
	for category, ownedSet in pairs(profile.owned) do
		for partId in pairs(ownedSet) do
			local part = PCPartsData.GetPart(category, partId)
			if part then
				bestPower = math.max(bestPower, part.power)
				bestStyle = math.max(bestStyle, part.style)
			end
		end
	end

	local progressScore = bestPower + bestStyle
	if progressScore < 20 then
		return RequestsData.Tiers[1]
	elseif progressScore < 50 then
		return RequestsData.Tiers[math.random(1, 2)]
	elseif progressScore < 90 then
		return RequestsData.Tiers[math.random(2, 3)]
	else
		return RequestsData.Tiers[math.random(3, 4)]
	end
end

local function generateRequest(player)
	local profile = profiles[player]
	if not profile then return end

	local template = RequestsData.Templates[math.random(1, #RequestsData.Templates)]
	local tier = pickTierForProfile(profile)

	-- Compute rough max achievable totals right now to scale requirement sensibly
	local maxPower, maxStyle = 0, 0
	for _, category in ipairs(PCPartsData.Categories) do
		local list = PCPartsData.Parts[category]
		maxPower += list[#list].power
		maxStyle += list[#list].style
	end

	local needPower = template.focus == "power" and math.floor(maxPower * tier.powerMult) or math.floor(maxPower * tier.powerMult * 0.4)
	local needStyle = template.focus == "style" and math.floor(maxStyle * tier.styleMult) or math.floor(maxStyle * tier.styleMult * 0.4)

	profile.currentRequest = {
		clientName = template.clientName,
		message = template.message,
		tierName = tier.name,
		needPower = needPower,
		needStyle = needStyle,
		reward = tier.reward,
	}

	NewRequestEvent:FireClient(player, profile.currentRequest)
end

----------------------------------------------------------------------
-- Remote event handlers
----------------------------------------------------------------------
BuyPartEvent.OnServerEvent:Connect(function(player, category, partId)
	local profile = profiles[player]
	if not profile then return end

	local part = PCPartsData.GetPart(category, partId)
	if not part then return end

	profile.owned[category] = profile.owned[category] or {}
	if profile.owned[category][partId] then
		NotifyEvent:FireClient(player, "You already own that part.")
		return
	end

	if profile.cash < part.price then
		NotifyEvent:FireClient(player, "Not enough cash for " .. part.name .. ".")
		return
	end

	profile.cash -= part.price
	profile.owned[category][partId] = true
	refreshLeaderstat(player)
	pushFullSync(player)
	NotifyEvent:FireClient(player, "Bought " .. part.name .. "!")
end)

AssemblePartEvent.OnServerEvent:Connect(function(player, category, partId)
	local profile = profiles[player]
	if not profile then return end

	if not (profile.owned[category] and profile.owned[category][partId]) then
		NotifyEvent:FireClient(player, "You don't own that part yet.")
		return
	end

	profile.assembled[category] = partId
	pushFullSync(player)
end)

FulfillRequestEvent.OnServerEvent:Connect(function(player)
	local profile = profiles[player]
	if not (profile and profile.currentRequest) then return end

	local totalPower, totalStyle = computeTotals(profile.assembled)
	local req = profile.currentRequest

	if totalPower >= req.needPower and totalStyle >= req.needStyle then
		profile.cash += req.reward
		refreshLeaderstat(player)
		NotifyEvent:FireClient(player, ("%s paid you $%d! Thanks for the build."):format(req.clientName, req.reward))
		profile.currentRequest = nil
		pushFullSync(player)
		task.delay(3, function()
			if profiles[player] then
				generateRequest(player)
			end
		end)
	else
		NotifyEvent:FireClient(player, "Your PC doesn't meet this client's requirements yet. Upgrade some parts!")
	end
end)

----------------------------------------------------------------------
-- Player lifecycle
----------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	loadProfile(player)
	setupLeaderstats(player)
	pushFullSync(player)

	task.delay(5, function()
		if profiles[player] then
			generateRequest(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	saveProfile(player)
	profiles[player] = nil
end)

-- Autosave every 2 minutes in case of crashes/server shutdowns
task.spawn(function()
	while true do
		task.wait(120)
		for _, player in ipairs(Players:GetPlayers()) do
			saveProfile(player)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveProfile(player)
	end
end)
