-- Yredelemnul's rare wrath servant is a hostile, permanent derived
-- undead. The base comes from the effective Dungeon population, while
-- the normal necromancy summon owner records its HP, HD, and base kind.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local necromancy = require("policy.magic.effects.summons.necromancy")
local streams = require("constants.rng_streams")
local zombie_base = require("policy.population.zombie_base")

local zombies = {}

-- Source first chooses a skeleton one time in four, then redraws a base
-- until that skeleton can exist. Both forms use the player's cell as a
-- placement anchor, with the shared summon owner finding an open neighbor.
function zombies.spawn(ctx, player, level)
    local skeleton = ctx:random(streams.CARDS, 4) == 0
    local base_id = zombie_base.pick(ctx, player, level, skeleton)
    local kind_id = skeleton and monsters.MONS_SKELETON or
        monsters.MONS_ZOMBIE
    local position = ctx:get(player, component.POSITION)

    return necromancy.raise(ctx, player, gods.YREDELEMNUL,
        kind_id, base_id, position, attitudes.HOSTILE,
        categories.GODS, streams.CARDS)
end

return zombies
