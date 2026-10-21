-- Theory of operation: Swamp's ruined homes and battle sites place old
-- remains at authored glyphs. The map keeps those glyphs; these handlers
-- attach typed decay intent before source substitutions erase them.
-- Population can materialize the historical corpse and extra gear from
-- these saved records without a second copy of the source map.
local effects = require("constants.vault_effects")

local handler = {}

-- Keep the source alternative list and optional equipment on one record.
local function schedule(api, glyph, alternatives, extra_items)
    api:record(effects.DELAYED_DECAY, {
        glyph = glyph,
        alternatives = alternatives,
        extra_items = extra_items,
    })
end

-- Orc loggers leave corpses and working gear at two separate glyphs.
local function orc_logging(api)
    schedule(api, "o", "orc corpse",
        "hand axe / broad axe, leather armour / pair of gloves, " ..
        "mundane quarterstaff")
    schedule(api, "p", "orc corpse",
        "hand axe / broad axe, leather armour / pair of gloves")
end

-- Three source houses may place a human skeleton on their d cell.
local function human_skeleton_d(api)
    schedule(api, "d", "human skeleton")
end

-- The ravenous encounter leaves a randomly chosen corpse on %.
local function any_corpse_percent(api)
    schedule(api, "%", "any corpse")
end

-- The witch cave has a mixed human, elf, dwarf, and orc skeleton history.
local function witch_cave(api)
    schedule(api, "d", "human skeleton / elf skeleton / " ..
        "dwarf skeleton / orc skeleton")
end

-- The hydra den's c cell marks a human corpse in the fight site.
local function human_corpse_c(api)
    schedule(api, "c", "human corpse")
end

-- The leech pen's e cell marks another human corpse.
local function human_corpse_e(api)
    schedule(api, "e", "human corpse")
end

-- Kiku's chapel can reveal giant or dragon remains on the K cell.
local function kiku_corpse_k(api)
    schedule(api, "K", "frost giant corpse / frost giant skeleton / " ..
        "shadow dragon corpse / shadow dragon skeleton")
end

-- The wayward sisters' d cell marks their human victim.
local function human_corpse_d(api)
    schedule(api, "d", "human corpse")
end

-- The adjacent e cell retains a human skeleton separately from the corpse.
local function human_skeleton_e(api)
    schedule(api, "e", "human skeleton")
end

-- The necromancy hut's uppercase K cell is the visible human remains.
local function human_corpse_k(api)
    schedule(api, "K", "human corpse")
end

handler.orc_logging = orc_logging
handler.human_skeleton_d = human_skeleton_d
handler.any_corpse_percent = any_corpse_percent
handler.witch_cave = witch_cave
handler.human_corpse_c = human_corpse_c
handler.human_corpse_e = human_corpse_e
handler.kiku_corpse_k = kiku_corpse_k
handler.human_corpse_d = human_corpse_d
handler.human_skeleton_e = human_skeleton_e
handler.human_corpse_k = human_corpse_k

return handler
