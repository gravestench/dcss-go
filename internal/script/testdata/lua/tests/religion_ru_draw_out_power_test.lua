-- Draw Out Power cures urgent restraints and restores both resource pools.
-- Its cost is maximum-HP drain and shared exhaustion, not piety.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local ids = require("ids.abilities")
local jobs = require("ids.jobs")
local registry = require("policy.abilities.registry")
local species = require("ids.species")
local traps = require("ids.traps")
local zap = require("policy.magic.effects.zaps.ids").component

local test = {}

-- Use production components so the power's live availability and status
-- clearing cannot drift from the character and combat rules.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Ru power test",
    })
    ctx:add(player, component.HEALTH, {
        current = 5,
        max = 20,
    })
    ctx:add(player, component.MAGIC, {
        current = 0,
        max = 5,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = 75,
    })
    ctx:add(player, zap.PLAYER_CONFUSION, {
        remaining_aut = 30,
    })
    ctx:add(player, component.PLAYER_SLOW, {
        remaining_aut = 40,
    })
    ctx:add(player, component.PLAYER_PETRIFICATION, {
        petrifying_aut = 20,
        petrified_aut = 0,
    })

    local constrictor = ctx:create()
    local net = ctx:create()
    local net_id = ctx:id(net)

    ctx:add(player, component.CONSTRICTION, {
        by = constrictor,
        escape_attempts = 0,
    })
    ctx:add(player, component.TRAP_HELD, {
        kind_id = traps.TRAP_NET,
        net_item_id = net_id,
    })

    local game = setmetatable({}, { __index = ctx })
    local draws = {}

    -- Zero draws make source stochastic rounding and every die explicit.
    function game:random(_, bound)
        draws[#draws + 1] = bound

        return 0
    end

    local power = registry.get(ids.RU_DRAW_OUT_POWER)

    harness.truthy(power ~= nil)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = 74
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    harness.truthy(not registry.usable_now(ctx, player, power))
    worship.piety = 75
    ctx:set(player, component.RELIGION_WORSHIP, worship)

    harness.truthy(registry.usable_now(ctx, player, power))
    harness.truthy(power.confusion_ok)
    harness.equal(power.prepare(game, player), nil)
    power.resolve(game, player)

    local health = ctx:get(player, component.HEALTH)
    local magic = ctx:get(player, component.MAGIC)
    local exhaustion = ctx:get(player, component.PLAYER_EXHAUSTION)

    harness.equal(health.current, 14)
    harness.equal(magic.current, 4)
    harness.truthy(ctx:has(player, component.PLAYER_DRAIN))
    harness.truthy(not ctx:has(player, zap.PLAYER_CONFUSION))
    harness.truthy(not ctx:has(player, component.PLAYER_SLOW))
    harness.truthy(not ctx:has(player,
        component.PLAYER_PETRIFICATION))
    harness.truthy(not ctx:has(player, component.CONSTRICTION))
    harness.truthy(not ctx:has(player, component.TRAP_HELD))
    harness.truthy(ctx:entity(net_id) == nil)
    harness.equal(exhaustion.remaining_aut, 120)
    harness.equal(draws[1], 16)
    harness.equal(draws[2], 20)
    harness.equal(draws[7], 48)
    harness.equal(draws[8], 40)
    harness.truthy(not registry.usable_now(ctx, player, power))

    ctx:remove(player, component.PLAYER_EXHAUSTION)
    health.current = health.max
    magic.current = magic.max
    ctx:set(player, component.HEALTH, health)
    ctx:set(player, component.MAGIC, magic)

    harness.truthy(power.prepare(ctx, player) ~= nil)
end

return test
