local weathers=require("tew\\Watch the Skies\\weathers")
local config=require("tew\\Watch the Skies\\config")
local debugLogOn=config.debugLogOn
local WtSdir="Data Files\\Textures\\tew\\Watch the Skies\\"
local vanChance=config.vanChance/100
local alterChanges=config.alterChanges
local interiorTransitions=config.interiorTransitions
local randomiseParticles=config.randomiseParticles
local version = "1.0.2"
local WtC, intWeatherTimer


local interiorWeathers={0,1,2,3}

local function debugLog(string)
    if debugLogOn then
       mwse.log("[Watch the Skies "..version.."] "..string)
    end
end

local function skyChoiceInterior()
    debugLog("Starting interior cloud texture randomisation.")
    if vanChance<math.random() then
        local sArray=weathers[WtC.currentWeather.index]
        local texPath
        for weather, index in pairs(tes3.weather) do
            if WtC.currentWeather.index==index then
                texPath=weather
            end
        end
        if texPath~=nil and sArray[1]~=nil then
            WtC.currentWeather.cloudTexture=WtSdir..texPath.."\\"..sArray[math.random(1, #sArray)]
            debugLog("Cloud texture path set to: "..WtC.currentWeather.cloudTexture)
        end
    else
        debugLog("Using vanilla texture.")
    end

    if alterChanges then
        WtC.hoursBetweenWeatherChanges=math.random(3,12)
        debugLog("Current time between weather changes: "..WtC.hoursBetweenWeatherChanges)
    end

    if randomiseParticles then
        WtC.weathers[5].maxParticles=math.random(200,1200)
        WtC.weathers[6].maxParticles=math.random(600,1500)
        WtC.weathers[9].maxParticles=math.random(150,1200)
    end
end

local function skyChoice(e)
    debugLog("Starting cloud texture randomisation.")
    if vanChance<math.random() then
        local sArray=weathers[e.to.index]
        local texPath
        for weather, index in pairs(tes3.weather) do
            if e.to.index==index then
                texPath=weather
            end
        end
        if texPath~=nil and sArray[1]~=nil then
            e.to.cloudTexture=WtSdir..texPath.."\\"..sArray[math.random(1, #sArray)]
            debugLog("Cloud texture path set to: "..e.to.cloudTexture)
        end
    else
        debugLog("Using vanilla texture.")
    end

    if alterChanges then
        WtC.hoursBetweenWeatherChanges=math.random(3,12)
        debugLog("Current time between weather changes: "..WtC.hoursBetweenWeatherChanges)
    end

    if randomiseParticles then
        WtC.weathers[5].maxParticles=math.random(200,1200)
        WtC.weathers[6].maxParticles=math.random(600,1500)
        WtC.weathers[9].maxParticles=math.random(150,1200)
    end

    WtC:updateVisuals()
end

local function changeInteriorWeather()
    debugLog("Weather before randomisation: "..WtC.currentWeather.index)
    WtC:switchTransition(interiorWeathers[math.random(1, #interiorWeathers)])
    debugLog("Weather randomised. New weather: "..WtC.currentWeather.index)
    skyChoiceInterior()
end

local function onCellChanged(e)
    local cell=e.cell
    debugLog("Current cell: "..cell.name)

    if not (cell.isInterior) or (cell.isInterior and cell.behavesAsExterior) then
        intWeatherTimer:pause()
        debugLog("Player in exterior. Pausing interior timer.")
    elseif (cell.isInterior) and not (cell.behavesAsExterior) then
        intWeatherTimer:resume()
        debugLog("Player in interior. Resuming interior timer. Time to weather change: "..WtC.hoursBetweenWeatherChanges)
    end
end

local function initTimer()
    intWeatherTimer=timer.start{duration=WtC.hoursBetweenWeatherChanges, callback=changeInteriorWeather, iterations=-1}
    intWeatherTimer:pause()
end

local function init()
    WtC=tes3.getWorldController().weatherController
    print("Watch the Skies version "..version.." initialised.")
    for weather, index in pairs(tes3.weather) do
        debugLog("Weather: "..weather)
        for sky in lfs.dir(WtSdir..weather) do
            debugLog("Found file: "..sky)
            if string.endswith(sky, ".dds") or string.endswith(sky, ".tga") then
                table.insert(weathers[index], sky)
                debugLog("Adding file: "..sky)
            end
        end
    end
    for _, weather in pairs(WtC.weathers) do
        for index, _ in pairs(weathers) do
            if weather.index==index then
                local texPath
                for w, i in pairs(tes3.weather) do
                    if index==i then
                        texPath=w
                        break
                    end
                end
                if texPath~=nil and weathers[index][1]~=nil then
                    weather.cloudTexture=WtSdir..texPath.."\\"..weathers[index][math.random(1, #weathers[index])]
                end
            end
        end
    end

    if alterChanges then
        WtC.hoursBetweenWeatherChanges=math.random(3,12)
    end

    event.register("weatherChangedImmediate", skyChoice, {priority=-165})
    event.register("weatherTransitionFinished", skyChoice, {priority=-165})

    if interiorTransitions then
        event.register("loaded", initTimer, {priority=-165})
        event.register("cellChanged", onCellChanged, {priority=-165})
    end


    if randomiseParticles then
        WtC.weathers[5].maxParticles=math.random(200,1200)
        WtC.weathers[6].maxParticles=math.random(600,1500)
        WtC.weathers[9].maxParticles=math.random(150,1200)
    end
end

event.register("initialized", init)

-- Registers MCM menu --
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\tew\\Watch the Skies\\mcm.lua")
end)