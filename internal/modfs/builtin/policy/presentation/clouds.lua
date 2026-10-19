local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local colors = require("policy.presentation.colors")

local clouds = {}

-- Cloud glyphs are projected from registered cloud definitions for the terminal view.
-- Example: clouds.get(cloud_ids.CLOUD_FIRE) returns a color and glyph pair.
-- The catalog check prevents a mod's unknown color from silently rendering.
function clouds.get(kind_id)
    local definition = catalog.get(categories.CLOUDS, kind_id)
    local color_id = definition.console_color or definition.color
    local color = colors.source[color_id]

    if not color then
        error("cloud " .. kind_id .. " has unknown console color " ..
            tostring(color_id))
    end

    return {
        name = definition.name,
        color = color,
        glyph = "#",
    }
end

return clouds
