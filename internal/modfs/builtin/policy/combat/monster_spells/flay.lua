-- Flay is a direct natural-life enchantment; its saved wound owner handles
-- damage, expiry, and recovery after the cast has fixed its victim.
-- Source: mon-cast.cc:_cast_flay and _flay.
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local flay = require("policy.combat.monster_flay")
local spells = require("ids.spells")

local effect = {}

-- Source AI refuses non-natural foes before making a random draw. Direct
-- targeting then fixes that living foe in the ordinary monster intent.
function effect.plan(ctx, caster, foe)
    if not foe or not ctx:has(foe, component.HEALTH) or
        not flay.natural(ctx, foe) then
        return nil
    end

    return direct.plan(ctx, caster, foe, spells.SPELL_FLAY)
end

-- Recheck the original handle and current holiness. Another target may
-- become nearby between planning and resolution; it must not be flayed.
function effect.resolve(ctx, caster, foe, _, plan)
    direct.require(ctx, caster, foe, plan)

    if flay.natural(ctx, foe) then
        flay.apply(ctx, caster, foe)
    end
end

return effect
