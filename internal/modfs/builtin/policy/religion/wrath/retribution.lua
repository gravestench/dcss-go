-- Divine retribution chooses a god separately from that god's effect. The
-- owner keeps source eligibility, bonus debilitation, and penance in one place.
local component = require("constants.component")
local confusion = require("policy.magic.player_confusion")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local gods = require("constants.gods")
local jiyva_life = require("policy.religion.jiyva.life")
local alignments = require("policy.religion.alignments")
local roster = require("policy.religion.wrath.roster")
local slow = require("policy.character.slow")
local streams = require("constants.rng_streams")

local retribution = {}

-- Keep the pinned source gods in enum order so vanilla card draws retain
-- their source sequence. New gods append in sorted stable ID order, so a
-- mod's filename and load order cannot change selection.
local function god_roster()
    local ids = {}
    local source = {}
    local effective = register.ids(categories.GODS)
    local available = {}

    for _, god_id in ipairs(effective) do
        available[god_id] = true
    end

    for _, god_id in ipairs(roster) do
        if available[god_id] then
            ids[#ids + 1] = god_id
            source[god_id] = true
        end
    end

    for _, god_id in ipairs(effective) do
        if not source[god_id] then
            ids[#ids + 1] = god_id
        end
    end

    return ids
end

-- One possible aftereffect follows each successful retribution. Confusion
-- and Slow use existing saved status owners; no untracked timer is created.
local function bonus(ctx, player)
    if ctx:random(streams.CARDS, 5) ~= 0 then
        return
    end

    local progression = ctx:get(player, component.PROGRESSION)

    if progression.level >= ctx:random(streams.CARDS, 37) then
        return
    end

    if ctx:random(streams.CARDS, 2) == 0 then
        if not confusion.active(ctx, player) then
            ctx:emit("religion", "The divine experience confuses you!")
            confusion.extend(ctx, player,
                5 + ctx:random(streams.CARDS, 3))
        end
    else
        ctx:emit("religion", "The divine experience drains your vigour!")
        slow.apply(ctx, player, ctx:random(streams.CARDS, 20))
    end
end

-- Penance is keyed by source god. Even zero penance still receives the
-- source decrement roll after a successful card retribution.
local function mollify(ctx, player, god_id)
    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local amount = 1 + ctx:random(streams.CARDS, 3)
    local old_penance = state.penance[god_id] or 0

    state.penance[god_id] = math.max(0,
        old_penance - amount)
    ctx:set(player, component.RELIGION_WORSHIP, state)

    -- A Wrath card can punish a god with no debt. Source dec_penance does
    -- not treat that draw as mollification of another queued wrath event.
    if old_penance > 0 and state.penance[god_id] == 0 then
        require("policy.religion.wrath.timer")
            .clear_if_mollified(ctx, player)
    end
end

-- Return false only when the source rejects a god. A missing eligible
-- punishment is explicit: silently sampling again would inflate the odds
-- of every implemented god and let an unsupported draw escape its penalty.
function retribution.invoke_god(ctx, player, god_id, options)
    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local current = state.god_id
    local force = options and options.force

    if god_id == gods.NO_GOD then
        return false
    end

    if not force and
        ((god_id == current and alignments.good(god_id)) or
            (god_id ~= current and
                not alignments.hates(god_id, current))) then
        return false
    end

    local definition = catalog.get(categories.GODS, god_id)

    -- Passive XP-penance gods have no module and still consume their card
    -- sampling attempt, just as their source switch entries do.
    if not definition.wrath_module then
        return false
    end

    local handler = require(definition.wrath_module)

    local do_more = handler.apply(ctx, player)

    if not (options and options.no_bonus) then
        if do_more then
            bonus(ctx, player)
        end

        mollify(ctx, player, god_id)
    end

    return true
end

-- Ignis becomes unavailable after prior worship and paid-off penance.
-- Jiyva's saved Royal Jelly death uses the same source availability rule.
local function unavailable(ctx, player, god_id)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if god_id == gods.JIYVA then
        return jiyva_life.dead(worship)
    end

    if god_id ~= gods.IGNIS then
        return false
    end

    return (worship.worshipped[gods.IGNIS] or 0) > 0 and
        worship.god_id ~= gods.IGNIS and
        (worship.penance[gods.IGNIS] or 0) == 0
end

-- Source active_penance excludes passive XP debt and gods that cannot act.
-- The source god iterator has stable enum order; the roster preserves it.
function retribution.active_gods(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local active = {}

    for _, god_id in ipairs(god_roster()) do
        if (worship.penance[god_id] or 0) > 0 and
            catalog.get(categories.GODS, god_id).wrath_module and
            not unavailable(ctx, player, god_id) and
            ((god_id == worship.god_id and
                not alignments.good(god_id)) or
                alignments.hates(god_id, worship.god_id)) then
            active[#active + 1] = god_id
        end
    end

    return active
end

-- religion.cc:random_god redraws unavailable gods inside one card attempt,
-- preserving the outer hundred tries for gods who decline retribution.
local function random_god(ctx, player)
    local ids = god_roster()

    while true do
        local index = ctx:random(streams.CARDS, #ids) + 1
        local god_id = ids[index]

        if not unavailable(ctx, player, god_id) then
            return god_id
        end
    end
end

-- decks.cc:_godly_wrath asks random_god up to 100 times. Eligible but
-- unimplemented gods stop explicitly rather than silently changing odds.
function retribution.sample(ctx, player)
    for _ = 1, 100 do
        local god_id = random_god(ctx, player)

        if retribution.invoke_god(ctx, player, god_id) then
            return god_id
        end
    end

    return nil
end

return retribution
