--[[
	PCPartsData (ModuleScript)
	PLACE THIS IN: ReplicatedStorage
	RENAME TO: PCPartsData

	Defines every purchasable part. Both server and client read this same table,
	so prices/stats never get out of sync.

	power  = how "strong" the PC is (used for high-end client requests)
	style  = how "flashy/cool" the part looks (used for aesthetic-focused requests)

	Add new parts later just by adding rows here -- nothing else needs to change.
]]

local PCPartsData = {}

PCPartsData.Categories = { "CPU", "GPU", "RAM", "Case", "RGB" }

PCPartsData.Parts = {

	CPU = {
		{ id = "cpu_budget",   name = "Dual-Core Basic",     price = 0,    power = 5,  style = 0 }, -- starter, free
		{ id = "cpu_mid",      name = "Hex-Core Runner",      price = 150,  power = 20, style = 2 },
		{ id = "cpu_high",     name = "Octa-Core Blaze",      price = 450,  power = 45, style = 4 },
		{ id = "cpu_flagship", name = "Titan X9 Processor",   price = 1200, power = 90, style = 7 },
	},

	GPU = {
		{ id = "gpu_budget",   name = "Integrated Graphics",  price = 0,    power = 5,  style = 0 },
		{ id = "gpu_mid",      name = "RTX Rookie 3060",      price = 300,  power = 30, style = 5 },
		{ id = "gpu_high",     name = "RTX Beast 4080",       price = 800,  power = 65, style = 8 },
		{ id = "gpu_flagship", name = "RTX Overkill 5090 Ti", price = 2000, power = 120,style = 12},
	},

	RAM = {
		{ id = "ram_budget",   name = "8GB Single Stick",     price = 0,    power = 3,  style = 0 },
		{ id = "ram_mid",      name = "16GB Dual Channel",    price = 100,  power = 10, style = 1 },
		{ id = "ram_high",     name = "32GB RGB Kit",         price = 250,  power = 18, style = 4 },
		{ id = "ram_flagship", name = "64GB Chromatic Elite", price = 600,  power = 30, style = 6 },
	},

	Case = {
		{ id = "case_budget",   name = "Plain Steel Box",     price = 0,    power = 0,  style = 0 },
		{ id = "case_mid",      name = "Tempered Glass Mid",  price = 120,  power = 0,  style = 5 },
		{ id = "case_high",     name = "Full Tower Showcase", price = 350,  power = 0,  style = 10},
		{ id = "case_flagship", name = "Mirror-Panel Vault",  price = 900,  power = 0,  style = 18},
	},

	RGB = {
		{ id = "rgb_none",     name = "No Lighting",          price = 0,    power = 0,  style = 0 },
		{ id = "rgb_basic",    name = "Single-Strip Glow",    price = 80,   power = 0,  style = 4 },
		{ id = "rgb_sync",     name = "Synced Fan Loop",      price = 220,  power = 0,  style = 9 },
		{ id = "rgb_pro",      name = "Full Spectrum Aura",   price = 500,  power = 0,  style = 16},
	},
}

-- Helper: look up a part definition by category + id
function PCPartsData.GetPart(category, partId)
	local list = PCPartsData.Parts[category]
	if not list then return nil end
	for _, part in ipairs(list) do
		if part.id == partId then
			return part
		end
	end
	return nil
end

-- Helper: every player starts owning the free ("budget") part in each category
function PCPartsData.GetDefaultLoadout()
	local loadout = {}
	for _, category in ipairs(PCPartsData.Categories) do
		loadout[category] = PCPartsData.Parts[category][1].id
	end
	return loadout
end

return PCPartsData
