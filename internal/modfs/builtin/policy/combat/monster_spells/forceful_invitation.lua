local branches = require("policy.combat.monster_summons.branches")
local component = require("constants.component")
local roll = require("policy.combat.roll")
local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local spells = require("ids.spells")

local effect = {}

-- Invitation is cast at the summoner; the branch decision belongs to the
-- caster's saved component and is made only when the cast resolves.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Choose a branch once per caster, then draw one to three source monsters
-- from that branch. The shared creator gives each creature degree one.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local state = ctx:get(caster, component.MONSTER_INVITATION)

    if not state then
        state = {
            branch_id = branches.choose_invitation(ctx),
        }
        ctx:add(caster, component.MONSTER_INVITATION, state)
    end

    local count = 1 + roll.spell(ctx, 3)

    for _ = 1, count do
        summons.spawn(ctx, caster, spells.SPELL_FORCEFUL_INVITATION,
            branches.invitation(ctx, state.branch_id), 1, nil)
    end
end

return effect
