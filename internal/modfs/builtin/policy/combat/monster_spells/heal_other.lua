local ally_target = require("policy.combat.monster_support.ally_target")
local healing = require("policy.combat.monster_support.healing")
local component = require("constants.component")
local spells = require("ids.spells")

local heal_other = {}

-- Unlike self-heal AI, the source allied beam values even one missing HP.
local function benefits(ctx, target)
    local health = ctx:get(target, component.HEALTH)

    return health ~= nil and health.current < health.max
end

-- Only a live, hurt ally in beam reach earns a Heal Other cast slot.
function heal_other.plan(ctx, caster)
    return ally_target.plan(ctx, caster, spells.SPELL_HEAL_OTHER, benefits)
end

-- The caster supplies spell HD for the roll; the ally owns the healed HP.
function heal_other.resolve(ctx, caster, _, _, plan)
    local target = ally_target.selected(ctx, caster, plan)

    if not target or not benefits(ctx, target) then
        return
    end

    healing.other(ctx, caster, target)
end

return heal_other
