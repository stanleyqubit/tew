return mwse.loadConfig(
    "Vapourmist",
    {
        debugLogOn = false,
        interiorFog = true,
        cloudyWeathers = {
            ["Cloudy"]=true,
            ["Foggy"]=true,
            ["Rain"]=true,
            ["Snow"]=true,
            ["Thunder"]=true,
        },
        mistyWeathers={
            ["Foggy"]=true,
        },
        randomCloudChance = 15,
        randomMistChance = 10
    }
)