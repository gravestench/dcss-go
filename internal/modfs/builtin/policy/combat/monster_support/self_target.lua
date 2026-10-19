local component = require("constants.component")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")

local self_target = {}

-- mon-cast.cc declines a pointless self-buff for an idle, nonsummoned ally.
-- Summoned allies may prepare magic before they acquire a foe.
function self_target.useful(ctx, caster, foe)
    return not (targets.allied(ctx, caster) and not foe and
        not ctx:has(caster, component.SUMMON))
end

-- A self spell still crosses the ordinary typed monster-intent boundary.
function self_target.plan(caster)
    return {
        kind = target_kind.ENTITY,
        entity = caster,
    }
end

-- A stale or rewritten intent must not let a self spell buff another actor.
function self_target.require_caster(plan, caster)
    if not plan or plan.kind ~= target_kind.ENTITY or
        plan.entity ~= caster then
        error("monster self spell target differs from caster")
    end
end

return self_target
