local component = require("constants.component")
local roll = require("policy.combat.roll")
local target = require("policy.combat.monster_summons.target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local spectral_gear = require("policy.combat.monster_summons.spectral_gear")
local undead = require("policy.combat.monster_summons.undead")
local catalog = require("policy.catalog")
local hit_points = require("policy.population.hit_points")

local effect = {}

-- Keep the victim's cell through the intent; spectral orcs appear around
-- that cell even if the original target moves before resolution.
function effect.plan(ctx, caster, foe, slot)
    return target.plan(ctx, caster, foe)
end

-- Source coinflip and rarer knight/warlord rolls determine the original
-- orc identity. The spectral actor stores that base kind for combat rules.
function effect.resolve(ctx, caster, foe, slot, plan)
    target.require_cell(ctx, caster, plan)

    local count = 1 + roll.spell(ctx, 3)

    for _ = 1, count do
        local base = monsters.MONS_ORC

        if roll.spell(ctx, 2) == 0 then
            base = monsters.MONS_ORC_WARRIOR
        elseif roll.spell(ctx, 3) == 0 then
            base = monsters.MONS_ORC_KNIGHT
        elseif roll.spell(ctx, 10) == 0 then
            base = monsters.MONS_ORC_WARLORD
        end

        local base_definition = catalog.get("monsters", base)
        local creature = summons.spawn(ctx, caster,
            spells.SPELL_SUMMON_SPECTRAL_ORCS,
            monsters.MONS_SPECTRAL_THING, 3, nil, {
                anchor = plan,
                hd = base_definition.hd,
                hp = hit_points.roll(ctx, undead.average_hp(
                    monsters.MONS_SPECTRAL_THING, base_definition.hd)),
            })

        if creature then
            ctx:add(creature, component.SUMMON_UNDEAD, {
                base_kind_id = base,
            })
            spectral_gear.give(ctx, creature, base, plan.level_id)
        end
    end
end

return effect
