-- Injury Bond marks eligible allied monsters; the health owner later uses
-- their saved protector handles to redirect ordinary incoming damage.
-- Source: mon-cast.cc:SPELL_INJURY_BOND and _can_injury_bond.
local actors = require("policy.combat.monster_area.actors")
local component = require("constants.component")
local bond = require("policy.combat.monster_injury_bond")
local self_target = require("policy.combat.monster_support.self_target")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}
local SIGHT_RADIUS = 7
local MIN_DURATION_AUT = 40
local DURATION_VARIANCE = 80

-- A protected, charmed, or enemy monster is not a new bond recipient.
-- This check is shared by preflight and committed resolution.
local function eligible(ctx, caster, target)
    if target == caster or ctx:has(target, component.PLAYER) or
        not targets.aligned(ctx, caster, target) or
        ctx:has(target, component.MONSTER_INJURY_BOND) then
        return false
    end

    local allegiance = ctx:get(target, component.MONSTER_ALLEGIANCE)

    return not allegiance or allegiance.charm_aut <= 0
end

-- A self-target plan carries the caster while the ally group stays live.
function effect.plan(ctx, caster)
    for _, target in ipairs(actors.los(ctx, caster, SIGHT_RADIUS)) do
        if eligible(ctx, caster, target) then
            return self_target.plan(caster)
        end
    end

    return nil
end

-- The source rolls a separate forty-through-119-aut bond for each ally.
-- Example: two guards can protect the caster for different durations.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    for _, target in ipairs(actors.los(ctx, caster, SIGHT_RADIUS)) do
        if eligible(ctx, caster, target) then
            local duration = MIN_DURATION_AUT +
                ctx:random(streams.MONSTER_SPELL,
                    DURATION_VARIANCE)

            bond.grant(ctx, target, caster, duration)
        end
    end
end

return effect
