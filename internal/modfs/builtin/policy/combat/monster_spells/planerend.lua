local branches = require("policy.combat.monster_summons.branches")
local component = require("constants.component")
local roll = require("policy.combat.roll")
local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local hit_points = require("policy.population.hit_points")

local effect = {}

-- A Planerend cast draws a fresh branch during resolution, not during
-- selection, so rejected intents leave the saved spell RNG untouched.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- The source chooses one branch per cast and one to three monsters from it.
-- Slime creatures receive a size-five saved component after placement.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local branch_id = branches.choose_planerend(ctx)
    local count = 1 + roll.spell(ctx, 3)

    for _ = 1, count do
        local kind = branches.planerend(ctx, branch_id)
        local options = nil

        if kind == monsters.MONS_SLIME_CREATURE then
            local definition = catalog.get("monsters", kind)

            options = {
                hp = hit_points.roll(ctx, definition.average_hp_10x) * 5,
            }
        end

        local creature = summons.spawn(ctx, caster,
            spells.SPELL_PLANEREND, kind, 1, nil, options)

        if creature and kind == monsters.MONS_SLIME_CREATURE then
            ctx:add(creature, component.SLIME_BLOB, {
                size = 5,
            })
        end
    end
end

return effect
