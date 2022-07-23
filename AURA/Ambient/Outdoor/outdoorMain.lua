-- TODO: WIND MODULE PER CLOUD/WIND SPEED FROM WTS?

local climates = require("tew.AURA.Ambient.Outdoor.outdoorClimates")
local config = require("tew.AURA.config")
local common=require("tew.AURA.common")
local tewLib = require("tew.tewLib.tewLib")
local sounds = require("tew.AURA.sounds")

local isOpenPlaza=tewLib.isOpenPlaza

local moduleAmbientOutdoor=config.moduleAmbientOutdoor
local moduleInteriorWeather=config.moduleInteriorWeather
local playSplash=config.playSplash
local quietChance=config.quietChance/100
local OAvol = config.OAvol/200
local splashVol = config.splashVol/200
local playInteriorAmbient=config.playInteriorAmbient

local moduleName = "outdoor"

local climateLast, weatherLast, timeLast, cellLast
local climateNow, weatherNow, timeNow
local WtC
local windoors, interiorTimer

local debugLog = common.debugLog

local function weatherParser(options)

	local volume, pitch, ref, immediate

	if not options then
		volume = OAvol
		pitch = 1
		immediate = false
		ref = tes3.mobilePlayer.reference
	else
		volume = options.volume or OAvol
		pitch = options.pitch or 1
		immediate = options.immediate or false
		ref = options.reference or tes3.mobilePlayer.reference
	end

	if weatherNow >= 0 and weatherNow <4 then
		if quietChance<math.random() then
			debugLog("Playing regular weather track.")
			if immediate then
				sounds.playImmediate{module = moduleName, climate = climateNow, time = timeNow, volume = volume, pitch = pitch, reference = ref}
			else
				sounds.play{module = moduleName, climate = climateNow, time = timeNow, volume = volume, pitch = pitch, reference = ref}
			end
		else
			debugLog("Playing quiet weather track.")
			if immediate then
				sounds.playImmediate{module = moduleName, volume = volume, type = "quiet", pitch = pitch, reference = ref}
			else
				sounds.play{module = moduleName, volume = volume, type = "quiet", pitch = pitch, reference = ref}
			end
		end
	elseif weatherNow == 6 or weatherNow == 7 or weatherNow == 9 then
		debugLog("Extreme weather detected.")
		sounds.remove{module = moduleName, reference = ref, volume = OAvol}
		return
	end
end

