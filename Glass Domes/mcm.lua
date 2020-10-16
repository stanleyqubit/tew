local configPath = "Glass Domes"
local config = require("tew.Glass Domes.config")
mwse.loadConfig("Glass Domes")
local version = "1.0.0"

local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name="Glass Domes",
    headerImagePath="\\Textures\\tew\\Glass Domes\\Moonrain_logo.tga"}

    local page = template:createPage{label="Main Page", noScroll=true}
    page:createCategory{
        label = "Glass Domes of Vivec, Moonrain Edition "..version.." by Sade1212, qwertyquit, Leyawynn, RandomPal and tewlwolow.\n\nThis is a lua script to control dome weather."
    }

    page:createYesNoButton{
        label = "Enable debug mode?",
        variable = registerVariable("debugLogOn"),
        restartRequired=true
    }

    page:createYesNoButton{
        label = "Use green sun tint for dome interiors? Requires MGE XE.\nDefault: No.",
        variable = registerVariable("greenTint")}

    page:createDropdown{
        label = "Choose tint strength. Reload or re-enter cell after changing this setting. Default: Moderate.",
        options = {
            {label = "Weak", value = "Weak"},
            {label = "Moderate", value = "Moderate"},
            {label = "Strong", value = "Strong"},
            },
            variable=registerVariable("tintStrength")}


template:saveOnClose(configPath, config)
mwse.mcm.register(template)