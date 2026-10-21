-- Theory of operation: source Lair endings schedule old skeletons at fixed
-- map glyphs. Typed decay records survive generation and save; the live
-- population owner can materialize their remains later.
local effects = require("constants.vault_effects")

local handler = {}

-- Keep an authored decay site and its alternative species in one record.
local function schedule(api, glyph, alternatives)
    api:record(effects.DELAYED_DECAY, {
        glyph = glyph,
        alternatives = alternatives,
    })
end

-- The beastmaster's den contains skeletons from many humanoid visitors.
local function grunt_lair_end_beastmaster(api)
    schedule(api, "d", "human skeleton / orc skeleton / elf skeleton / " ..
        "dwarf skeleton / ogre skeleton w:1 / naga skeleton w:1 / " ..
        "minotaur skeleton w:1 / merfolk skeleton w:1")
end

-- The abyssal woods preserves both spriggan and beast remains at O.
local function hellmonk_lair_end_abyssal_woods(api)
    schedule(api, "O", "spriggan skeleton / wolf skeleton w:3 / " ..
        "polar bear skeleton w:2 / black bear skeleton w:2")
end

handler.grunt_lair_end_beastmaster = grunt_lair_end_beastmaster
handler.hellmonk_lair_end_abyssal_woods =
    hellmonk_lair_end_abyssal_woods

return handler
