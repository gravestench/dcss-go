-- Symbol of Torment uses the same nonlethal area rule as a Torment scroll,
-- centered on the monster rather than on a player reader.
local area = require("policy.combat.torment_area")
local channels = require("constants.message_channels")
local self_target = require("policy.combat.monster_support.self_target")

local effect = {}

-- Avoid spending the cast when no vulnerable enemy is in LOS_NO_TRANS, or
-- when an allied caster would torment the player. The chosen caster crosses
-- the ordinary saved intent boundary as a self target.
function effect.plan(ctx, caster)
    if not area.worthwhile(ctx, caster) then
        return nil
    end

    return self_target.plan(caster)
end

-- Validate the saved source before Torment samples the current level. The
-- shared owner applies each victim's resistance and health policy.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)
    area.apply(ctx, caster, channels.SPELL)
end

return effect
