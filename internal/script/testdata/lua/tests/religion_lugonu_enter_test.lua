-- Enter the Abyss pays its source cost only after a successful power
-- draw, and saves the outside site through the real Abyss owner.
local abyss = require("policy.world.abyss")
local component = require("constants.component")
local enter = require("policy.abilities.lugonu.enter")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local species = require("ids.species")

local test = {}

-- A context with actual player, health, magic, and worship components
-- isolates the world-region transaction while checking the ability's
-- resource and source HP-deflation rules.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_ABYSSAL_KNIGHT,
        name = "Abyss entry tester",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })
    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 20,
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.LUGONU,
        piety = 200,
    })

    local game = setmetatable({}, { __index = ctx })
    local entered = false
    local original = abyss.enter

    function game:random(_, bound)
        return bound - 1
    end

    abyss.enter = function(_, traveler, site)
        harness.equal(traveler, player)
        harness.equal(site.level_id, 1)
        harness.equal(site.x, 10)
        harness.equal(site.y, 10)
        entered = true
    end

    local okay, reason = pcall(enter.resolve, game, player)

    abyss.enter = original

    if not okay then
        error(reason)
    end

    harness.truthy(entered)
    harness.equal(ctx:get(player, component.HEALTH).current, 1)
    harness.equal(ctx:get(player, component.MAGIC).current, 0)
    harness.truthy(ctx:get(player, component.RELIGION_WORSHIP).piety <
        200)
end

return test
