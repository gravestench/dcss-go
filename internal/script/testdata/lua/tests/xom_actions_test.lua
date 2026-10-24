-- The ordinary Xom turn and card wrath must share one action owner. These
-- checks pin post-action interest and mood writes around a live effect.
local actions = require("policy.religion.xom.actions")
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local gods = require("constants.gods")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local streams = require("constants.rng_streams")

local test = {}

-- A bored bad act rounds source badness 13/10 to two, samples its new
-- interest, and leaves piety alone when the one-in-five reroll fails.
local function bored_bad_act(ctx)
    local player = ctx:create()
    local draws = {
        { bound = 3, value = 0 },
        { bound = 40, value = 39 },
        { bound = 10, value = 0 },
        { bound = 120, value = 0 },
        { bound = 121, value = 100 },
        { bound = 5, value = 1 },
    }
    local index = 0
    local proxy = setmetatable({}, { __index = ctx })

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.XOM,
        piety = 40,
        gift_timeout = 0,
    })

    -- Production components and effects stay in the base runtime; only
    -- the source RELIGION stream's exact draws are pinned for this rule.
    function proxy:random(stream, bound)
        index = index + 1

        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, draws[index].bound)

        return draws[index].value
    end

    local result = actions.take(proxy, player,
        ids.BAD_CONFUSION, 40, streams.RELIGION)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    harness.truthy(result)
    harness.equal(worship.gift_timeout, 50)
    harness.equal(worship.piety, 40)
    harness.equal(index, #draws)
end

-- Simulate a lethal side effect at the action boundary. The source health
-- owner may leave HP at zero for Xom to rescue, but boredom and penance
-- deliberately remove that protection.
local function accidental_death(ctx, gift_timeout, penance, saved)
    local player = ctx:create()
    local proxy = setmetatable({}, { __index = ctx })
    local original_apply = events.apply

    ctx:add(player, component.HEALTH, {
        current = 7,
        max = 10,
    })
    ctx:add(player, component.PLAYER_FORM, {
        form_id = "tree",
        remaining_aut = 100,
        power = 10,
        appendage_mask = 0,
        uncancellable = false,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.XOM,
        piety = 40,
        gift_timeout = gift_timeout,
        penance = {
            [gods.XOM] = penance,
        },
    })

    function proxy:random(_, bound)
        return bound - 1
    end

    function events.apply(owner, victim)
        local health = owner:get(victim, component.HEALTH)
        local form = owner:get(victim, component.PLAYER_FORM)

        health.current = 0
        owner:set(victim, component.HEALTH, health)
        form.form_id = "bat"
        owner:set(victim, component.PLAYER_FORM, form)
    end

    actions.take(proxy, player, ids.BAD_CONFUSION, 10,
        streams.RELIGION)
    events.apply = original_apply

    local health = ctx:get(player, component.HEALTH)
    local form = ctx:get(player, component.PLAYER_FORM)

    harness.equal(health.current, saved and 7 or 0)
    harness.equal(form.form_id, saved and "tree" or "bat")
end

-- The test targets the shared source action entry point, without
-- reconstructing a second copy of its badness or worship schema.
function test.run(ctx)
    bored_bad_act(ctx)
    accidental_death(ctx, 10, 0, true)
    accidental_death(ctx, 0, 0, false)
    accidental_death(ctx, 10, 1, false)
end

return test
