-- Theory of operation: six Shoals maps seed old remains at authored glyphs.
-- Keep their geometry in DES and attach typed delayed-decay records here;
-- population turns each record into the appropriate corpse or skeleton.
local effects = require("constants.vault_effects")

local handler = {}

-- A human skeleton marks the close island's c cell.
local function human_skeleton_c(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "c",
        alternatives = "human skeleton",
    })
end

-- The hunting party leaves a snapping turtle corpse at its h cell.
local function turtle_corpse_h(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "h",
        alternatives = "snapping turtle corpse",
    })
end

-- Crete preserves two different animal remains in one map.
local function crete_remains(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "g",
        alternatives = "snapping turtle corpse",
    })
    api:record(effects.DELAYED_DECAY, {
        glyph = "h",
        alternatives = "elephant corpse",
    })
end

-- Prometheus' bound island gives the d glyph its demigod corpse.
local function demigod_corpse_d(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "d",
        alternatives = "demigod corpse",
    })
end

-- The pirate stash hides a human skeleton in the z cell.
local function human_skeleton_z(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "z",
        alternatives = "human skeleton",
    })
end

-- The lighthouse's Q cell represents a human skeleton.
local function human_skeleton_q(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "Q",
        alternatives = "human skeleton",
    })
end

handler.human_skeleton_c = human_skeleton_c
handler.turtle_corpse_h = turtle_corpse_h
handler.crete_remains = crete_remains
handler.demigod_corpse_d = demigod_corpse_d
handler.human_skeleton_z = human_skeleton_z
handler.human_skeleton_q = human_skeleton_q

return handler
