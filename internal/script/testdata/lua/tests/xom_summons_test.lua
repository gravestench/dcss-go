-- Xom's allies and hostile demons must be ordinary saved summon entities,
-- with source allegiance and expiry read by AI and the summon clock.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local ids = require("ids.xom_events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")

local test = {}

-- A low roll chooses one lesser demon in each case. The common summon
-- owner still places and saves it, rather than a Xom-only actor shortcut.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 5,
    })

    -- Force the source's low-severity lesser-demon draw. Every fallback
    -- RNG call remains in the real shared runtime for summon placement.
    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return 0
        end

        return ctx:random(stream, bound)
    end

    -- The shared population owner asks for local branch depth when Xom
    -- chooses a shadow creature; this fixture has one Dungeon floor.
    function owner:level_depth()
        return 1
    end

    local ally = events.apply(owner, player,
        ids.GOOD_SINGLE_ALLY, 10, {
            stream = streams.RELIGION,
        })
    local friendly = ctx:get(ally, component.SUMMON)

    harness.equal(friendly.attitude, attitudes.FRIENDLY)
    harness.truthy(friendly.expires_aut > 0)

    local allies = events.apply(owner, player,
        ids.GOOD_ALLIES, 10, {
            stream = streams.RELIGION,
        })

    harness.equal(allies, 2)

    -- One-in-three chooses the shadow branch at zero, so the bad event
    -- can also be inspected without assuming a particular demon tier.
    local count = events.apply(owner, player,
        ids.BAD_SUMMON_HOSTILES, 10, {
            stream = streams.RELIGION,
        })

    harness.truthy(count > 0)

    local hostiles = 0

    for _, monster in ipairs(ctx:query({ component.SUMMON })) do
        local summon = ctx:get(monster, component.SUMMON)

        if summon.attitude == attitudes.HOSTILE then
            hostiles = hostiles + 1
        end
    end

    harness.equal(hostiles, count)
end

return test
