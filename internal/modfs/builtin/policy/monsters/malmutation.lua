-- A monster's body change belongs to the monster, regardless of whether
-- its cause was a ray, an area spell, a cloud, or a player's mutation.
-- Source: monster.cc:monster::can_mutate and monster::malmutate.
local channels = require("constants.message_channels")
local component = require("constants.component")
local holiness = require("constants.monster_holiness")
local monsters = require("ids.monsters")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local ugly_thing = require("policy.monsters.ugly_thing")

local malmutation = {}

-- mon-tentacle.cc names the linked tentacle bodies whose mutation cannot
-- be represented as an independent monster status.
local tentacles = {
    [monsters.MONS_KRAKEN_TENTACLE] = true,
    [monsters.MONS_KRAKEN_TENTACLE_SEGMENT] = true,
    [monsters.MONS_STARSPAWN_TENTACLE] = true,
    [monsters.MONS_STARSPAWN_TENTACLE_SEGMENT] = true,
    [monsters.MONS_ELDRITCH_TENTACLE] = true,
    [monsters.MONS_ELDRITCH_TENTACLE_SEGMENT] = true,
    [monsters.MONS_SNAPLASHER_VINE] = true,
    [monsters.MONS_SNAPLASHER_VINE_SEGMENT] = true,
}

-- Source traits are lists; an absent entry cannot grant an immunity.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Tentacle segments and Chaos Spawn are too unusual to malmutate.
-- Abominations and ugly things are mutable, but neither gains Wretched.
-- The former rerolls a tile; the latter rerolls combat traits and colour.
function malmutation.can_mutate(definition)
    if definition.id == monsters.MONS_CHAOS_SPAWN or
        tentacles[definition.id] then
        return false
    end

    if definition.id == monsters.MONS_ABOMINATION_SMALL or
        definition.id == monsters.MONS_ABOMINATION_LARGE then
        return true
    end

    return not has(definition.holiness, holiness.UNDEAD) and
        not has(definition.holiness, holiness.NONLIVING)
end

-- The duration is measured in aut and scaled by the victim's speed so a
-- fast monster experiences roughly the same number of actions.
local function wretched_duration(ctx, target, stream)
    local actor = ctx:get(target, component.ACTOR)
    local speed = math.max(1, actor.speed)
    local base = 20

    for _ = 1, 3 do
        base = base + 1 + ctx:random(stream, 10)
    end

    local centiturns = math.max(2,
        math.floor(base * 10 / math.max(1,
            math.floor(100 / speed))))
    local raw = centiturns *
        roll.random_divide(ctx, 100, speed, stream)
    local low = math.floor(raw * 60 / 100)
    local high = math.floor(raw * 40 / 100)
    local fuzz = roll.average_two(ctx, stream, low + high + 1)

    return math.max(15, raw + fuzz - low)
end

-- Repeated mutation extends the existing saved Wretched duration. Source
-- abominations reroll a tile. Ugly things instead replace their saved
-- colour, attack, and resistance while preserving HP and HD.
function malmutation.apply(ctx, target, definition, stream)
    if not malmutation.can_mutate(definition) then
        return false
    end

    if definition.id == monsters.MONS_ABOMINATION_SMALL or
        definition.id == monsters.MONS_ABOMINATION_LARGE then
        return true
    end

    if ugly_thing.kind(definition.id) then
        ugly_thing.try_mutate(ctx, target, definition,
            stream or streams.MUTATION)

        return true
    end

    local added = wretched_duration(ctx, target,
        stream or streams.SPELL)
    local state = ctx:get(target, component.WRETCHED)

    if state then
        state.remaining_aut = state.remaining_aut + added
        ctx:set(target, component.WRETCHED, state)
    else
        ctx:add(target, component.WRETCHED, {
            remaining_aut = added,
        })
    end

    if senses.player_sees_actor(ctx, target) then
        ctx:emit(channels.SPELL, "The " .. definition.name ..
            " twists and deforms.")
    end

    return true
end

return malmutation
