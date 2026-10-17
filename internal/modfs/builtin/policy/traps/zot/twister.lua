-- Source: traps.cc:zot_effects[10].
local categories = require("constants.catalog")
local ids = require("ids.traps")
local monsters = require("ids.monsters")
local summons = require("policy.magic.effects.summons.common")

local effect = {}

function effect.apply(ctx, player)
    local creature = summons.spawn(ctx, player,
        ids.TRAP_ZOT, monsters.MONS_TWISTER, 2, 1, {
            hostile = true,
            source_category = categories.TRAPS,
        })

    if creature then
        ctx:emit("trap", "A huge vortex of air appears!")
    end
end

return effect
