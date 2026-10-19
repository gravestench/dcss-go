local hand = require("policy.combat.monster_support.trogs_hand")
local self_target = require("policy.combat.monster_support.self_target")

local trogs_hand = {}

-- Neither regeneration nor strong will can be invoked again while active.
function trogs_hand.plan(ctx, caster)
    if hand.active(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- One invocation grants both defenses through their shared saved owner.
function trogs_hand.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    hand.invoke(ctx, caster)
end

return trogs_hand
