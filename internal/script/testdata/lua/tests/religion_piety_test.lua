-- Piety is saved on the player; source breakpoint and random draw order
-- determine what later god systems may unlock after each conduct event.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local slots = require("constants.jewellery_slots")
local species = require("ids.species")
local limits = require("constants.piety")
local piety = require("policy.religion.piety")
local signals = require("constants.religion_signals")
local streams = require("constants.rng_streams")

local test = {}

-- Give one rule call a bounded sequence of RNG results and collect signals
-- without copying any production component schema or event implementation.
local function scripted(ctx, draws)
    local proxy = setmetatable({}, { __index = ctx })
    local used = 0
    local emitted = {}

    function proxy:random(stream, bound)
        used = used + 1
        local next_draw = draws[used]

        harness.equal(stream, streams.RELIGION)
        harness.truthy(next_draw, "unexpected piety draw")
        harness.equal(bound, next_draw.bound)

        return next_draw.value
    end

    function proxy:signal(name, value)
        emitted[#emitted + 1] = {
            name = name,
            value = value,
        }
    end

    function proxy:used()
        return used
    end

    function proxy:emitted()
        return emitted
    end

    return proxy
end

-- A fresh owner uses the production worship schema; each test replaces the
-- detached record so previous cases cannot silently carry over counters.
local function owner(ctx, god_id, points)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = points or 0,
    })

    return player
end

-- Source six-star thresholds are inclusive, while Xom divides its mood
-- around different boundaries and Gozag has no ordinary piety rank.
local function ranks()
    for stars, threshold in ipairs(limits.BREAKPOINTS) do
        harness.equal(piety.breakpoint(stars), threshold)
        harness.equal(piety.rank(gods.TROG, threshold), stars)
        harness.equal(piety.rank(gods.TROG, threshold - 1), stars - 1)
    end

    harness.equal(piety.rank(gods.XOM, 20), 1)
    harness.equal(piety.rank(gods.XOM, 21), 2)
    harness.equal(piety.rank(gods.XOM, 50), 2)
    harness.equal(piety.rank(gods.XOM, 51), 3)
    -- Xom has six mood breakpoints; the highest band starts above 180.
    harness.equal(piety.rank(gods.XOM, 180), 6)
    harness.equal(piety.rank(gods.XOM, 181), 7)
    harness.equal(piety.rank(gods.GOZAG, 200), 0)
    harness.equal(piety.rank(gods.NO_GOD, 0), 0)
end

-- Loss first fills a one-point hysteresis buffer; the next point crosses
-- the rank boundary. Gain then repays that buffer before raising piety.
local function hysteresis(ctx)
    local player = owner(ctx, gods.TROG, 30)
    local sequence = scripted(ctx, {})

    piety.lose(sequence, player, 1)

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 30)
    harness.equal(state.piety_hysteresis, 1)
    harness.equal(#sequence:emitted(), 0)

    piety.lose(sequence, player, 1)

    state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 29)
    harness.equal(sequence:emitted()[1].name, signals.RANK_CHANGED)
    harness.equal(sequence:emitted()[1].value.old_rank, 1)
    harness.equal(sequence:emitted()[1].value.new_rank, 0)

    piety.gain(sequence, player, 1, 1, false)

    state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 29)
    harness.equal(state.piety_hysteresis, 0)
    harness.equal(sequence:emitted()[2].name, signals.GIFT_CHECK)
end

