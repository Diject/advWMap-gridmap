
local I = require("openmw.interfaces")
local util = require("openmw.util")
local async = require("openmw.async")
local markup = require("openmw.markup")
local ui = require("openmw.ui")
local vfs = require("openmw.vfs")
local core = require("openmw.core")
local storage = require("openmw.storage")


local l10n = core.l10n("advanced_world_map_gridmap")
local settingStorage = storage.playerSection("Settings:advWMap_gridmap")



local totspEsm = "solstheim tomb of the snow prince.esm"

local baseDir = "textures/advanced_world_map/gridmap/base/"
local totspDir = "textures/advanced_world_map/gridmap/totsp/"
local defaultTRMapDir = "textures/advanced_world_map/default/TRmap/"
local defaultBaseMapDir = "textures/advanced_world_map/default/basemap/"

local protectedConfigs = {
    ["data.altExMapPath"] = true,
    ["data.altExMapInfo"] = true,
    ["data.altExMapAlpha"] = true,

    ["ui.worldDefaultColor"] = true,
    ["ui.worldDefaultDarkColor"] = true,
    ["ui.worldDefaultLightColor"] = true,
    ["ui.worldMarkerShadowColor"] = true,
    ["ui.worldMarkerShadowLightColor"] = true,
    ["ui.markerBackgroundAltColor"] = true,
    ["legend.alpha.backgroundAlt"] = true,
    ["legend.worldMarkerShadow"] = true,
    ["legend.alpha.city"] = true,
    ["legend.alpha.region"] = true,
}

local oldMapInfo
local oldDirPath
local isOldTextureDefault


local function restoreConfig(data)
    data.ui.worldDefaultColor = settingStorage:get("worldDefaultColor") or util.color.rgb(0, 0, 0)
    data.ui.worldDefaultDarkColor = settingStorage:get("worldDefaultDarkColor") or util.color.rgb(0.15, 0.15, 0)
    data.ui.worldDefaultLightColor = settingStorage:get("worldDefaultLightColor") or util.color.rgb(1, 1, 1)
    data.ui.worldMarkerShadowColor = settingStorage:get("worldMarkerShadowColor") or util.color.rgb(0, 0, 0)
    data.ui.worldMarkerShadowLightColor = settingStorage:get("worldMarkerShadowLightColor") or util.color.rgb(0.760784, 0.631372, 0.494117)
    data.ui.markerBackgroundAltColor = settingStorage:get("markerBackgroundColor") or util.color.rgb(0.55, 0.55, 0.55)
    data.legend.alpha.backgroundAlt = settingStorage:get("alpha.background") or 80

    local shadow = settingStorage:get("worldMarkerShadow")
    data.legend.worldMarkerShadow = (shadow == nil or shadow == true) and true or false
    data.legend.alpha.city = settingStorage:get("alpha.city") or 90
    data.legend.alpha.region = settingStorage:get("alpha.region") or 7

    if settingStorage:get("enableOldMapOverlay") and oldMapInfo and oldDirPath then
        data.data.altExMapAlpha = settingStorage:get("oldMapOverlayAlpha") or 10
        data.data.altExMapInfo = oldMapInfo
        data.data.altExMapPath = oldDirPath
    else
        data.data.altExMapAlpha = nil
        data.data.altExMapInfo = nil
        data.data.altExMapPath = nil
    end
end

settingStorage:subscribe(async:callback(function(s, key)
    if key and I.AdvancedWorldMap then
        restoreConfig(I.AdvancedWorldMap.getConfig())
        if I.AdvancedWorldMap.version >= 19 then
            I.AdvancedWorldMap._clearCache()
        end
    end
end))


