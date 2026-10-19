-- Grasping Roots is a direct monster spell. Cast eligibility checks the
-- shared root owner; the saved entity plan prevents a later retarget.
-- Source: mon-cast.cc:_cast_grasping_roots and spl-monench.cc.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local fastroot = require("policy.magic.effects.zaps.fastroot")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}
local POWER_PER_HD = 12

-- The source monster refuses to spend a cast when its selected foe is
-- already gripped, immune to constriction, or standing on unsafe ground.
function effect.plan(ctx, caster, foe)
    if not foe or not targets.enemy(ctx, caster, foe) or
        not fastroot.eligible(ctx, caster, foe) then
        return nil
    end

    return direct.plan(ctx, caster, foe, spells.SPELL_GRASPING_ROOTS)
end

-- Duration is four turns plus a two-draw average of stochastically
-- rounded power/10. Draw only after the selected target commits.
function effect.resolve(ctx, caster, foe, _, plan)
    direct.require(ctx, caster, foe, plan)

    if not targets.enemy(ctx, caster, foe) or
        not fastroot.eligible(ctx, caster, foe) then
        return
    end

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local power = monster_stats.spell_hit_dice(ctx, caster,
        definition) * POWER_PER_HD
    local bound = roll.random_divide(ctx, power, 10,
        streams.MONSTER_SPELL)
    local turns = 4 + roll.average_two(ctx,
        streams.MONSTER_SPELL, bound)

    ctx:emit("spell", "Roots burst forth from the earth!")
    fastroot.apply(ctx, caster, foe, turns, power)
end

return effect
