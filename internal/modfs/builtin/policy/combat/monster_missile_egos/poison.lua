-- Source ranged-attack.cc gives ordinary poisoned ammunition a three in
-- four chance after a hit. A poisoned dart instead uses its own duration
-- roll during contact; the ranged action records that dose separately.
local curare = require("policy.combat.monster_tactical.curare")
local player_poison = require("policy.combat.player_poison")
local streams = require("constants.rng_streams")
local items = require("ids.items")

local poison = {}

-- Poison dose scales with the base hit; zero damage still has a legal
-- source roll bound and can deliver poison on contact.
function poison.poisoned(ctx, _, definition, kind, damage)
    if kind.id == items.MI_DART or
        ctx:random(streams.MELEE, 4) == 0 then
        return
    end

    local variable = math.max(1, math.floor(damage * 3 / 2))
    local dose = 6 + ctx:random(streams.MELEE, 8) +
        ctx:random(streams.MELEE, variable)

    player_poison.deliver(ctx, dose, definition.id)
end

-- The same source curare rule serves monster spells and thrown darts.
-- It checks resistance before rolling poison, breath damage, and slow.
function poison.curare(ctx, attacker)
    curare.apply(ctx, attacker, ctx:player(), streams.MELEE)
end

return poison
