local I = require("openmw.interfaces")
local util = require("openmw.util")
local storage = require("openmw.storage")



I.Settings.registerPage{
  key = "advWMap_gridmap:Settings",
  l10n = "advanced_world_map_gridmap",
  name = "ModName",
  description = "ModDescription",
}

---@class settings.boolSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default boolean|nil
---@field trueLabel string|nil
---@field falseLabel string|nil
---@field disabled boolean|nil

---@class settings.numberSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default number|nil
---@field min number|nil
---@field max number|nil
---@field integer boolean|nil
---@field disabled boolean|nil

---@class settings.selectSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default string
---@field items string[]
---@field disabled boolean|nil


---@param args settings.boolSetting
local function boolSetting(args)
    return {
        key = args.key,
        renderer = "checkbox",
        name = args.name,
        description = args.description,
        default = args.default or false,
        argument = {
            trueLabel = args.trueLabel,
            falseLabel = args.falseLabel,
            disabled = args.disabled,
        }
    }
end

---@param args settings.numberSetting
local function numberSetting(args)
    local data = {
        key = args.key,
        renderer = "number",
        name = args.name,
        description = args.description,
        default = args.default or 0,
        argument = {
            min = args.min,
            max = args.max,
            integer = args.integer,
            disabled = args.disabled,
        }
    }
    return data
end

local function color(args)
    local data = {
        renderer = "color",
        key = args.key,
        name = args.name,
        description = args.description,
        default = args.default,
        argument = {
            disabled = args.disabled,
        }
    }
    return data
end


local settingsStorage = storage.playerSection("Settings:advWMap_gridmap")
if not settingsStorage:get("version") then
    settingsStorage:set("worldDefaultColor", util.color.rgb(0, 0, 0))
    settingsStorage:set("worldDefaultDarkColor", util.color.rgb(0.15, 0.15, 0))
    settingsStorage:set("version", 1)
end


I.Settings.registerGroup{
    key = "Settings:advWMap_gridmap",
    page = "advWMap_gridmap:Settings",
    l10n = "advanced_world_map_gridmap",
    name = "MainSettings",
    description = "MainSettingsDescription",
    permanentStorage = true,
    order = 0,
    settings = {
        color{key = "worldDefaultColor", name = "WorldDefaultColor", default = util.color.rgb(0, 0, 0)},
        color{key = "worldDefaultDarkColor", name = "WorldDefaultDarkColor", default = util.color.rgb(0.15, 0.15, 0)},
        color{key = "worldDefaultLightColor", name = "WorldDefaultLightColor", default = util.color.rgb(1, 1, 1)},
        color{key = "waterColor", name = "WaterColor", default = util.color.rgb(0.521569, 0.643137, 0.701961)},
        boolSetting{key = "worldMarkerShadow", name = "WorldMarkerShadowEnabled", default = true},
        color{key = "worldMarkerShadowColor", name = "WorldMarkerShadowColor", default = util.color.rgb(0, 0, 0)},
        color{key = "worldMarkerShadowLightColor", name = "WorldMarkerShadowLightColor", default = util.color.rgb(0.760784, 0.631372, 0.494117)},
        color{key = "markerBackgroundColor", name = "MarkerBackgroundColor", default = util.color.rgb(0.55, 0.55, 0.55)},
        numberSetting{key = "alpha.city", name = "LegendAlphaCity", default = 90, min = 0, max = 100},
        numberSetting{key = "alpha.region", name = "LegendAlphaRegion", default = 7, min = 0, max = 100},
        numberSetting{key = "alpha.background", name = "LegendAlphaMarkerBackground", default = 80, min = 0, max = 100},
        boolSetting{key = "enableOldMapOverlay", name = "EnableOldMapOverlay", description = "EnableOldMapOverlayDescription", default = true},
        numberSetting{key = "oldMapOverlayAlpha", name = "OldMapOverlayAlpha", default = 10, min = 0, max = 100},
    },
}