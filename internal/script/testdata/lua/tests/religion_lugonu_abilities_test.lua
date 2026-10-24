-- Lugonu's power menu reflects rank, location, patron, and the saved
-- once-only capstone. The tests use the production ability registry.
local abilities = require("ids.abilities")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local species = require("ids.species")

local test = {}

-- A real worship component is changed in place so every rank check
-- exercises the same state the game saves between dungeon actions.
function test.run(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })

    function game:player()
        return player
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_ABYSSAL_KNIGHT,
        name = "Lugonu ability tester",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })
    ctx:add(player, component.MAGIC, {
        current = 20,
        max = 20,
    })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.LUGONU,
        piety = piety.breakpoint(2),
    })

    local powers = {
        abilities.LUGONU_ABYSS_EXIT,
        abilities.LUGONU_BEND_SPACE,
        abilities.LUGONU_BANISH,
        abilities.LUGONU_CORRUPT,
        abilities.LUGONU_ABYSS_ENTER,
        abilities.LUGONU_BLESS_WEAPON,
    }

    harness.equal(#powers, 6)

    for _, id in ipairs(powers) do
        harness.truthy(registry.get(id))
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    harness.truthy(registry.usable_now(game, player,
        registry.get(abilities.LUGONU_BEND_SPACE)))
    harness.falsy(registry.usable_now(game, player,
        registry.get(abilities.LUGONU_BANISH)))

    ctx:add(player, component.PLAYER_STATUS, {
        silence_aut = 100,
    })
    harness.falsy(registry.usable_now(game, player,
        registry.get(abilities.LUGONU_BEND_SPACE)))
    ctx:remove(player, component.PLAYER_STATUS)

    worship.piety = piety.breakpoint(6)
    worship.penance[gods.LUGONU] = 1
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    harness.falsy(registry.usable_now(game, player,
        registry.get(abilities.LUGONU_CORRUPT)))

    worship.penance[gods.LUGONU] = 0
    worship.one_time_abilities[gods.LUGONU] = true
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    harness.falsy(registry.usable_now(game, player,
        registry.get(abilities.LUGONU_BLESS_WEAPON)))
end

return test
