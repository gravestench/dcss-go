-- Theory of operation: a rune island can be requested through either its
-- real-rune tag or its false-rune tag. The same DES geometry serves both;
-- this hook supplies the appropriate KITEM at the original script site.
-- Ice helpers also share the source substitutions and cosmetic tile rules.
local directives = require("constants.vault_directives")
local tags = require("constants.vault_tags")

local handler = {}

local mimic_tags = {
    [tags.SHOAL_MIMIC_SIMPLE] = true,
    [tags.SHOAL_MIMIC_HANGEDMAN] = true,
    [tags.SHOAL_MIMIC_GRUNT_ICE] = true,
    [tags.SHOAL_MIMIC_GRUNT_GARDEN] = true,
}

-- The controller sets map_tag on each child request. Only a mimic request
-- emits the source item modifier; a real-rune child remains collectible.
local function rune_at(api, glyph)
    local item = "barnacled rune of Zot"

    if mimic_tags[api:map_tag()] then
        item = item .. " mimic"
    end

    api:emit(directives.KITEM, glyph .. " = " .. item)
end

-- Three source rune huts mark their prize with O.
function handler.rune_o(api)
    rune_at(api, "O")
end

-- Hangedman's alternate island marks its prize with d.
function handler.rune_d(api)
    rune_at(api, "d")
end

-- Retain source ice carving and visual rules on every iceberg helper.
-- Visual directives survive as typed records for future tile clients.
function handler.ice(api)
    api:emit(directives.SUBST, "- = xxxW.")
    api:emit(directives.RTILE, "x = wall_zot_cyan")
    api:emit(directives.COLOUR, ".x@01eO| = white")
    api:emit(directives.FTILE, ".x@+01eO| = floor_ice")
end

return handler
