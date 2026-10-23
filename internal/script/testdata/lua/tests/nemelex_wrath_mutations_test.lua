-- Jiyva and Qazlal use source god-gift mutation rules with saved ECS ranks.
local component = require("constants.component")
local catalog = require("policy.catalog")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jiyva = require("policy.religion.wrath.jiyva")
local mutations = require("ids.mutations")
local piety = require("policy.religion.piety")
local qazlal = require("policy.religion.wrath.qazlal")
local records = require("policy.mutations.records")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local uses = require("constants.mutation_uses")

local test = {}

-- Give each wrath branch its own player and save-backed mutation records.
local function player(ctx, god_id, points)
    local owner = ctx:create()

    ctx:add(owner, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(owner, component.PROGRESSION, {
        level = 7,
    })
    ctx:add(owner, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = points or 0,
        penance = {},
    })

    return owner
end

-- Fix card gates and mutation draws independently while reporting every
-- requested bound. A missed draw changes this list even if ranks match.
local function with_draws(ctx, cards)
    local owner = setmetatable({}, { __index = ctx })
    local card_bounds = {}
    local mutation_bounds = {}

    -- Card values choose only wrath gates; zero mutation values select the
    -- first eligible source pool entry and minimum expiry dice.
    function owner:random(stream, bound)
        if stream == streams.CARDS then
            card_bounds[#card_bounds + 1] = bound

            local value = cards[#card_bounds]

            harness.truthy(value ~= nil and value >= 0 and value < bound,
                "invalid wrath card draw")

            return value
        end

        if stream == streams.MUTATION then
            mutation_bounds[#mutation_bounds + 1] = bound

            return 0
        end

        return ctx:random(stream, bound)
    end

    -- Expose the exact wrath gate order after the branch finishes.
    function owner:card_bounds()
        return card_bounds
    end

    -- Expose mutation owner draws separately from the wrath card gates.
    function owner:mutation_bounds()
        return mutation_bounds
    end

    return owner
end

-- Source count roll precedes each bad candidate. A third-level rMut does
-- not intercept Jiyva's god gift, and the final zero coinflip skips revoke.
local function jiyva_bad_gift(ctx)
    local target = player(ctx, gods.NO_GOD)

    records.grant_acquired(ctx, target,
        mutations.MUT_MUTATION_RESISTANCE, 3)

    local draws = with_draws(ctx, { 0, 0, 0 })

    harness.truthy(jiyva.apply(draws, target))
    harness.equal(#draws:card_bounds(), 3)
    harness.equal(draws:card_bounds()[1], 7)
    harness.equal(draws:card_bounds()[2], 3)
    harness.equal(draws:card_bounds()[3], 2)
    harness.truthy(#draws:mutation_bounds() > 0,
        "Jiyva samples a bad mutation despite ordinary rMut")

    local acquired = 0

    for _, entry in ipairs(records.list(ctx, target)) do
        if entry.state.mutation_id ~= mutations.MUT_MUTATION_RESISTANCE then
            acquired = acquired + entry.state.acquired
        end
    end

    harness.truthy(acquired > 0,
        "Jiyva's bad gift survives in acquired mutation records")
end

-- Source second zero coinflip chooses vulnerability. The Qazlal pool may
-- grant two temporary levels, with one shared saved XP expiry timer.
local function qazlal_temporary_gift(ctx)
    local target = player(ctx, gods.NO_GOD)
    local draws = with_draws(ctx, { 0, 0 })

    harness.truthy(qazlal.apply(draws, target))
    harness.equal(#draws:card_bounds(), 2)
    harness.equal(draws:card_bounds()[1], 2)
    harness.equal(draws:card_bounds()[2], 2)
    harness.equal(records.temporary_count(ctx, target), 2,
        "Qazlal grants two ranks of the selected vulnerability")
    harness.equal(records.timer(ctx, target).remaining_xp, 207,
        "two ranks share the source XL7 minimum expiry roll")
end

-- Source Qazlal samples one use-pool ID and can fail when it is capped.
-- It must not retry into another vulnerability after the blocked draw.
local function qazlal_capped_candidate(ctx)
    local target = player(ctx, gods.NO_GOD)
    local first

    for _, definition in ipairs(catalog.all("mutations")) do
        for _, use in ipairs(definition.uses) do
            if definition.status == "active" and use == uses.QAZLAL then
                first = definition
                break
            end
        end

        if first then
            break
        end
    end

    harness.truthy(first, "Qazlal needs a mutation candidate")
    records.grant_acquired(ctx, target, first.id, first.max_level)

    local draws = with_draws(ctx, { 0, 0 })

    harness.truthy(qazlal.apply(draws, target))
    harness.equal(records.temporary_count(ctx, target), 0)
    harness.equal(#draws:mutation_bounds(), 1,
        "capped Qazlal candidate consumes one weighted draw")
end

-- Zin's fifth-breakpoint protection succeeds without a mutation-stream
-- roll, even during penance; Qazlal must still announce failed stripping.
local function zin_protects(ctx)
    local target = player(ctx, gods.ZIN, piety.breakpoint(5))
    local worship = ctx:get(target, component.RELIGION_WORSHIP)

    worship.penance[gods.ZIN] = 5
    ctx:set(target, component.RELIGION_WORSHIP, worship)

    local draws = with_draws(ctx, { 0, 0 })

    harness.truthy(qazlal.apply(draws, target))
    harness.equal(records.temporary_count(ctx, target), 0)
    harness.equal(#draws:mutation_bounds(), 0)
end

-- Keep independent outcomes in one test so no earlier saved rank can
-- satisfy a later branch assertion.
function test.run(ctx)
    jiyva_bad_gift(ctx)
    qazlal_temporary_gift(ctx)
    qazlal_capped_candidate(ctx)
    zin_protects(ctx)
end

return test
