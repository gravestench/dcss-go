-- Kiku's death curse uses the source weights and writes through saved player
-- damage, Slow, stat loss, drain, and Torment owners.
local component = require("constants.component")
local curse = require("policy.religion.wrath.death_curse")
local fixture = require("tests.monster_ally_support_fixture")
local forms = require("constants.form_ids")
local gods = require("constants.gods")
local harness = require("tests.harness")
local kikubaaqudgha = require("policy.religion.wrath.kikubaaqudgha")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Fix card draws while retaining real ECS and side effects; failed bounds
-- expose a changed source roll sequence at its first divergent draw.
local function with_draws(ctx, draws)
    local owner = setmetatable({}, { __index = ctx })
    local used = 0
    local messages = {}

    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return ctx:random(stream, bound)
        end

        used = used + 1
        local value = draws[used]

        harness.truthy(value ~= nil, "missing Kiku curse draw")
        harness.truthy(value >= 0 and value < bound,
            "invalid Kiku curse draw")

        return value
    end

    -- Expose the exact count because repeated curses must each redraw.
    function owner:draws_used()
        return used
    end

    -- Keep source speech observable while forwarding normal game events.
    function owner:emit(channel, message)
        messages[#messages + 1] = message
        ctx:emit(channel, message)
    end

    -- Return messages in source order for the polarity assertion.
    function owner:message(index)
        return messages[index]
    end

    return owner
end

-- Use the production player components needed by every curse effect.
local function player_at(ctx, level, x)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.ACTOR, {
        kind_id = monsters.MONS_HUMAN,
        speed = 10,
    })
    ctx:add(player, component.PROGRESSION, { level = level })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = x,
        y = 20,
    })
    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 15,
        intelligence = 15,
        dexterity = 15,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NO_GOD,
    })

    return player
end

-- At severity zero the first eighty weight units produce only a message.
local function trivial_message(ctx)
    local player = player_at(ctx, 1, 10)
    local owner = with_draws(fixture.context(ctx, player), { 0, 0 })

    harness.equal(curse.apply(owner, player, 0), "message")
    harness.equal(ctx:get(player, component.HEALTH).current, 100)
    harness.equal(owner:draws_used(), 2)
end

-- Species-specific message entries preserve source order and grammar:
-- Mummies skip smell, Tengu have feathers, and Formicids have no bones.
local function species_messages(ctx)
    local mummy = player_at(ctx, 1, 31)
    local mummy_identity = ctx:get(mummy, component.PLAYER)

    mummy_identity.species_id = species.SP_MUMMY
    ctx:set(mummy, component.PLAYER, mummy_identity)

    local mummy_owner = with_draws(fixture.context(ctx, mummy), {
        0, 8,
    })

    harness.equal(curse.apply(mummy_owner, mummy, 0), "message")
    harness.equal(mummy_owner:message(1), "Your bandages flutter.")

    local tengu = player_at(ctx, 1, 32)
    local tengu_identity = ctx:get(tengu, component.PLAYER)

    tengu_identity.species_id = species.SP_TENGU
    ctx:set(tengu, component.PLAYER, tengu_identity)

    local tengu_owner = with_draws(fixture.context(ctx, tengu), {
        0, 9,
    })

    harness.equal(curse.apply(tengu_owner, tengu, 0), "message")
    harness.equal(tengu_owner:message(1),
        "Your feathers prickle.")

    local formicid = player_at(ctx, 1, 33)
    local formicid_identity = ctx:get(formicid, component.PLAYER)

    formicid_identity.species_id = species.SP_FORMICID
    ctx:set(formicid, component.PLAYER, formicid_identity)

    local formicid_owner = with_draws(fixture.context(ctx, formicid), {
        0, 10,
    })

    harness.equal(curse.apply(formicid_owner, formicid, 0), "message")
    harness.equal(formicid_owner:message(1),
        "You hear strange and distant voices.")
end

