-- Fire and frost ammunition add damage through the same brand owner as
-- flaming and freezing melee hits. Its resistance handling and messages
-- stay authoritative when the source is a thrown missile.
local brands = require("policy.combat.brands")
local weapon_brands = require("constants.weapon_brands")

local elemental = {}

-- A post-contact brand reads current player health after base damage.
function elemental.flame(ctx, attacker, definition, _, damage)
    local player = ctx:player()
    local health = ctx:get(player, "core.health")

    brands.apply(ctx, weapon_brands.FLAMING, damage,
        definition.id, definition.name, health, attacker)
end

-- Frost uses its own resistance profile but shares the hit envelope.
function elemental.frost(ctx, attacker, definition, _, damage)
    local player = ctx:player()
    local health = ctx:get(player, "core.health")

    brands.apply(ctx, weapon_brands.FREEZING, damage,
        definition.id, definition.name, health, attacker)
end

return elemental
