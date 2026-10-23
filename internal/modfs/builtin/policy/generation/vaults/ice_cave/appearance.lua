-- Ice Cave's visible walls and water retain their normal grid features.
-- Map-local records give them source descriptions, while freezing-vapour
-- markers become live clouds through the existing fog-machine owner.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")

local appearance = {}

local names = {
    {
        feature = features.ROCK_WALL,
        name = "ice covered rock wall",
    },

    {
        feature = features.STONE_ARCH,
        name = "ice choked empty arch of ancient stone",
    },

    {
        feature = features.SHALLOW_WATER,
        name = "Some ice crusted shallow water",
    },

    {
        feature = features.DEEP_WATER,
        name = "Some ice crusted deep water",
    },
}

-- The authored `<` is the temporary branch exit. The visit component,
-- rather than stair depth, supplies its exact outside return coordinate.
function appearance.exit_and_names(api)
    api:emit(directives.KFEAT, "< = exit_ice_cave")

    for _, definition in ipairs(names) do
        api:record(effects.FEATURE_NAME, {
            feature = definition.feature,
            name = definition.name,
        })
    end
end

-- The source machine starts one cold cloud, then produces more on a
-- 50–250-aut interval. Its requested size changes by map but its power
-- and exclusion policy remain the same everywhere.
function appearance.freezing_machine(api, size, glyphs)
    glyphs = glyphs or "!"

    api:emit(directives.MARKER,
        glyphs .. ' = lua:fog_machine { pow_max = 20, ' ..
        'cloud_type = "freezing vapour", delay_min = 50, ' ..
        'delay_max = 250, size = ' .. size ..
        ', start_clouds = 1, excl_rad = -1 }')
end

-- Each wrapper names the source machine size at its DES call site. This
-- keeps the map's scripted choice readable without a stringly argument.
function appearance.fog_8(api)
    appearance.freezing_machine(api, 8)
end

-- Twelve cells are the source default for cavern and demon-room fog.
function appearance.fog_12(api)
    appearance.freezing_machine(api, 12)
end

-- Caverns 02 marks its narrow r shortcut with a six-cell cold machine.
function appearance.fog_r6(api)
    appearance.freezing_machine(api, 6, "r")
end

return appearance
