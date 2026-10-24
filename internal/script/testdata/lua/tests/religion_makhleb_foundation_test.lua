-- Makhleb's player abilities and wrath use one roster, while the shared
-- cost owner prevents a divine power from paying its last hit point.
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local roster = require("policy.religion.makhleb.roster")

local test = {}

-- Paying the last hit point would bypass source ability affordability;
-- a rejected action must leave the real ECS health component intact.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = 4,
        max = 10,
    })

    harness.falsy(costs.enough_health(ctx, player, 4))
    harness.truthy(costs.enough_health(ctx, player, 3))
    costs.spend_health(ctx, player, 3)
    harness.equal(ctx:get(player, component.HEALTH).current, 1)
    harness.falsy(costs.enough_health(ctx, player, 1))

    harness.equal(#roster.lesser, 5)
    harness.equal(#roster.greater, 5)
    harness.equal(roster.lesser[1], monsters.MONS_HELLWING)
    harness.equal(roster.greater[1], monsters.MONS_EXECUTIONER)
    harness.truthy(roster.contains(monsters.MONS_YNOXINUL, "lesser"))
    harness.truthy(roster.contains(monsters.MONS_CACODEMON, "greater"))
    harness.falsy(roster.contains(monsters.MONS_OGRE, "greater"))

    local random = setmetatable({}, { __index = ctx })

    -- Generic costs remain source ranges rather than fixed integers.
    function random:random(_, bound)
        return 0
    end

    harness.equal(costs.piety_cost(random, 2), 2)
    harness.equal(costs.piety_cost(random, 5), 5)

    function random:random(_, bound)
        return bound - 1
    end

    harness.equal(costs.piety_cost(random, 2), 3)
    harness.equal(costs.piety_cost(random, 5), 8)
end

return test
