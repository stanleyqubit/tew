local configPath = "AURA"
local config = require("tew.AURA.config")
local defaults = require("tew.AURA.defaults")
mwse.loadConfig("AURA")
local modversion = require("tew.AURA.version")
local version = modversion.version
local soundBuilder = require("tew\\AURA\\soundBuilder")

local function registerVariable(id)
	return mwse.mcm.createTableVariable{
		id = id,
		table = config
	}
end

local template = mwse.mcm.createTemplate{
	name="AURA",
	headerImagePath="\\Textures\\tew\\AURA\\AURA_logo.tga"}

	local page = template:createPage{label="Main Settings", noScroll=true}
	page:createCategory{
		label = "AURA "..version.." by tewlwolow.\nLua-based sound overhaul.\n\nSettings:",
	}
	page:createYesNoButton{
		label = "Enable debug mode?",
		variable = registerVariable("debugLogOn"),
		restartRequired=true
	}
	page:createYesNoButton{
		label = "Enable Outdoor Ambient module?",
		variable = registerVariable("moduleAmbientOutdoor"),
		restartRequired=true
	}
	page:createYesNoButton{
		label = "Enable Interior Ambient module?",
		variable = registerVariable("moduleAmbientInterior"),
		restartRequired=true
	}
	page:createYesNoButton{
		label = "Enable Populated Ambient module?",
		variable = registerVariable("moduleAmbientPopulated"),
		restartRequired=true
	}
	page:createYesNoButton{
		label = "Enable Interior Weather module?",
		variable = registerVariable("moduleInteriorWeather"),
		restartRequired=true
	}
	page:createYesNoButton{
		label = "Enable Service Voices module?",
		variable = registerVariable("moduleServiceVoices"),
		restartRequired=true
	}
	page:createYesNoButton{
		label = "Enable UI module?",
		variable = registerVariable("moduleUI"),
		restartRequired=true
	}
	page:createYesNoButton{
		label = "Enable Containers module?",
		variable = registerVariable("moduleContainers"),
		restartRequired=true
	}
	page:createYesNoButton{
		label = "Enable PC module?",
		variable = registerVariable("modulePC"),
		restartRequired=true
	}
	page:createYesNoButton{
		label = "Enable Misc module?",
		variable = registerVariable("moduleMisc"),
		restartRequired=true
	}

	local flushButton = page:createButton{
		buttonText = "Flush manifest file",
		callback = function()
			soundBuilder.flushManifestFile()
		end,
	}

	local pageOA = template:createPage{label="Outdoor Ambient"}
	pageOA:createCategory{
		label = "Plays ambient sounds in accordance with local climate, weather, player position, and time.\n\nSettings:"
	}
	pageOA:createSlider{
		label = string.format("Changes %% volume for Outdoor Ambient module. Default = %s%%.\nRequires restart. Volume %%", defaults.OAvol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("OAvol")
	}
	pageOA:createSlider{
		label = string.format("Changes %% chance for a quiet track to play instead of the regular one. Default = %s%%.\nRequires restart. Chance %%", defaults.quietChance),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable=registerVariable("quietChance")
	}
	pageOA:createYesNoButton{
		label = "Enable exterior ambient sounds in interiors? This means the last exterior loop will play on each interior door leading to an exterior. The sound will stop if you're far enough from such door.",
		variable = registerVariable("playInteriorAmbient"),
		restartRequired=true
	}

	local pageIA = template:createPage{label="Interior Ambient"}
	pageIA:createCategory{
		label = "Plays ambient sounds in accordance with interior type. Includes taverns, guilds, shops, libraries, tombs, caves, and ruins.\n\nSettings:"
	}
	pageIA:createSlider{
		label = string.format("Changes %% volume for Interior Ambient module. Default = %s%%.\nRequires restart. Volume %%", defaults.intVol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("intVol")
	}
	pageIA:createYesNoButton{
		label = "Enable natural, native music in taverns? Note that this works best if you have empty explore/battle folders and use no music mod. Requires restart.",
		variable = registerVariable("interiorMusic"),
		restartRequired=true
	}

	template:createExclusionsPage{
		label = "Taverns Blacklist",
		description = "Select which taverns the music is disabled in.",
		toggleText = "Toggle",
		leftListLabel = "Disabled taverns",
		rightListLabel = "Enabled taverns",
		showAllBlocked = false,
		variable = mwse.mcm.createTableVariable{
			id = "disabledTaverns",
			table = config,
		},

		filters = {

			{
				label = "Enabled taverns",
				callback = (
					function()
						local enabledTaverns = {}
						for cell in tes3.iterate(tes3.dataHandler.nonDynamicData.cells) do
							if cell.isInterior then
								for npc in cell:iterateReferences(tes3.objectType.npc) do
									if (npc.object.class.id == "Publican"
									or npc.object.class.id == "T_Sky_Publican"
									or npc.object.class.id == "T_Cyr_Publican") then
										table.insert(enabledTaverns, cell.name)
									end
								end
							end
						end
						
						-- Remove duplicated tavern names
						table.sort(enabledTaverns)
						local previous
						local duplicates = {}
						for k, v in pairs(enabledTaverns) do
							if v == previous then
								table.insert(duplicates, k, v)
							end
							previous = v
						end
						for k, v in pairs(duplicates) do
							table.remove(enabledTaverns, k-1)
						end

						return enabledTaverns
					end
				)
			},

		}
	}

	local pagePA = template:createPage{label="Populated Ambient"}
	pagePA:createCategory{
		label = "Plays ambient sounds in populated areas, like towns and villages.\n\nSettings:"
	}
	pagePA:createSlider{
		label = string.format("Changes %% volume for Populated Ambient module. Default = %s%%.\nRequires restart. Volume %%", defaults.popVol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("popVol")
	}

	local pageIW = template:createPage{label="Interior Weather"}
	pageIW:createCategory{
		label = "Plays weather sounds in interiors.\n\nSettings:"
	}
	pageIW:createSlider{
		label = string.format("Changes %% volume for Interior Weather module. Default = %s%%.\nRequires restart. Volume %%", defaults.IWvol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("IWvol")
	}

	local pageSV = template:createPage{label="Service Voices"}
	pageSV:createCategory{
		label = "Plays appropriate voice comments on service usage.\n\nSettings:"
	}
	pageSV:createYesNoButton{
		label = "Enable voice comments on repair service?",
		variable = registerVariable("serviceRepair"),
	}
	pageSV:createYesNoButton{
		label = "Enable voice comments on spells vendor service?",
		variable = registerVariable("serviceSpells"),
	}
	pageSV:createYesNoButton{
		label = "Enable voice comments on training service?",
		variable = registerVariable("serviceTraining"),
	}
	pageSV:createYesNoButton{
		label = "Enable voice comments on spellmaking service?",
		variable = registerVariable("serviceSpellmaking"),
	}
	pageSV:createYesNoButton{
		label = "Enable voice comments on enchanting service?",
		variable = registerVariable("serviceEnchantment"),
	}
	pageSV:createYesNoButton{
		label = "Enable voice comments on travel service?",
		variable = registerVariable("serviceTravel"),
	}
	pageSV:createYesNoButton{
		label = "Enable voice comments on barter service?",
		variable = registerVariable("serviceBarter"),
	}
	pageSV:createSlider{
		label = string.format("Changes %% volume for Service Voices module. Default = %s%%.\nRequires restart. Volume %%", defaults.SVvol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("SVvol")
	}

	local pagePC = template:createPage{label="PC"}
	pagePC:createCategory{
		label = "Plays sounds related to the player character.\n\nSettings:"
	}
	pagePC:createYesNoButton{
		label = "Enable low health sounds?",
		variable = registerVariable("PChealth"),
	}
	pagePC:createYesNoButton{
		label = "Enable low fatigue sounds?",
		variable = registerVariable("PCfatigue"),
	}
	pagePC:createYesNoButton{
		label = "Enable low magicka sounds?",
		variable = registerVariable("PCmagicka"),
	}
	pagePC:createYesNoButton{
		label = "Enable diseased sounds?",
		variable = registerVariable("PCDisease"),
	}
	pagePC:createYesNoButton{
		label = "Enable blighted sounds?",
		variable = registerVariable("PCBlight"),
	}
	pagePC:createYesNoButton{
		label = "Enable player combat taunts?",
		variable = registerVariable("PCtaunts"),
	}
	pagePC:createSlider{
		label = string.format("Changes %% volume for for vital signs (health, fatigue, magicka, disease, blight). Default = %s%%.\nRequires restart. Volume %%", defaults.vsVol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("vsVol")
	}
	pagePC:createSlider{

		label = string.format("Changes %% chance for a battle taunt to play. Default = %s%%.\nRequires restart. Chance %%", defaults.tauntChance),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable=registerVariable("tauntChance")
	}
	pagePC:createSlider{
		label = string.format("Changes %% volume for player battle taunts. Default = %s%%.\nRequires restart. Volume %%", defaults.tVol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("tVol")
	}

	local pageC = template:createPage{label="Containers"}
	pageC:createCategory{
		label = "Plays container sound on open/close.\n\nSettings:"
	}
	pageC:createSlider{
		label = string.format("Changes %% volume for Containers module. Default = %s%%.\nRequires restart. Volume %%", defaults.Cvol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("Cvol")
	}

	local pageUI = template:createPage{label="UI"}
	pageUI:createCategory{
		label = "Additional immersive UI sounds.\n\nSettings:"
	}
	pageUI:createYesNoButton{
		label = "Enable training menu sounds?",
		variable = registerVariable("UITraining"),
	}
	pageUI:createYesNoButton{
		label = "Enable travel menu sounds?",
		variable = registerVariable("UITravel"),
	}
	pageUI:createYesNoButton{
		label = "Enable spell menu sounds?",
		variable = registerVariable("UISpells"),
	}
	pageUI:createYesNoButton{
		label = "Enable barter menu sounds?",
		variable = registerVariable("UIBarter"),
	}
	pageUI:createYesNoButton{
		label = "Enable eating sound for ingredients in inventory menu?",
		variable = registerVariable("UIEating"),
	}
	pageUI:createSlider{
		label = string.format("Changes %% volume for UI module. Default = %s%%.\nRequires restart. Volume %%", defaults.UIvol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("UIvol")
	}

	local pageMisc = template:createPage{label="Misc", noScroll=true}
	pageMisc:createCategory{
		label = "Plays various miscellaneous sounds.\n\nSettings:"
	}
	pageMisc:createYesNoButton{
		label = "Enable variable rain sounds per max particles?\nNote: requires Watch the Skies for full effect.",
		variable = registerVariable("rainSounds"),
	}
	pageMisc:createYesNoButton{
		label = "Enable variable wind sounds per clouds speed?\nNote: requires Watch the Skies for full effect.",
		variable = registerVariable("windSounds"),
	}
	pageMisc:createSlider{
		label = string.format("Changes %% volume for wind sounds. Default = %s%%.\nRequires restart. Volume %%", defaults.windVol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("windVol")
	}
	pageMisc:createYesNoButton{
		label = "Enable splash sounds when going underwater and back to surface?",
		variable = registerVariable("playSplash"),
	}
	pageMisc:createSlider{
		label = string.format("Changes %% volume for splash sounds. Default = %s%%.\nRequires restart. Volume %%", defaults.splashVol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("splashVol")
	}
	pageMisc:createYesNoButton{
		label = "Enable door sounds for yurts and pelt entrances?",
		variable = registerVariable("playYurtFlap"),
	}
	pageMisc:createSlider{
		label = string.format("Changes %% volume for yurt and bear skins flaps. Default = %s%%.\nRequires restart. Volume %%", defaults.yurtVol),
		min = 0,
		max = 200,
		step = 1,
		jump = 10,
		variable=registerVariable("yurtVol")
	}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
