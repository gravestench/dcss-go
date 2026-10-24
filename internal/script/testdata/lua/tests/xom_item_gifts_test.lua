-- Xom's two gifts must be ordinary positioned ECS items, with their
-- generation path distinguished by quality and source attribution.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local item_sets = require("policy.item_generation.item_sets")
local jobs = require("ids.jobs")
local purpose = require("constants.item_generation_purpose")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- The production item generator reads the real player catalog identity,
-- skills, and unique history. The fixture supplies only a sparse floor.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local selected_class = 0

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Xom gift tester",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        choices = {},
    })
    item_sets.initialise(ctx, player)

    function owner:random(stream, bound)
        if stream == streams.RELIGION and bound == 9 then
            return selected_class
        end

        return ctx:random(stream, bound)
    end

    function owner:level_depth()
        return 1
    end

    local random = events.apply(owner, player,
        ids.GOOD_RANDOM_ITEM, 10, {
            stream = streams.RELIGION,
        })
    local gifts = { random }

    -- Every source class must materialize, including miscellany and gold,
    -- which do not use the same subtype picker as equipment classes.
    for index = 0, 8 do
        selected_class = index
        gifts[#gifts + 1] = events.apply(owner, player,
            ids.GOOD_ACQUIREMENT, 10, {
                stream = streams.RELIGION,
            })
    end

    for _, item in ipairs(gifts) do
        harness.truthy(ctx:has(item, component.ITEM))
        harness.equal(ctx:get(item, component.POSITION).level_id, 1)
        harness.equal(ctx:get(item, component.ITEM_PROVENANCE).god_id,
            gods.XOM)
        harness.equal(ctx:get(item, component.ITEM_PROVENANCE).purpose,
            purpose.GOD_GIFT)
    end
end

return test
