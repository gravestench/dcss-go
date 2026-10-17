-- Source: mon-place.cc:random_demon_by_tier(1/2) and traps.cc:zot_effects.
local categories = require("constants.catalog")
local ids = require("ids.traps")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")

local effect = {}

local tier_two = {
    monsters.MONS_GREEN_DEATH,
    monsters.MONS_BLIZZARD_DEMON,
    monsters.MONS_BALRUG,
    monsters.MONS_CACODEMON,
    monsters.MONS_HELL_BEAST,
    monsters.MONS_HELLION,
    monsters.MONS_REAPER,
    monsters.MONS_LOROCYPROCA,
    monsters.MONS_TORMENTOR,
    monsters.MONS_SHADOW_DEMON,
}

local tier_one = {
    monsters.MONS_BRIMSTONE_FIEND,
    monsters.MONS_ICE_FIEND,
    monsters.MONS_TZITZIMITL,
    monsters.MONS_HELL_SENTINEL,
    monsters.MONS_EXECUTIONER,
}

function effect.apply(ctx, player)
    local tier = ctx:random(streams.TRAPS, 10) < 6 and tier_two or tier_one
    local kind_id = tier[ctx:random(streams.TRAPS, #tier) + 1]
    local creature = summons.spawn(ctx, player,
        ids.TRAP_ZOT, kind_id, 0, 1, {
            hostile = true,
            source_category = categories.TRAPS,
        })

    if creature then
        ctx:emit("trap", "You sense a hostile presence.")
    end
end

return effect
