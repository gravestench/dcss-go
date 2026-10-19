local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local catalog = require("policy.catalog")
local choice = require("policy.combat.monster_summons.choice")
local component = require("constants.component")
local roll = require("policy.combat.roll")
local self_target = require("policy.combat.monster_support.self_target")
local summons = require("policy.magic.effects.summons.common")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local effect = {}

-- Spriggan berserkers call a different animal set from other Trog casters.
-- Both arrays are explicit because source RANDOM_ELEMENT uses one draw.
local spriggan = {
    monsters.MONS_POLAR_BEAR,
    monsters.MONS_ELEPHANT,
    monsters.MONS_DEATH_YAK,
}

local ordinary = {
    monsters.MONS_BLACK_BEAR,
    monsters.MONS_OGRE,
    monsters.MONS_TROLL,
    monsters.MONS_TWO_HEADED_OGRE,
    monsters.MONS_DEEP_TROLL,
}

-- The source AI refuses a third Brother until its Berserker Rage clears the
-- caster's count. Check before spending the cast or drawing random numbers.
function effect.plan(ctx, caster, foe, slot)
    local state = ctx:get(caster, component.MONSTER_BROTHERS)

    if state and state.count >= 2 then
        return nil
    end

    return self_target.plan(caster)
end

-- Source power uses ordinary hit dice, not modified spell HD. The two
-- five-HD draws have a fixed sequence point; then the chosen ally is born
-- frenzied and the caster's attempt count increases even if placement fails.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local hd = definition.hd
    local spread = hd * 5
    local power = hd * 20 + roll.spell(ctx, spread)

    power = power - roll.spell(ctx, spread)

    local pool = ordinary

    if actor.kind_id == monsters.MONS_SPRIGGAN_BERSERKER then
        pool = spriggan
    end

    local kind = choice.uniform(ctx, pool)
    local degree = math.min(2 +
        math.floor(roll.spell(ctx, power) / 4), 6)
    local creature = summons.spawn(ctx, caster,
        spells.SPELL_BROTHERS_IN_ARMS, kind, degree, nil)

    if creature then
        allegiance.start_berserk(ctx, creature)
    end

    local state = ctx:get(caster, component.MONSTER_BROTHERS)

    if state then
        state.count = state.count + 1
        ctx:set(caster, component.MONSTER_BROTHERS, state)
    else
        ctx:add(caster, component.MONSTER_BROTHERS, {
            count = 1,
        })
    end
end

return effect
