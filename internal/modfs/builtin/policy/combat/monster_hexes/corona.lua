local component = require("constants.component")
local status = require("policy.combat.monster_hexes.status")
local streams = require("constants.rng_streams")
local invisibility = require("policy.potions.invisibility")

local corona = {}

-- Source AI does not waste Corona on an already backlit target. The player
-- rule includes glowing mutations and contamination as well as this status.
function corona.viable(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        return not invisibility.backlit(ctx, defender)
    end

    return not status.backlit(ctx, defender) and
        not ctx:has(defender, component.STICKY_FLAME)
end

-- Corona is a light source attached to the defender. The saved duration is
-- consumed by visibility policy, so the enchantment outlives this beam hit.
function corona.apply(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        local turns = 15 + ctx:random(streams.MONSTER_SPELL, 21)

        status.corona(ctx, defender, turns * 10)
        ctx:emit("combat", "You are outlined in light.")

        return
    end

    local turns = 20 + ctx:random(streams.MONSTER_SPELL, 11)

    status.corona(ctx, defender, turns * 10)
end

return corona
