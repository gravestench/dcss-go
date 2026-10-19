local choice = require("policy.combat.monster_summons.choice")
local component = require("constants.component")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local target = require("policy.combat.monster_summons.target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Source pick_random_wraith favors ordinary wraiths. Each summoned spirit
-- gets a separate draw and a saved link to the original victim when present.
local wraiths = {
    {
        id = monsters.MONS_SHADOW_WRAITH,
        weight = 1,
    },

    {
        id = monsters.MONS_WRAITH,
        weight = 5,
    },

    {
        id = monsters.MONS_FREEZING_WRAITH,
        weight = 2,
    },

    {
        id = monsters.MONS_PHANTASMAL_WARRIOR,
        weight = 2,
    },
}

-- The chosen victim's cell crosses the intent boundary unchanged.
function effect.plan(ctx, caster, foe, slot)
    return target.plan(ctx, caster, foe)
end

-- Two or three wraiths gather at the original cell. A moved or dead foe
-- does not make the cast follow it to a newly occupied location.
function effect.resolve(ctx, caster, foe, slot, plan)
    target.require_cell(ctx, caster, plan)

    local hd = strength.spell_hd(ctx, caster)
    local count = 2 + roll.spell(ctx, 2)
    local degree = math.min(2 + math.floor(hd / 5), 6)
    local victim = nil

    if plan.entity and ctx:has(plan.entity, component.ACTOR) then
        local position = ctx:get(plan.entity, component.POSITION)

        if position and position.level_id == plan.level_id and
            position.x == plan.x and position.y == plan.y then
            victim = plan.entity
        end
    end

    for _ = 1, count do
        local creature = summons.spawn(ctx, caster, spells.SPELL_HAUNT,
            choice.weighted(ctx, wraiths), degree, nil, {
                anchor = plan,
            })

        if creature and victim and victim ~= creature then
            ctx:add(creature, component.SUMMON_HAUNTING, {
                target = victim,
            })
        end
    end
end

return effect