local function init()
    ---@type AdvancedWorldMap.Interface
    local interface = I.AdvancedWorldMap

    if not interface or interface.version < 16 then return end

    local dir = baseDir
    local mapInfo = markup.loadYaml(dir .. "mapInfo.yaml")
    if not mapInfo then return end

    local wColor = settingStorage:get("waterColor") or util.color.rgb(0.521569, 0.643137, 0.701961)
    mapInfo.bColor = {wColor.r, wColor.g, wColor.b}

    interface.events.registerHandler(interface.events.EVENT.onWorldMapTextureInit, function (e)
        if not e.internal then return end

        if e.mapInfo and e.mapInfo.waterWithAlpha and e.dirPath ~= baseDir and e.dirPath ~= totspDir then
            oldMapInfo = e.mapInfo
            oldDirPath = e.dirPath
            isOldTextureDefault = oldDirPath and (oldDirPath:find(defaultTRMapDir, nil, true) or
                oldDirPath:find(defaultBaseMapDir, nil, true)) and true or false

            restoreConfig(interface.getConfig())
        end

        e.dirPath = dir
        e.mapInfo = mapInfo
        e.imagePath = nil
    end, -123)

    local oMapInfo, oDirPath = interface.getWorldMapInfo()
    if oMapInfo and oDirPath and oMapInfo.waterWithAlpha and oDirPath ~= baseDir and oDirPath ~= totspDir then
        oldMapInfo = oMapInfo
        oldDirPath = oDirPath
        isOldTextureDefault = oldDirPath and (oldDirPath:find(defaultTRMapDir, nil, true) or
            oldDirPath:find(defaultBaseMapDir, nil, true)) and true or false
    end

    if not interface.setWorldMapInfo(mapInfo, dir) then return end

    local config = interface.getConfig()

    if core.contentFiles.has(totspEsm) then
        local availableTextures = {}
        local mapInfoPath = totspDir.."mapInfo.yaml"
        if vfs.fileExists(mapInfoPath) then
            availableTextures = markup.loadYaml(mapInfoPath).textures or {}
        end

        interface.events.registerHandler(interface.events.EVENT.onWorldMapTextureGet, function (e)
            if not e.mapInfo then return end

            local id = string.format("(%d,%d).png", e.x, e.y)

            if not availableTextures[id] then return end

            local path = totspDir..id
            if vfs.fileExists(path) then
                e.path = path
            end
        end, -123)

        interface.events.registerHandler(interface.events.EVENT.onWorldMapOverlayTextureGet, function (e)
            if not isOldTextureDefault or e.mapInfo ~= oldMapInfo then return end
            local id = string.format("(%d,%d).png", e.x, e.y)
            local tilemapDir = config.data.useTilemap and "tilemap/" or ""
            local path = "textures/advanced_world_map/default/TotSP/"..tilemapDir..id

            if vfs.fileExists(path) then
                e.path = path
            end
        end, 1050)
    end



    interface.events.registerHandler(interface.events.EVENT.onConfigChanged, function (e)
        if not protectedConfigs[e.key] then return end
        ui.showMessage(l10n("ConfigChangeWarning", {id = e.key}))
        restoreConfig(interface.getConfig())
    end, -123)

    restoreConfig(interface.getConfig())

    interface.events.registerHandler(interface.events.EVENT.onLegendWidgetCreate, function (e)
        if not oldMapInfo or not oldDirPath then return end

        local flexContent = ui.content{}
        local cfg = interface.getConfig()

        local size = e.size

        local function addVPadding(elem, padding)
            return {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(
                        size.x,
                        (elem.props.textSize or elem.props.size and elem.props.size.y or cfg.ui.fontSize) * (padding or 1.5)
                    ),
                },
                content = ui.content{
                    elem
                }
            }
        end

        local label = {
            type = ui.TYPE.Text,
            props = {
                text = l10n("Gridmap"),
                textSize = cfg.ui.fontSize,
                textColor = cfg.ui.defaultColor,
                autoSize = true,
                anchor = util.vector2(0, 0.5),
                position = util.vector2(4, cfg.ui.fontSize * 0.75),
            },
        }

        local overlayCB = interface.uiElements.checkbox{
            updateFunc = e.menu.update,
            text = l10n("MapOverlay"),
            textSize = cfg.ui.fontSize,
            anchor = util.vector2(0, 0.5),
            position = util.vector2(cfg.ui.fontSize, cfg.ui.fontSize * 0.75),
            checked = settingStorage:get("enableOldMapOverlay"),
            getScrollBoxMeta = function ()
                return e.scrollBox
            end,
            event = function (checked, layout)
                settingStorage:set("enableOldMapOverlay", checked)
                if not e.menu.mapWidget.cellId then
                    e.menu.mapWidget:updateMarkers(true)
                end
            end
        }

        flexContent:add(
            addVPadding(label)
        )
        flexContent:add(
            addVPadding(overlayCB)
        )

        e.content:add{
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
            },
            content = flexContent,
        }
    end, 1050)
end


async:newUnsavableSimulationTimer(0.01, init)


return {}