-- Awaken Forest attaches one timed caster condition. The forest policy
-- derives strikes from live tree terrain and actor allegiance each action.
local component = require("constants.component")
local forest = require("policy.combat.monster_plants.forest")
local self_target = require("policy.combat.monster_support.self_target")

local effect = {}

-- The source refuses another awake forest on this level. At least one
-- enemy must currently be close enough to a visible tree for an attack.
function effect.plan(ctx, caster)
    local position = ctx:get(caster, component.POSITION)

    if not position or forest.active(ctx, position.level_id) or
        #forest.victims(ctx, caster) == 0 then
        return nil
    end

    return self_target.plan(caster)
end

-- Recheck the saved caster and current tree geometry before spending the
-- duration roll. Another cast may have awakened the level meanwhile.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)
    forest.awaken(ctx, caster)
end

return effect
