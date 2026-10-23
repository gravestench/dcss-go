-- Theory of operation: the saved easy/hard choice selects Ice Cave's
-- monster definitions before map placement. Keyed requests create actors
-- on authored cells; the separate random-list record serves effects such
-- as Shadow Creatures without becoming ambient floor population.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local rules = require("constants.vault_generation_rules")
local weighted = require("policy.generation.vaults.ice_cave.weighted_items")

local monsters = {}

local draconian_weapons = {
    ["broad axe"] = 1,
    ["halberd"] = 2,
    ["morningstar"] = 2,
    ["scimitar"] = 2,
}

-- Missing difficulty indicates a broken entrance-to-destination contract;
-- choosing an easy roster would silently change the source challenge.
local function hard(api)
    local value = api:setting("ice_cave_hard")

    if type(value) ~= "boolean" then
        error("Ice Cave monsters need saved easy/hard difficulty")
    end

    return value
end

-- Source dgn.random_entry_arg adds the same weight to each slash-separated
-- alternative, keeping its three simulacrum groups proportional.
function monsters.weighted_entries(entries, weight)
    return entries:gsub("/", " w:" .. weight .. " /") ..
        " w:" .. weight
end

-- Mocking resembles player species, savage is beastly, and cruel has
-- especially dangerous bodies. Maps and the random-list rule share these
-- three sets so a variant cannot drift from its source roster.
function monsters.simulacrum_sets(is_hard)
    if is_hard then
        return {
            mocking = "deep troll simulacrum / minotaur simulacrum" ..
                " / spriggan defender simulacrum",
            savage = "lindwurm simulacrum / dire elephant simulacrum" ..
                " / alligator simulacrum / harpy simulacrum" ..
                " / anaconda simulacrum",
            cruel = "ettin simulacrum / 7-headed hydra simulacrum" ..
                " / golden dragon simulacrum" ..
                " / caustic shrike simulacrum",
        }
    end

    return {
        mocking = "two-headed ogre simulacrum / troll simulacrum" ..
            " / naga simulacrum / spriggan simulacrum",
        savage = "wolf simulacrum / elephant simulacrum" ..
            " / polar bear simulacrum / cane toad simulacrum" ..
            " / death yak simulacrum",
        cruel = "dire elephant simulacrum / harpy simulacrum" ..
            " / anaconda simulacrum / 3-headed hydra simulacrum",
    }
end

-- A random-list record is saved beside the map. It does not spawn a
-- monster immediately and therefore remains independent of keyed slots.
function monsters.record_random_list(api, expression)
    api:record(effects.GENERATION_RULE, {
        rule = rules.RANDOM_MONSTER_LIST,
        expression = expression,
    })
end

-- The undead/demon caves put simulacra into the weaker keyed slots, then
-- raise statues and bosses with difficulty. Optional reaper glyphs add
-- enough cold-resistance gear for the source freezing-vapour rooms.
function monsters.undead(api, reaper_glyphs)
    local is_hard = hard(api)
    local simul = monsters.simulacrum_sets(is_hard)
    local reaper = "reaper ; halberd itemname:scythe " ..
        "tile:wpn_scythe wtile:scythe ego:freezing"

    if reaper_glyphs then
        reaper = reaper .. " . robe ego:cold_resistance" ..
            " . ring of protection from cold | ring of ice"
    end

    if is_hard then
        api:emit(directives.KMONS,
            "1 = " .. simul.mocking .. " / ice devil")
        api:emit(directives.KMONS,
            "2 = " .. simul.savage .. " / freezing wraith")
        api:emit(directives.KMONS, "3 = obsidian statue")
        api:emit(directives.KMONS, "4 = freezing wraith")
        api:emit(directives.KMONS, "5 = " .. simul.cruel)
        api:emit(directives.KMONS,
            "6 = bog body / white very ugly thing w:2")
        api:emit(directives.KMONS, "7 = blizzard demon")

        if reaper_glyphs then
            api:emit(directives.KMONS,
                reaper_glyphs .. " = " .. reaper)
        end

        api:emit(directives.KMONS, "8 = ice fiend")
        monsters.record_random_list(api,
            monsters.weighted_entries(simul.mocking ..
                " / ice devil", 144) ..
            " / " .. monsters.weighted_entries(simul.savage, 48) ..
            " / freezing wraith w:80 / " .. simul.cruel)

        return
    end

    api:emit(directives.KMONS,
        "1 = " .. simul.mocking .. " / white imp / ufetubus")
    api:emit(directives.KMONS, "2 = " .. simul.savage)
    api:emit(directives.KMONS, "3 = ice statue")
    api:emit(directives.KMONS, "4 = ice devil")
    api:emit(directives.KMONS, "5 = " .. simul.cruel)
    api:emit(directives.KMONS,
        "6 = freezing wraith / white ugly thing w:2")
    api:emit(directives.KMONS, "7 = bog body")
    api:emit(directives.KMONS,
        (reaper_glyphs or "8") .. " = " .. reaper)
    monsters.record_random_list(api,
        monsters.weighted_entries(simul.mocking ..
            " / white imp / ufetubus", 120) ..
        " / " .. monsters.weighted_entries(simul.savage, 48) ..
        " / ice devil w:80 / " .. simul.cruel)
end

-- This entry point keeps a reaper on the authored E glyph; the named
-- cold-resistance equipment in `undead` protects it from its own fog.
function monsters.undead_reaper_e(api)
    monsters.undead(api, "E")
end

-- Natural caves use wolves and yaks at easy depth, then ice dragons,
-- frosthearts, and shard shrikes in hard caves. The white draconian's
-- weapon roll stays attached to that actor as one source KMONS request.
function monsters.natural(api)
    if hard(api) then
        api:emit(directives.KMONS,
            "1 = polar bear / rime drake")
        api:emit(directives.KMONS, "2 = white ugly thing")
        api:emit(directives.KMONS,
            "3 = orange crystal statue")
        api:emit(directives.KMONS, "4 = ice dragon")
        api:emit(directives.KMONS,
            "5 = ironbound frostheart")
        api:emit(directives.KMONS,
            "6 = white draconian ; " ..
            weighted.describe(draconian_weapons, "freezing", nil, "|") ..
            " . cloak")
        api:emit(directives.KMONS, "7 = frost giant")
        api:emit(directives.KMONS, "8 = shard shrike")
        monsters.record_random_list(api,
            "polar bear w:15 / rime drake w:15 / ice dragon" ..
            " / ironbound frostheart w:5")

        return
    end

    api:emit(directives.KMONS, "1 = wolf / yak")
    api:emit(directives.KMONS, "2 = polar bear")
    api:emit(directives.KMONS, "3 = ice statue")
    api:emit(directives.KMONS, "4 = rime drake")
    api:emit(directives.KMONS, "5 = death yak")
    api:emit(directives.KMONS, "6 = white ugly thing")
    api:emit(directives.KMONS,
        "7 = ironbound frostheart")
    api:emit(directives.KMONS, "8 = frost giant")
    monsters.record_random_list(api,
        "wolf w:30 / yak w:30 / polar bear w:15" ..
        " / rime drake / death yak w:5")
end

return monsters