local function playInteriorBig(windoor, playOld)
	if windoor==nil then debugLog("Dodging an empty ref.") return end
	if playOld then
		debugLog("Playing interior ambient sounds for big interiors using old track.")
		sounds.playImmediate{module = moduleName, last = true, reference = windoor, volume = (0.55*OAvol)-(0.005 * #windoors), pitch=0.8}
	else
		debugLog("Playing interior ambient sounds for big interiors using new track.")
		weatherParser{reference = windoor, volume = (0.55*OAvol)-(0.005 * #windoors), pitch = 0.8, immediate = true}
	end
end

local function updateInteriorBig()
	debugLog("Updating interior doors and windows.")
	local playerPos=tes3.player.position
	for _, windoor in ipairs(windoors) do
		if common.getDistance(playerPos, windoor.position) > 1800
		and windoor~=nil then
			playInteriorBig(windoor, true)
		end
	end
end

local function playInteriorSmall()
	if cellLast and not cellLast.isInterior then
		debugLog("Playing interior ambient sounds for small interiors using old track.")
		sounds.playImmediate{module = moduleName, last = true, volume = 0.3*OAvol, pitch=0.9}
	else
		debugLog("Playing interior ambient sounds for small interiors using new track.")
		weatherParser{volume = 0.3*OAvol, pitch = 0.9, immediate = true}
	end
end

local function cellCheck()

	-- Gets messy otherwise
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		return
	end

	local region

	OAvol = config.OAvol/200

	debugLog("Cell changed or time check triggered. Running cell check.")

	-- Getting rid of timers on cell check --
	if not interiorTimer then
		interiorTimer = timer.start({duration=1, iterations=-1, callback=updateInteriorBig, type=timer.real})
		interiorTimer:pause()
	else
		interiorTimer:pause()
	end

	local cell = tes3.getPlayerCell()
	if (not cell) then debugLog("No cell detected. Returning.") return end
	debugLog("Cell: "..cell.editorName)

	if cell.isInterior then
		local regionObject = tes3.getRegion({useDoors=true})
		region = regionObject.name
		weatherNow = regionObject.weather.index
	else
		region = tes3.getRegion().name
		if WtC.nextWeather then
			weatherNow = WtC.nextWeather.index
		else
			weatherNow = WtC.currentWeather.index
		end
	end

	debugLog("Weather: "..weatherNow)

	if region == nil then debugLog("No region detected. Returning.") return end

	-- Checking climate --
	for kRegion, vClimate in pairs(climates.regions) do
		if kRegion==region then
			climateNow=vClimate
		end
	end

	if not climateNow then debugLog ("Blacklisted region - no climate detected. Returning.") return end
	debugLog("Climate: "..climateNow)

	-- Checking time --
	local gameHour=tes3.worldController.hour.value
	if (gameHour >= WtC.sunriseHour - 1.5) and (gameHour < WtC.sunriseHour + 1.5) then
		timeNow = "sr"
	elseif (gameHour >= WtC.sunriseHour + 1.5) and (gameHour < WtC.sunsetHour - 1.5) then
		timeNow = "d"
	elseif (gameHour >= WtC.sunsetHour - 1.5) and (gameHour < WtC.sunsetHour + 1.5) then
		timeNow = "ss"
	elseif (gameHour >= WtC.sunsetHour + 1.5) or (gameHour < WtC.sunriseHour - 1.5) then
		timeNow = "n"
	end
	debugLog("Time: "..timeNow)


	-- Transition filter chunk --
	if
		timeNow==timeLast
		and climateNow==climateLast
		and weatherNow==weatherLast
		and (common.checkCellDiff(cell, cellLast) == false
			or cell == cellLast) then
		debugLog("Same conditions. Returning.")
		return
	elseif
		timeNow~=timeLast
		and weatherNow==weatherLast
		and (common.checkCellDiff(cell, cellLast) == false)
		and ((weatherNow >= 4 and weatherNow < 6) or (weatherNow == 8)) then
			debugLog("Time changed but weather didn't. Returning.")
			return
	end

	debugLog("Different conditions. Resetting sounds.")

	if moduleInteriorWeather == false and windoors[1]~=nil and weatherNow<4 or weatherNow==8 then
		for _, windoor in ipairs(windoors) do
			sounds.removeImmediate{module=moduleName, reference=windoor}
		end
		debugLog("Clearing windoors.")
	end

	local useLast = false
	if (cell.isOrBehavesAsExterior and not isOpenPlaza(cell)) then
		if cellLast and common.checkCellDiff(cell, cellLast)==true and timeNow==timeLast
		and weatherNow==weatherLast and climateNow==climateLast
		and not ((weatherNow >= 4 and weatherNow <= 6) or (weatherNow == 8)) then
		-- Using the same track when entering int/ext in same area; time/weather change will randomise it again --
			debugLog("Found same cell. Using last sound.")
			useLast = true
			sounds.removeImmediate{module = moduleName}
			sounds.playImmediate{module = moduleName, last = true, volume = OAvol}
		else
			debugLog("Found exterior cell.")
			sounds.remove{module = moduleName, volume=OAvol}
			weatherParser{volume=OAvol}
		end
	elseif cell.isInterior then
		if (not playInteriorAmbient) or (playInteriorAmbient and isOpenPlaza(cell) and weatherNow==3) then
			debugLog("Found interior cell. Removing sounds.")
			sounds.removeImmediate{module = moduleName}
			return
		end
		debugLog("Found interior cell.")
		sounds.removeImmediate{module = moduleName}
		if common.getCellType(cell, common.cellTypesSmall)==true
		or common.getCellType(cell, common.cellTypesTent)==true then
			debugLog("Found small interior cell. Playing interior loops.")
			sounds.removeImmediate{module = moduleName}
			playInteriorSmall()
		else
			debugLog("Found big interior cell. Playing interior loops.")
			windoors=nil
			windoors=common.getWindoors(cell)
			if windoors ~= nil then
				for _, windoor in ipairs(windoors) do
					tes3.removeSound{reference=windoor}
					playInteriorBig(windoor, useLast)
					useLast = true
				end
				interiorTimer:resume()
			end
		end
	end

	-- Setting last values --
	timeLast=timeNow
	climateLast=climateNow
	weatherLast=weatherNow
	cellLast=cell
	debugLog("Cell check complete.")
end

local function positionCheck(e)
	local cell=tes3.getPlayerCell()
	local element=e.element
	debugLog("Player underwater. Stopping AURA sounds.")
	if (not cell.isInterior) or (cell.behavesAsExterior) then
		sounds.removeImmediate{module = moduleName}
		sounds.playImmediate{module = moduleName, last = true, volume = 0.4*OAvol, pitch=0.5}
	end
	if playSplash and moduleAmbientOutdoor then
		tes3.playSound{sound="splash_lrg", volume=0.5*splashVol, pitch=0.6}
	end
	element:register("destroy", function()
		debugLog("Player above water level. Resetting AURA sounds.")
		if (not cell.isInterior) or (cell.behavesAsExterior) then
			sounds.removeImmediate{module = moduleName}
			sounds.playImmediate{module = moduleName, last = true, volume = OAvol}
		end
		timer.start({duration=1, callback=cellCheck, type=timer.real})
		if playSplash and moduleAmbientOutdoor then
			tes3.playSound{sound="splash_sml", volume=0.6*splashVol, pitch=0.7}
		end
	end)
end

local function waitCheck(e)
	local element=e.element
	element:register("destroy", function()
        timer.start{
            type=timer.game,
            duration = 0.02,
            callback = cellCheck
        }
    end)
end

local function runResetter()
	climateLast, weatherLast, timeLast = nil, nil, nil
	climateNow, weatherNow, timeNow = nil, nil, nil
	windoors = {}
	timer.start{
		type = timer.game,
		duration = 0.01,
		callback = cellCheck
	}
end

local function runHourTimer()
	timer.start({duration=0.5, callback=cellCheck, iterations=-1, type=timer.game})
end

-- Potential fix for sky texture pop-in - believe it or not :|
local function onWeatherTransistionStarted()
	timer.start(
		{
			duration=0.1, callback=cellCheck, iterations=1, type=timer.game
		}
	)
end

WtC = tes3.worldController.weatherController
event.register("loaded", runHourTimer, {priority=-160})
event.register("load", runResetter, {priority=-160})
event.register("cellChanged", cellCheck, {priority=-160})
event.register("weatherTransitionStarted", onWeatherTransistionStarted, {priority=-160})
event.register("weatherTransitionFinished", cellCheck, {priority=-160})
event.register("weatherTransitionImmediate", cellCheck, {priority=-160})
event.register("weatherChangedImmediate", cellCheck, {priority=-160})
event.register("uiActivated", positionCheck, {filter="MenuSwimFillBar", priority = -5})
event.register("uiActivated", waitCheck, {filter="MenuTimePass", priority = -5})
debugLog("Outdoor Ambient Sounds module initialised.")