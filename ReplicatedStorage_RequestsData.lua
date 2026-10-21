--[[
	RequestsData (ModuleScript)
	PLACE THIS IN: ReplicatedStorage
	RENAME TO: RequestsData

	Templates for the "client hustle" messages. RequestManager (server) picks
	one at random, scales the numbers to the player's progress, and sends it
	to that player's in-game "phone/PC" UI.

	Add more clientName/message pairs any time -- more variety keeps the loop
	from feeling repetitive.
]]

local RequestsData = {}

RequestsData.Templates = {
	{
		clientName = "xX_JayGamer_Xx",
		message = "yo I saw your setup on the discover page, my pc looks like trash rn lol. can you build me something decent? I got the cash",
		focus = "power", -- this client cares about raw power
	},
	{
		clientName = "sarah.codes",
		message = "hey!! I need a pc for streaming, doesn't need to be crazy powerful but it HAS to look good on camera. rgb is a must",
		focus = "style",
	},
	{
		clientName = "BigMoneyMike",
		message = "money is not a problem. I want the most expensive, most powerful build you can make. show me what you got",
		focus = "power",
	},
	{
		clientName = "aestheticgurl",
		message = "omg your room is so cute, can u build me a pc that matches?? has to be aesthetic pls",
		focus = "style",
	},
	{
		clientName = "NoobMaster69",
		message = "bro i keep lagging in every game can u just build me literally anything that works",
		focus = "power",
	},
	{
		clientName = "TechReviewTom",
		message = "I'm filming a build video, need something that looks INSANE on camera. budget's flexible",
		focus = "style",
	},
	{
		clientName = "quietkid_dev",
		message = "just need something reliable for coding, don't need it to be flashy, just strong",
		focus = "power",
	},
}

-- Difficulty tiers scale reward + requirements. RequestManager rolls a tier
-- based on how far along the player is (their current best power/style).
RequestsData.Tiers = {
	{ name = "Easy",   powerMult = 0.3, styleMult = 0.3, reward = 150  },
	{ name = "Medium", powerMult = 0.6, styleMult = 0.6, reward = 400  },
	{ name = "Hard",   powerMult = 0.9, styleMult = 0.9, reward = 900  },
	{ name = "Elite",  powerMult = 1.2, styleMult = 1.2, reward = 2000 },
}

return RequestsData
