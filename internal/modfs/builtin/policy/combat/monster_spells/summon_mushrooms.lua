local component = require("constants.component")
local roll = require("policy.combat.roll")
local strength = require("policy.combat.monster_summons.strength")
local target = require("policy.combat.monster_summons.target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Source mushrooms are a ring around the current foe, so record its cell
-- before the action is spent rather than re-reading its later position.
function effect.plan(ctx, caster, foe, slot)
    return target.plan(ctx, caster, foe)
end

-- Try radius one before radius two for each mushroom. A full ring ends the
-- cast without creating a partial actor; one in three kinds is a Deathcap.
function effect.resolve(ctx, caster, foe, slot, plan)
    target.require_cell(ctx, caster, plan)

    local hd = strength.spell_hd(ctx, caster)
    local count = 2 + roll.spell(ctx, math.floor(hd / 4) + 1)
    local degree = math.min(2 + math.floor(hd / 5), 6)

    for _ = 1, count do
        local kind = monsters.MONS_WANDERING_MUSHROOM

        if roll.spell(ctx, 3) == 0 then
            kind = monsters.MONS_DEATHCAP
        end

        local x, y = target.open_spot(ctx, plan, kind)

        if not x then
            return
        end

        summons.spawn(ctx, caster, spells.SPELL_SUMMON_MUSHROOMS,
            kind, degree, nil, {
                anchor = plan,
                exact = {
                    x = x,
                    y = y,
                },
            })
    end
end

return effect
