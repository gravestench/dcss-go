-- Dragon and draconian rooms have separate easy and hard source rosters.
-- This hook keeps their authored equipment and substitutions together.
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")
local monsters = require("policy.generation.vaults.ice_cave.monsters")
local weighted = require("policy.generation.vaults.ice_cave.weighted_items")

local map = {}

local draconian_weapons = {
    ["broad axe"] = 1,
    ["halberd"] = 2,
    ["morningstar"] = 2,
    ["scimitar"] = 2,
}

-- This source `knight` table is the same weapon set used by the original
-- dungeon Lua helper. It is local content, not a new engine rule.
local knight_weapons = {
    ["bardiche"] = 5,
    ["battleaxe"] = 15,
    ["broad axe"] = 10,
    ["demon blade"] = 5,
    ["demon trident"] = 5,
    ["demon whip"] = 5,
    ["dire flail"] = 10,
    ["double sword"] = 5,
    ["eveningstar"] = 5,
    ["executioner's axe"] = 5,
    ["glaive"] = 10,
    ["great mace"] = 10,
    ["great sword"] = 15,
    ["lajatang"] = 5,
    ["morningstar"] = 10,
    ["scimitar"] = 15,
    ["triple sword"] = 5,
}

-- Hard maps replace easy reptiles with dragons and improve the keyed
-- draconians' freezing weapons. Source room shuffles then choose which
-- leader occupies each authored location.
function map.site_2(api)
    if difficulty.hard(api) then
        api:emit(directives.KITEM, "k = any jewellery randart")
        api:emit(directives.MONS,
            "lindwurm simulacrum / ice dragon simulacrum" ..
            " / storm dragon simulacrum / golden dragon simulacrum")
        api:emit(directives.MONS,
            "ice dragon, orange crystal statue, golden dragon")
        api:emit(directives.KMONS,
            "D = white draconian ; " ..
            weighted.describe(draconian_weapons, "freezing", nil, "|") ..
            " . cloak")
        api:emit(directives.KMONS,
            "E = white draconian knight ; " ..
            weighted.describe(knight_weapons, "freezing", "good_item", "|") ..
            " . cloak good_item")
        monsters.record_random_list(api,
            "lindwurm simulacrum / swamp dragon simulacrum" ..
            " / ice dragon simulacrum / golden dragon simulacrum" ..
            " / white draconian / ice dragon")
        api:emit(directives.NSUBST, "3 = 3 / 2")
        api:emit(directives.SHUFFLE, "24 / DE")
        return
    end

    api:emit(directives.KITEM, "k = any jewellery good_item")
    api:emit(directives.MONS,
        "steam dragon simulacrum / acid dragon simulacrum" ..
        " / komodo dragon simulacrum / lindwurm simulacrum w:5")
    api:emit(directives.MONS,
        "rime drake, ice statue, ice dragon, white draconian")
    monsters.record_random_list(api,
        "steam dragon simulacrum / acid dragon simulacrum" ..
        " / komodo dragon simulacrum / lindwurm simulacrum" ..
        " / rime drake w:20")
    api:emit(directives.SUBST, "4 = 45")
end

return map