-- The severity-15 pain slot rolls two samples before unresisted damage.
local function pain(ctx)
    local player = player_at(ctx, 15, 11)
    local owner = with_draws(fixture.context(ctx, player), {
        0, 0, 0,
    })

    harness.equal(curse.apply(owner, player, 15), "pain")
    harness.equal(ctx:get(player, component.HEALTH).current, 95)
    harness.equal(owner:draws_used(), 3)
end

-- The Slow slot passes severity as turns to the saved player owner.
local function lethargy(ctx)
    local player = player_at(ctx, 15, 12)
    local owner = with_draws(fixture.context(ctx, player), { 40 })

    harness.equal(curse.apply(owner, player, 15), "slow")
    harness.truthy(ctx:get(player, component.PLAYER_SLOW).remaining_aut > 0)
    harness.equal(owner:draws_used(), 1)
end

-- Drain's XL/27 gate can choose a stat loss instead of maximum-HP drain.
local function draining(ctx)
    local player = player_at(ctx, 15, 13)
    local owner = with_draws(fixture.context(ctx, player), {
        80, 26, 0, 0, 0,
    })

    harness.equal(curse.apply(owner, player, 15), "drain")
    harness.truthy(ctx:get(player, component.HEALTH).max < 100)
    harness.equal(owner:draws_used(), 3)
end

-- The drain slot's chance gate may lose one random attribute instead of HP.
local function stat_draining(ctx)
    local player = player_at(ctx, 15, 21)
    local owner = with_draws(fixture.context(ctx, player), {
        80, 0, 1, 0, 0,
    })

    harness.equal(curse.apply(owner, player, 15), "drain")
    harness.equal(ctx:get(player, component.STAT_LOSS).intelligence, 1)
    harness.equal(ctx:get(player, component.HEALTH).max, 100)
    harness.equal(owner:draws_used(), 5)
end

-- Full negative-energy resistance blocks the ordinary drain path after
-- the stat-loss gate has failed.
local function resisted_drain(ctx)
    local player = player_at(ctx, 15, 26)
    local owner = with_draws(fixture.context(ctx, player), {
        80, 26,
    })

    ctx:add(player, component.PLAYER_FORM, {
        form_id = forms.LICH,
        remaining_aut = 100,
    })

    harness.equal(curse.apply(owner, player, 15), "drain")
    harness.equal(ctx:get(player, component.HEALTH).max, 100)
    harness.equal(owner:draws_used(), 2)
end

-- A Torment curse reaches only the target cell, leaving nearby actors alone.
local function torment(ctx)
    local player = player_at(ctx, 15, 14)
    local neighbor = player_at(ctx, 15, 22)
    local owner = with_draws(fixture.context(ctx, player), { 120 })

    harness.equal(curse.apply(owner, player, 15), "torment")
    harness.equal(ctx:get(player, component.HEALTH).current, 51)
    harness.equal(ctx:get(neighbor, component.HEALTH).current, 100)
    harness.equal(owner:draws_used(), 1)
end

-- Lich Form resists pain after selecting that slot and draws no damage dice.
local function immune_pain(ctx)
    local player = player_at(ctx, 15, 23)
    local owner = with_draws(fixture.context(ctx, player), { 0 })

    ctx:add(player, component.PLAYER_FORM, {
        form_id = forms.LICH,
        remaining_aut = 100,
    })

    harness.equal(curse.apply(owner, player, 15), "pain")
    harness.equal(ctx:get(player, component.HEALTH).current, 100)
    harness.equal(owner:draws_used(), 1)
end

-- Active two-star protection can wholly cancel a curse or halve its
-- severity before the weighted effect draw.
local function protected_curse(ctx)
    local player = player_at(ctx, 15, 24)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.god_id = gods.KIKUBAAQUDGHA
    worship.piety = 50
    ctx:set(player, component.RELIGION_WORSHIP, worship)

    local averted = with_draws(fixture.context(ctx, player), { 0 })

    harness.equal(curse.apply(averted, player, 15), "averted")
    harness.equal(averted:draws_used(), 1)

    local partial = with_draws(fixture.context(ctx, player), {
        1, 0, 0,
    })

    harness.equal(curse.apply(partial, player, 15), "message")
    harness.equal(partial:draws_used(), 3)
