local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local boons = require("policy.combat.monster_support.boons")
local self_target = require("policy.combat.monster_support.self_target")

local rage = {}

-- A capable melee caster needs a nearby foe and no conflicting status.
function rage.plan(ctx, caster, foe)
    if boons.hasted(ctx, caster) or
        not allegiance.needs_berserk(ctx, caster, foe) then
        return nil
    end

    return self_target.plan(caster)
end

-- Frenzy and its later fatigue remain in the existing allegiance component.
function rage.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    allegiance.start_berserk(ctx, caster)
end

return rage
