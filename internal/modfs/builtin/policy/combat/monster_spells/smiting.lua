-- Smiting selects a visible foe directly. Divine damage bypasses shields,
-- evasion, AC, and elemental resistance in the source monster cast.
local direct = require("policy.combat.monster_direct")
local roll = require("policy.combat.roll")
local spells = require("ids.spells")

local effect = {}

-- A direct strike needs sight and range, but no projectile-clear ray.
function effect.plan(ctx, caster, foe)
    return direct.plan(ctx, caster, foe, spells.SPELL_SMITING)
end

-- Source mon-cast.cc:_cast_smiting uses 7 + random2avg(11, 2).
-- Example: resolving a minimum roll against a monster removes seven HP.
function effect.resolve(ctx, caster, foe, _, plan)
    direct.require(ctx, caster, foe, plan)

    local amount = 7 + roll.average_two(ctx, "monster_spell", 11)

    direct.damage(ctx, caster, foe, amount)
    ctx:emit("spell", "Divine power smites the target!")
end

return effect