end

-- At XL 27 the source's negative message weight makes Slow the first
-- selectable slot, and resistance substitutes exactly three curses.
local function resistant_wrath(ctx)
    local player = player_at(ctx, 27, 15)
    local owner = with_draws(fixture.context(ctx, player), {
        0, 0, 0, 0, 0,
    })

    ctx:add(player, component.PLAYER_FORM, {
        form_id = forms.LICH,
        remaining_aut = 100,
    })

    harness.truthy(kikubaaqudgha.apply(owner, player))
    harness.truthy(ctx:get(player, component.PLAYER_SLOW).remaining_aut > 0)
    harness.equal(owner:draws_used(), 5)
end

-- Severity 27 keeps the source's negative message weight: draw 64 starts
-- drain, while draw 136 starts Torment in the 208-unit total.
local function maximum_weights(ctx)
    local drained = player_at(ctx, 27, 27)
    local drain_owner = with_draws(fixture.context(ctx, drained), {
        64, 0, 0, 0, 0,
    })

    harness.equal(curse.apply(drain_owner, drained, 27), "drain")
    harness.equal(ctx:get(drained, component.STAT_LOSS).strength, 1)

    local tormented = player_at(ctx, 27, 28)
    local torment_owner = with_draws(fixture.context(ctx, tormented), {
        136,
    })

    harness.equal(curse.apply(torment_owner, tormented, 27), "torment")
    harness.equal(ctx:get(tormented, component.HEALTH).current, 51)
end

-- A normal curse branch adds a second curse only on its one-in-four roll.
local function ordinary_wrath(ctx)
    local player = player_at(ctx, 5, 16)
    local owner = with_draws(fixture.context(ctx, player), {
        0, 26, 4, 0, 0, 0, 0, 0,
    })

    harness.truthy(kikubaaqudgha.apply(owner, player))
    harness.equal(owner:draws_used(), 8)
end

-- Failing the one-in-four roll applies exactly one curse.
local function single_curse_wrath(ctx)
    local player = player_at(ctx, 5, 30)
    local owner = with_draws(fixture.context(ctx, player), {
        0, 26, 4, 1, 0, 0,
    })

    harness.truthy(kikubaaqudgha.apply(owner, player))
    harness.equal(owner:draws_used(), 6)
end

-- XL one has no curse branch after the torment gate fails.
local function quiet_wrath(ctx)
    local player = player_at(ctx, 1, 25)
    local owner = with_draws(fixture.context(ctx, player), {
        0, 26, 0,
    })

    harness.truthy(kikubaaqudgha.apply(owner, player))
    harness.equal(ctx:get(player, component.HEALTH).current, 100)
    harness.equal(owner:draws_used(), 3)
    harness.equal(owner:message(1),
        "Kikubaaqudgha's malice focuses upon you.")
end

-- coinflip's true value is the nonzero draw, so speech changes without
-- changing the same low-level branch's draw count.
local function cackling_wrath(ctx)
    local player = player_at(ctx, 1, 29)
    local owner = with_draws(fixture.context(ctx, player), {
        1, 26, 0,
    })

    harness.truthy(kikubaaqudgha.apply(owner, player))
    harness.equal(owner:message(1),
        "You hear Kikubaaqudgha cackling.")
    harness.equal(owner:draws_used(), 3)
end

-- Every scenario has a separate actor, so saved state assertions are local.
function test.run(ctx)
    trivial_message(ctx)
    species_messages(ctx)
    pain(ctx)
    lethargy(ctx)
    draining(ctx)
    stat_draining(ctx)
    resisted_drain(ctx)
    torment(ctx)
    immune_pain(ctx)
    protected_curse(ctx)
    resistant_wrath(ctx)
    maximum_weights(ctx)
    ordinary_wrath(ctx)
    single_curse_wrath(ctx)
    quiet_wrath(ctx)
    cackling_wrath(ctx)
end

return test