-- Penance and timeout consume candidate points in source order. A timeout
-- slowdown roll occurs only for gods whose gifts normally slow devotion.
local function debt_and_timeout(ctx)
    local player = owner(ctx, gods.TROG, 50)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    state.penance[gods.TROG] = 2
    state.gift_timeout = 1
    ctx:set(player, component.RELIGION_WORSHIP, state)

    local sequence = scripted(ctx, {
        { bound = 4, value = 3 },
    })

    piety.gain(sequence, player, 3, 1, false)

    state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.penance[gods.TROG], 0)
    harness.equal(state.gift_timeout, 0)
    harness.equal(state.piety, 50)
    harness.equal(sequence:used(), 1)
    harness.equal(#sequence:emitted(), 0)

    local elyvilon = owner(ctx, gods.ELYVILON, 50)
    local ely_state = ctx:get(elyvilon, component.RELIGION_WORSHIP)

    ely_state.gift_timeout = 1
    ctx:set(elyvilon, component.RELIGION_WORSHIP, ely_state)

    local exempt = scripted(ctx, {})

    piety.gain(exempt, elyvilon, 1, 1, false)

    harness.equal(ctx:get(elyvilon, component.RELIGION_WORSHIP).piety, 51)
    harness.equal(exempt:used(), 0)
end

-- Above five stars the first taper roll may consume the gain. Ru instead
-- stops exactly at six stars, and a capped ordinary god asks for a gift.
local function caps_and_taper(ctx)
    local ru = owner(ctx, gods.RU, limits.RU_MAX)
    local quiet = scripted(ctx, {})

    piety.gain(quiet, ru, 5, 1, false)

    harness.equal(ctx:get(ru, component.RELIGION_WORSHIP).piety,
        limits.RU_MAX)
    harness.equal(#quiet:emitted(), 0)

    local trog = owner(ctx, gods.TROG, limits.MAX)

    piety.gain(quiet, trog, 1, 1, false)

    harness.equal(ctx:get(trog, component.RELIGION_WORSHIP).piety,
        limits.MAX)
    harness.equal(quiet:emitted()[1].name, signals.GIFT_CHECK)

    local high = owner(ctx, gods.TROG, limits.RU_MAX)
    local tapered = scripted(ctx, {
        { bound = 3, value = 0 },
    })

    piety.gain(tapered, high, 1, 1, false)

    harness.equal(ctx:get(high, component.RELIGION_WORSHIP).piety,
        limits.RU_MAX)
    harness.equal(tapered:used(), 1)
    harness.equal(tapered:emitted()[1].name, signals.GIFT_CHECK)
end

-- Only a fractional numerator spends a rounding draw. Godless, Xom, and
-- Gozag gains do not consume RNG or change the saved worship record.
local function rounding_and_exclusions(ctx)
    local trog = owner(ctx, gods.TROG, 28)
    local rounded = scripted(ctx, {
        { bound = 2, value = 0 },
    })

    piety.gain(rounded, trog, 3, 2, false)

    harness.equal(ctx:get(trog, component.RELIGION_WORSHIP).piety, 30)
    harness.equal(rounded:used(), 1)
    harness.equal(rounded:emitted()[1].name, signals.GIFT_CHECK)
    harness.equal(rounded:emitted()[2].name, signals.RANK_CHANGED)
    harness.equal(ctx:get(trog, component.RELIGION_WORSHIP)
        .piety_max[gods.TROG], 30)

    for _, id in ipairs({ gods.NO_GOD, gods.XOM, gods.GOZAG }) do
        local skipped = owner(ctx, id, 0)
        local no_draw = scripted(ctx, {})

        harness.falsy(piety.gain(no_draw, skipped, 3, 2, false))
        harness.equal(no_draw:used(), 0)
        harness.equal(#no_draw:emitted(), 0)
    end
end

-- Faith uses the equipped amulet's live capability before the final
-- division. Its fractional quarter consumes the first religion draw.
local function faith_scale(ctx)
    local player = owner(ctx, gods.TROG, 0)
    local amulet = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Faith test",
    })
    ctx:add(amulet, component.ITEM, {
        kind_id = items.AMU_FAITH,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(amulet, component.CARRIED_BY, {
        holder = player,
    })
    ctx:add(amulet, component.EQUIPPED, {
        slot = slots.AMULET,
    })

    local scaled = scripted(ctx, {
        { bound = limits.FAITH_DIVISOR, value = 0 },
    })

    function scaled:player()
        return player
    end

    piety.gain(scaled, player, 3, 1, true)

    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).piety, 4)
    harness.equal(scaled:used(), 1)
end

-- Ignis's reserve follows real losses rather than its ordinary maximum;
-- this stored floor is what the later rejoin path must consult.
local function ignis_reserve(ctx)
    local player = owner(ctx, gods.IGNIS, 130)
    local quiet = scripted(ctx, {})

    piety.lose(quiet, player, 20)

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 111)
    harness.equal(state.min_ignis_piety, 111)
end

-- Keep each case independent while exercising the full source sequence.
function test.run(ctx)
    ranks()
    hysteresis(ctx)
    debt_and_timeout(ctx)
    caps_and_taper(ctx)
    rounding_and_exclusions(ctx)
    faith_scale(ctx)
    ignis_reserve(ctx)
end

return test
