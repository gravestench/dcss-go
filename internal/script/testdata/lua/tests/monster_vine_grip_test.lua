-- A vine's first source attack holds its victim; its second attack hurts.
-- The fixture supplies only a sparse grid and deterministic melee draws.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local grip = require("policy.combat.monster_plants.vine_grip")
local chain = require("policy.combat.monster_plants.vine_chain")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- The victim keeps a source handle and loses the grip when that head dies.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 8, 8, 30)
    local caster = fixture.actor(ctx, monsters.MONS_DRYAD, 1, 1, 30)
    local vine = fixture.actor(ctx,
        monsters.MONS_SNAPLASHER_VINE, 3, 3, 30)
    local victim = fixture.actor(ctx, monsters.MONS_GOBLIN, 4, 3, 30)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})
    ctx:add(vine, component.MONSTER_VINE, {
        target = victim,
        anchor_x = 2,
        anchor_y = 3,
    })
    ctx:add(vine, component.SUMMON, {
        owner = caster,
        source_id = spells.SPELL_AWAKEN_VINES,
        attitude = attitudes.HOSTILE,
        expires_aut = 200,
    })
    ctx:add(victim, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 200,
    })

    function game:random(_, bound)
        return bound - 1
    end

    grip.contact(game, vine, victim)

    local state = ctx:get(victim, component.MONSTER_VINE_GRIP)

    harness.truthy(state, "the first attack makes a physical grip")
    harness.equal(state.by, vine, "the held actor keeps the vine handle")
    harness.truthy(ctx:get(victim, component.HEALTH).current < 30,
        "the second source attack deals ordinary lash damage")

    local step = chain.act(game, vine)

    harness.equal(step.dx, -1,
        "a holding vine retracts toward its saved tree anchor")
    game:move_actor(vine, 1, 2, 3)
    chain.refresh(game, vine)
    harness.equal(ctx:get(victim, component.POSITION).x, 3,
        "the vine pulls its held victim into the vacated head cell")

    local health = ctx:get(vine, component.HEALTH)

    health.current = 0
    ctx:set(vine, component.HEALTH, health)
    grip.tick(game, caster, 10)

    harness.falsy(ctx:has(victim, component.MONSTER_VINE_GRIP),
        "death releases the vine's held victim")
end

return test
