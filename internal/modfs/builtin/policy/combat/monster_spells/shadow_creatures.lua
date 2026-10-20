local branch_ids = require("ids.branches")
local component = require("constants.component")
local pool = require("policy.population.pool")
local roll = require("policy.combat.roll")
local roster = require("policy.population.roster")
local scenarios = require("constants.scenarios")
local self_target = require("policy.combat.monster_support.self_target")
local strength = require("policy.combat.monster_summons.strength")
local summons = require("policy.magic.effects.summons.common")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

-- RANDOM_MOBILE_MONSTER asks the active level's population owner for its
-- roster. Current playable Dungeon floors use their numeric level ID as
-- depth; other branches wait for their own depth and roster domain.
function effect.plan(ctx, caster, foe, slot)
    local position = ctx:get(caster, component.POSITION)

    if not position or
        ctx:level_branch(position.level_id) ~= branch_ids.BRANCH_DUNGEON then
        return nil
    end

    return self_target.plan(caster)
end

-- Each creature is drawn from the same Dungeon population rule used by
-- generation. The current floor's depth and mod-added population rows can
-- affect the choice without an effect-specific monster switch.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local position = ctx:get(caster, component.POSITION)
    local scenario_id = scenarios.GENERATED_DUNGEON_BASIC
    local allowed = roster.allowed(scenario_id, branch_ids.BRANCH_DUNGEON)
    local choices, total = pool.at_depth(branch_ids.BRANCH_DUNGEON,
        position.level_id,
        allowed, scenario_id)
    local hd = strength.spell_hd(ctx, caster)
    local count = 1 + roll.spell(ctx, math.floor(hd / 5) + 1)

    for _ = 1, count do
        local kind = pool.pick(ctx, choices, total,
            streams.MONSTER_SPELL)

        summons.spawn(ctx, caster, spells.SPELL_SHADOW_CREATURES,
            kind, 5, nil)
    end
end

return effect
