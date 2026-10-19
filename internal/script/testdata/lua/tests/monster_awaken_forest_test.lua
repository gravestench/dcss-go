-- Awaken Forest stores one caster condition and reads live tree terrain
-- when later actions strike. No test schema or terrain copy is declared.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.fixtures.monster_status")
local forest = require("policy.combat.monster_plants.forest")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local terrain = require("constants.terrain")

local test = {}

-- A dryad can wake one reachable forest. Its saved timer drives a later
-- strike and prevents a second caster on the level from waking another.
function test.run(ctx)
    local player = fixture.actor(ctx,
        monsters.MONS_HUMAN, 7, 7, 30)

    ctx:add(player, component.PLAYER, {})

    local caster = fixture.actor(ctx,
        monsters.MONS_DRYAD, 1, 1, 30)
    local other = fixture.actor(ctx,
        monsters.MONS_DRYAD, 2, 2, 30)
    local victim = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 3, 1, 30)

    ctx:add(victim, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 500,
    })

    local live = fixture.context(ctx, player, 0)
    local effect = effects.effect(spells.SPELL_AWAKEN_FOREST)

    -- The only tree is adjacent to the victim and visible to both casters.
    function live:cell(_, x, y)
        if x == 4 and y == 1 then
            return terrain.DNGN_TREE
        end

        return terrain.DNGN_FLOOR
    end

    local plan = effect.plan(live, caster, victim)

    harness.truthy(plan, "a tree can reach an enemy in sight")
    effect.resolve(live, caster, victim, nil, plan)

    local state = ctx:get(caster, component.MONSTER_AWAKE_FOREST)

    harness.truthy(state and state.remaining_aut >= 50,
        "the caster owns a saved forest timer")
    harness.falsy(effect.plan(live, other, victim),
        "only one forest may be awake on a level")

    forest.tick(live, caster, 10)

    harness.truthy(ctx:get(victim, component.HEALTH).current < 30,
        "a later caster action makes the tree deal real damage")
    harness.equal(ctx:get(caster,
        component.MONSTER_AWAKE_FOREST).remaining_aut,
        state.remaining_aut - 10,
        "the saved timer ages with the caster action")

    local health = ctx:get(caster, component.HEALTH)

    health.current = 0
    ctx:set(caster, component.HEALTH, health)
    forest.tick(live, caster, 10)

    harness.falsy(ctx:has(caster, component.MONSTER_AWAKE_FOREST),
        "death removes the forest's only saved owner")
end

return test
