local component = require("constants.component")
local monster_poison = require("policy.combat.monster_poison")
local player_resistance = require("policy.combat.player_resistance")
local status = require("policy.combat.monster_hexes.status")
local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")

local virulence = {}

-- A fully immune target cannot have its poison resistance weakened.
function virulence.viable(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        return player_resistance.poison(ctx, defender) < 3
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return monster_poison.effective_resistance(ctx, defender,
        definition) < 3
end

-- Example: virulence.apply(ctx, nil, defender) with player with zero RNG -> 120 aut poison vulnerability
-- Lower poison resistance only after the hex contact and saving throw succeed.
function virulence.apply(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        local turns = 12 + ctx:random(streams.MONSTER_SPELL, 18)

        status.poison_vulnerability(ctx, defender, turns * 10)
        ctx:emit("combat", "You feel vulnerable to poison.")

        return
    end

    local turns = 20 + ctx:random(streams.MONSTER_SPELL, 11)

    status.poison_vulnerability(ctx, defender, turns * 10)
end

return virulence
