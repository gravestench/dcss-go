local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local undead = require("policy.combat.monster_summons.undead")
local spells = require("ids.spells")
local component = require("constants.component")
local hit_points = require("policy.population.hit_points")

local effect = {}

-- Undead kinds are independent population draws around the caster;
-- planning stores that actor, not one preselected kind.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The source high-level helper draws a separate undead kind for each summon.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local hd = strength.spell_hd(ctx, caster)
    local count = 2 + roll.spell(ctx, math.floor(hd / 5) + 1)
    local degree = math.min(2 + math.floor(hd / 5), 6)
    local position = ctx:get(caster, component.POSITION)

    for _ = 1, count do
        local kind = undead.pick(ctx)
        local options = nil
        local base = nil

        if undead.derived(kind) then
            base = undead.base(ctx, position, kind)
            options = {
                hd = base.hd,
                hp = hit_points.roll(ctx,
                    undead.average_hp(kind, base.hd)),
            }
        end

        local creature = summons.spawn(ctx, caster,
            spells.SPELL_SUMMON_UNDEAD, kind, degree, nil, options)

        if creature and base then
            ctx:add(creature, component.SUMMON_UNDEAD, {
                base_kind_id = base.id,
            })
        end
    end
end

return effect
