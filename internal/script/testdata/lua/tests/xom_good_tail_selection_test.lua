-- Xom's late helpful gates preserve source priority and RNG order. They
-- share the ordinary effect owners rather than deciding from catalog order.
local events = require("ids.xom_events")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local good = require("policy.religion.xom.selection_good")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

local before_tail = {
    3, 100, 100, 100, 100, 5, 5, 100,
    8, 100, 10, 8, 100, 100, 100,
}

-- Each earlier gate fails, including destruction. The animation danger
-- draw deliberately passes so its severity chance is still accounted for.
local function choose(owner, player, suffix, overrides)
    local bounds = {}

    for _, bound in ipairs(before_tail) do
        bounds[#bounds + 1] = bound
    end

    for _, bound in ipairs(suffix) do
        bounds[#bounds + 1] = bound
    end

    local used = 0

    -- Reject any hidden extra draw at the exact event that consumed it.
    function owner:random(stream, bound)
        used = used + 1
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, bounds[used])

        if overrides[used] ~= nil then
            return overrides[used]
        end

        return bound - 1
    end

    local selected = good.choose(owner, player, 100, 2,
        streams.RELIGION)

    harness.equal(used, #bounds)

    return selected
end

-- Cleaving precedes Fog; a fogless player can receive fog after Cleaving
-- fails. The item gate then distinguishes an ordinary and acquired gift.
function test.run(ctx)
    local owner = fixture.observed_context(ctx)
    local player = owner:player()

    harness.equal(choose(owner, player, { 5, 100 }, {
        [12] = 0,
        [16] = 0,
        [17] = 0,
    }), events.GOOD_CLEAVING)

    harness.equal(choose(owner, player, { 5, 100 }, {
        [12] = 0,
        [16] = 4,
        [17] = 0,
    }), events.GOOD_FOG)

    local item_bounds = { 5, 100, 100, 2, 100, 201 }
    local item_draws = {
        [12] = 0,
        [16] = 0,
        [17] = 99,
        [19] = 0,
        [20] = 0,
        [21] = 200,
    }

    harness.equal(choose(owner, player, item_bounds,
        item_draws), events.GOOD_RANDOM_ITEM)

    item_draws[21] = 0

    harness.equal(choose(owner, player, item_bounds,
        item_draws), events.GOOD_ACQUIREMENT)

    -- The later gates need a real character profile and local monster
    -- threat. Earlier tests stop before these shared policies are read.
    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.HEALTH, {
        current = 30,
        max = 30,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })

    -- A fully seen one-cell floor makes the source exploration probe
    -- deterministic; its rare 100-in-120 veto can then be checked.
    function owner:level_size()
        return 1, 1
    end

    -- Every sampled cell is known, so no terrain query is needed.
    function owner:seen()
        return true
    end

    local late_bounds = {
        3, 100, 100, 100, 100, 100, 5,
        100, 5, 8, 100, 10, 100, 8,
        100, 100, 100, 5, 100, 100,
        20, 100,
    }

    -- Teleport's unusual exploration veto follows its own successful
    -- severity chance. Mutations and lightning must not draw afterward.
    local teleport_bounds = {}

    for _, bound in ipairs(late_bounds) do
        teleport_bounds[#teleport_bounds + 1] = bound
    end

    teleport_bounds[#teleport_bounds + 1] = 120

    local used = 0

    -- Draw 22 passes teleport; draw 23 fails the explored-floor veto.
    function owner:random(stream, bound)
        used = used + 1
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, teleport_bounds[used],
            "teleport draw " .. used)

        return used == 22 and 0 or bound - 1
    end

    harness.equal(good.choose(owner, player, 100, 20,
        streams.RELIGION), events.GOOD_TELEPORT)
    harness.equal(used, #teleport_bounds)

    local mutation_bounds = {}

    for _, bound in ipairs(late_bounds) do
        mutation_bounds[#mutation_bounds + 1] = bound
    end

    mutation_bounds[#mutation_bounds + 1] = 20
    mutation_bounds[#mutation_bounds + 1] = 100
    used = 0

    -- After teleport fails, low tension and the source 19/severity roll
    -- offer a good mutation to this living, initially unmutated Human.
    function owner:random(stream, bound)
        used = used + 1
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, mutation_bounds[used],
            "mutation draw " .. used)

        return (used == 23 or used == 24) and 0 or bound - 1
    end

    harness.equal(good.choose(owner, player, 100, 20,
        streams.RELIGION), events.GOOD_MUTATION)
    harness.equal(used, #mutation_bounds)

    local enemy = fixture.actor(ctx, monsters.MONS_OGRE,
        8, 7, 100)
    local lightning_bounds = {}

    for _, bound in ipairs(mutation_bounds) do
        lightning_bounds[#lightning_bounds + 1] = bound
    end

    used = 0

    -- Let mutation fail and lightning pass. The nearby ogre supplies
    -- genuine local danger and a reachable explosion cell.
    function owner:random(stream, bound)
        used = used + 1
        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, lightning_bounds[used],
            "lightning draw " .. used)

        return used == 24 and 0 or bound - 1
    end

    harness.equal(good.choose(owner, player, 100, 20,
        streams.RELIGION), events.GOOD_LIGHTNING)
    harness.equal(used, #lightning_bounds)
    ctx:destroy(enemy)
end

return test
