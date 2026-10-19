
local abilities = require("ids.abilities")
local component = require("constants.component")
local harness = require("tests.harness")
local mutations = require("ids.mutations")
local monsters = require("ids.monsters")
local registry = require("policy.abilities.registry")
local commands = require("policy.commands.abilities")
local cooldowns = require("policy.abilities.cooldowns")
local records = require("policy.mutations.records")

local test = {}

-- Check the prepared ability list by ID independent of menu order.
local function listed(options, id)
    for _, option in ipairs(options) do
        if option.id == id then
            return true
        end
    end

    return false
end

-- Old spit action rejects after the upgrade.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 2,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
        total_xp = 0,
    })

    local world = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to poison breath fixture actor so player-only branches execute on that entity.
    function world.player()
        return player
    end

    -- Make poison breath sight deterministic while leaving actor positions to the ECS fixture.
    function world.visible()
        return true
    end

    -- Define poison breath fixture's traversable cells for movement and targeting checks.
    function world.walkable()
        return true
    end

    -- Return no occupant while preparing a clear poison-breath line.
    function world.actor_at()
        return nil
    end

    -- Avoid incidental random ability choices while checking the upgraded breath menu.
    function world.random(_, _, bound)
        return bound - 1
    end

    records.grant_innate(world, player, mutations.MUT_SPIT_POISON, 1)

    local options = registry.available(world, player)

    -- The first level exposes the spit command and its shared cooldown.
    harness.truthy(listed(options, abilities.SPIT_POISON),
        "first mutation level offers Spit Poison")
    harness.falsy(listed(options, abilities.BREATHE_POISON),
        "first mutation level does not offer poison breath")

    local spit = commands.prepare(world, player, {
        ability_id = abilities.SPIT_POISON,
        dx = 1,
        dy = 0,
    })

    harness.equal(spit.cost, 10,
        "valid poison spit takes one action")
    registry.resolve(world, player, spit.intent, 10)

    local breath = world:get(player, component.BREATH_COOLDOWN)

    harness.truthy(breath and breath.remaining_aut > 0,
        "Spit Poison starts the shared breath cooldown")
    harness.truthy(commands.prepare(world, player, {
        ability_id = abilities.SPIT_POISON,
        dx = 1,
        dy = 0,
    }).message, "poison spit rejects during the cooldown")

    cooldowns.tick(world, player, breath.remaining_aut)
    harness.equal(world:get(player,
        component.BREATH_COOLDOWN).remaining_aut, 0,
        "breath cooldown expires with elapsed action time")

    records.grant_innate(world, player, mutations.MUT_SPIT_POISON, 1)
    options = registry.available(world, player)

    -- Upgrading the mutation swaps ability IDs without resetting the breath timer.
    harness.falsy(listed(options, abilities.SPIT_POISON),
        "second mutation level replaces Spit Poison")
    harness.truthy(listed(options, abilities.BREATHE_POISON),
        "second mutation level offers Breathe Poison Gas")
    -- A stale command cannot bypass the new level-two ability selection.
    harness.truthy(commands.prepare(world, player, {
        ability_id = abilities.SPIT_POISON,
        dx = 1,
        dy = 0,
    }).message, "old spit action rejects after the upgrade")

    local gas = commands.prepare(world, player, {
        ability_id = abilities.BREATHE_POISON,
        dx = 1,
        dy = 0,
    })

    harness.equal(gas.cost, 10,
        "poison gas breath uses the same ability command")
    registry.resolve(world, player, gas.intent, 10)
    harness.truthy(world:get(player,
        component.BREATH_COOLDOWN).remaining_aut > 0,
        "poison gas breath starts the source cooldown")

    local rat = ctx:create()

    ctx:add(rat, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(rat, component.HEALTH, {
        current = 40,
        max = 40,
    })
    ctx:add(rat, component.POSITION, {
        level_id = 1,
        x = 3,
        y = 2,
    })

    local battle = setmetatable({}, { __index = world })

    -- Return the rat at the aimed cell so breath can resolve against it.
    function battle.actor_at(_, _, x, y)
        if x == 3 and y == 2 then
            return rat
        end

        return nil
    end

    -- Force the spell proc but use high remaining draws to isolate breath damage.
    function battle.random(_, stream, bound)
        if stream == "spell" and bound == 10 then
            return 0
        end

        return bound - 1
    end

    local ready = world:get(player, component.BREATH_COOLDOWN)
    ready.remaining_aut = 0
    world:set(player, component.BREATH_COOLDOWN, ready)

    local targeted = commands.prepare(battle, player, {
        ability_id = abilities.BREATHE_POISON,
        dx = 1,
        dy = 0,
    })

    registry.resolve(battle, player, targeted.intent, 10)
    harness.truthy(world:get(rat, component.HEALTH).current < 40,
        "poison gas breath hurts the first creature on its beam")
    harness.truthy(world:has(rat, component.PROJECTILE_POISON),
        "poison gas breath applies the poison status")
end

return test
