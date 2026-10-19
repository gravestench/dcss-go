-- Brain Feed uses the production stat-loss schema and source target plan.
-- A deterministic host draw exercises the successful one-in-three branch.
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local target_kind = require("constants.target_kind")

local test = {}

-- Drive the real ECS component owner while providing only the sight service
-- absent from the isolated Lua harness. This avoids redefining any schema.
function test.run(ctx)
    local caster = ctx:create()
    local player = ctx:create()
    local monster = ctx:create()

    ctx:add(caster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_SORCERER,
        speed = 10,
    })
    ctx:add(caster, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })
    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_GOBLIN,
        speed = 10,
    })
    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 2,
    })

    local sight = setmetatable({}, { __index = ctx })

    -- Direct spells need ordinary visibility, but this test has no grid.
    function sight:visible()
        return true
    end

    local effect = effects.effect(spells.SPELL_BRAIN_FEED)

    harness.falsy(effect.plan(sight, caster, monster),
        "Brain Feed is pointless against a monster foe")

    local plan = effect.plan(sight, caster, player)

    harness.equal(plan.kind, target_kind.ENTITY,
        "Brain Feed saves an entity target")
    harness.equal(plan.entity, player,
        "the planned player remains the target")

    effect.resolve(sight, caster, player, nil, plan)

    local loss = ctx:get(player, component.STAT_LOSS)

    harness.equal(loss.intelligence, 1,
        "the successful source roll drains Intelligence")
    harness.equal(loss.strength, 0,
        "Brain Feed does not drain a different stat")
end

return test
