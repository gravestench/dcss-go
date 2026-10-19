-- Draining Gaze sends direct enchantment power to the shared MP and
-- antimagic owner without rolling a beam hit or tracing a projectile.
local drain = require("policy.combat.monster_hexes.drain_magic")
local gazes = require("policy.combat.monster_gazes")
local spells = require("ids.spells")

local effect = {}

-- Source `can_see` is the only targeting requirement for this gaze.
function effect.plan(ctx, caster, foe)
    return gazes.plan(ctx, caster, foe,
        spells.SPELL_DRAINING_GAZE)
end

-- Source default power is twelve spell HD, passed directly as enchantment
-- power. The shared drain owner handles Ghost Moth healing from actual loss.
-- Example: a zero-MP player yields no healing.
function effect.resolve(ctx, caster, foe, _, plan)
    gazes.require(ctx, caster, foe, plan)

    local power = gazes.hit_dice(ctx, caster, true) * 12

    drain.apply_power(ctx, caster, foe, power)
end

return effect
