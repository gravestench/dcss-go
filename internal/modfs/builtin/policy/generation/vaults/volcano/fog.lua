-- Theory of operation: the source maps declare fog machines on lava
-- glyphs. The marker carries immutable cloud settings; Akara owns the
-- countdown and emitted cloud entities after population.
local directives = require("constants.vault_directives")
local volcano = require("constants.volcano")

local fog = {}

-- Emit a marker with one named listener. A chain name groups every
-- occurrence of a glyph under one saved master firing clock.
local function machine(api, glyph, settings, chain)
    api:emit(directives.KFEAT, glyph .. " = l")

    if chain then
        settings = settings .. ', chain = "' .. chain .. '"'
    end

    api:emit(directives.MARKER,
        glyph .. " = lua:fog_machine { " .. settings .. " }")
end

-- One tiny crater begins at the source V and emits about forty flame
-- cells per 800-aut pulse, with an early eruption warning.
local function tiny(api)
    machine(api, "V",
        'cloud_type = "flame", walk_dist = 10, pow_max = 6, ' ..
        "delay = " .. volcano.TINY_FOG_DELAY ..
        ", size = " .. volcano.TINY_FOG_SIZE ..
        ', spread_rate = 10, excl_rad = -1, ' ..
        'listener = "volcano.large"')
end

-- The larger machine has the same 300-aut timing but covers a wide
-- region; source maps use it only where their geometry can contain it.
local function large(api)
    machine(api, "V",
        'cloud_type = "flame", walk_dist = 15, pow_max = 6, ' ..
        'delay = 300, size = 10000, spread_rate = 30, ' ..
        'excl_rad = -1, listener = "volcano.large"')
end

-- A smaller regular eruption carries the distinct near-player message.
local function small(api)
    machine(api, "V",
        'cloud_type = "flame", walk_dist = 15, pow_max = 6, ' ..
        'delay = 300, size = 800, spread_rate = 30, ' ..
        'excl_rad = -1, listener = "volcano.small"')
end

-- Repeated V glyphs share one master; each firing affects all slaves at
-- the same instant, rather than six independent random clocks.
local function chained(api)
    machine(api, "V",
        'cloud_type = "flame", walk_dist = 15, pow_max = 6, ' ..
        "delay = " .. volcano.CHAINED_FOG_DELAY ..
        ", size = " .. volcano.CHAINED_FOG_SIZE ..
        ', spread_rate = 30, excl_rad = -1, ' ..
        'listener = "volcano.large"', "V")
end

-- The lake has six separate synchronized glyph groups. Each group has
-- one source delay draw and acts at every matching authored location.
local function lake(api)
    for glyph in ("QRSTUV"):gmatch(".") do
        machine(api, glyph,
            'cloud_type = "flame", walk_dist = 0, pow_max = 6, ' ..
            'delay_min = 300, delay_max = 800, size = 125, ' ..
            'spread_rate = 5, excl_rad = -1, ' ..
            'listener = "volcano.small"', glyph)
    end
end

fog.tiny = tiny
fog.large = large
fog.small = small
fog.chained = chained
fog.lake = lake

return fog
