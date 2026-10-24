-- Source ranged-attack.cc gives ordinary poisoned ammunition a three in
-- four chance after a hit. A poisoned dart instead uses its own duration
-- roll during contact; the ranged action records that dose separately.
local brands = require("policy.combat.brands")
local curare = require("policy.combat.monster_tactical.curare")
local resistance = require("policy.combat.player_resistance")
local streams = require("constants.rng_streams")
local items = require("ids.items")

local poison = {}

-- Poison_player in the source rejects immunity and usually resists a
-- positive rPois level. Keep the raw status writer separate because Curare
-- already checks resistance before calling it.
function poison.deliver(ctx, amount, source_id)
    local level = resistance.poison(ctx, ctx:player())

    if level >= 3 or level > 0 and
        ctx:random(streams.MELEE, 3) ~= 0 then
        return false
    end

    if level < 0 then
        amount = amount * 2
    end

    brands.poison(ctx, amount, source_id)

    return true
end

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

    poison.deliver(ctx, dose, definition.id)
end

-- The same source curare rule serves monster spells and thrown darts.
-- It checks resistance before rolling poison, breath damage, and slow.
function poison.curare(ctx, attacker)
    curare.apply(ctx, attacker, ctx:player(), streams.MELEE)
end

return poison
