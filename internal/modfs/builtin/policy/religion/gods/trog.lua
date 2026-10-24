-- Trog opposes magic study while worship lasts. Source join_trog_skills
-- disables magic training controls, but this port projects the same lockout
-- from live worship so leaving Trog restores earlier saved choices without
-- erasing skill points. Gnoll distributed training is the source exception.
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local order = require("data.skill_order")
local brothers = require("policy.abilities.trog.brothers")
local hand = require("policy.religion.trog.hand")

local trog = {}

-- Source SK_SPELLCASTING through SK_LAST_MAGIC are harmful under Trog.
-- The shared training owner asks this optional god hook at every decision.
function trog.forbids_training(ctx, player, skill_id)
    if not order.is_magic(skill_id) then
        return false
    end

    return levels.effective(ctx, player,
        mutations.MUT_DISTRIBUTED_TRAINING) == 0
end

-- Leaving Trog dismisses temporary divine allies and ends the Hand.
-- Gifted equipment remains an ordinary item on its current floor.
function trog.leave(ctx, player)
    hand.clear(ctx, player)
    brothers.dismiss(ctx, player)
end

-- Penance immediately suspends these temporary gifts while worship
-- itself and its historical piety stay in the saved player component.
function trog.on_penance(ctx, player)
    trog.leave(ctx, player)
end

return trog
