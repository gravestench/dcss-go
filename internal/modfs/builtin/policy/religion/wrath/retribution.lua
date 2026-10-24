-- Divine retribution chooses a god separately from that god's effect. The
-- owner keeps source eligibility, bonus debilitation, and penance in one place.
local component = require("constants.component")
local confusion = require("policy.magic.player_confusion")
local gods = require("constants.gods")
local alignments = require("constants.god_alignments")
local roster = require("policy.religion.wrath.roster")
local slow = require("policy.character.slow")
local streams = require("constants.rng_streams")

local retribution = {}

local handlers = {
    [gods.BEOGH] = require("policy.religion.wrath.beogh"),
    [gods.CHEIBRIADOS] = require("policy.religion.wrath.cheibriados"),
    [gods.DITHMENOS] = require("policy.religion.wrath.dithmenos"),
    [gods.FEDHAS] = require("policy.religion.wrath.fedhas"),
    [gods.IGNIS] = require("policy.religion.wrath.ignis"),
    [gods.JIYVA] = require("policy.religion.wrath.jiyva"),
    [gods.KIKUBAAQUDGHA] = require("policy.religion.wrath.kikubaaqudgha"),
    [gods.LUGONU] = require("policy.religion.wrath.lugonu"),
    [gods.MAKHLEB] = require("policy.religion.wrath.makhleb"),
    [gods.OKAWARU] = require("policy.religion.wrath.okawaru"),
    [gods.QAZLAL] = require("policy.religion.wrath.qazlal"),
    [gods.SHINING_ONE] = require("policy.religion.wrath.shining_one"),
    [gods.SIF_MUNA] = require("policy.religion.wrath.sif_muna"),
    [gods.TROG] = require("policy.religion.wrath.trog"),
    [gods.USKAYAW] = require("policy.religion.wrath.uskayaw"),
    [gods.VEHUMET] = require("policy.religion.wrath.vehumet"),
    [gods.WU_JIAN] = require("policy.religion.wrath.wu_jian"),
    [gods.XOM] = require("policy.religion.wrath.xom"),
    [gods.YREDELEMNUL] = require("policy.religion.wrath.yredelemnul"),
    [gods.ZIN] = require("policy.religion.wrath.zin"),
}

-- These source switch entries return false without bonus or penance loss.
-- They still occupy a random_god draw before decks.cc tries again.
local no_retribution = {
    [gods.ASHENZARI] = true,
    [gods.ELYVILON] = true,
    [gods.GOZAG] = true,
    [gods.RU] = true,
    [gods.HEPLIAKLQANA] = true,
}

local evil = {
    [gods.KIKUBAAQUDGHA] = true,
    [gods.MAKHLEB] = true,
    [gods.YREDELEMNUL] = true,
    [gods.BEOGH] = true,
    [gods.LUGONU] = true,
    [gods.DITHMENOS] = true,
}

-- Source god_hates_your_god treats non-good gods as hostile to every other
-- patron. Zin hates chaos and other good gods spare Nemelex worshippers.
local function hates(god_id, worship_id)
    if god_id == gods.RU or god_id == worship_id then
        return false
    end

    if not alignments.GOOD[god_id] then
        return true
    end

    if god_id == gods.ZIN and alignments.CHAOTIC[worship_id] then
        return true
    end

    return evil[worship_id] == true
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

    state.penance[god_id] = math.max(0,
        (state.penance[god_id] or 0) - amount)
    ctx:set(player, component.RELIGION_WORSHIP, state)
end

-- Return false only when the source rejects a god. A missing eligible
-- punishment is explicit: silently sampling again would inflate the odds
-- of every implemented god and let an unsupported draw escape its penalty.
function retribution.invoke_god(ctx, player, god_id, options)
    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local current = state.god_id
    local force = options and options.force

    if god_id == gods.NO_GOD or god_id == gods.NEMELEX_XOBEH then
        return false
    end

    if not force and
        ((god_id == current and alignments.GOOD[god_id]) or
            (god_id ~= current and not hates(god_id, current))) then
        return false
    end

    if no_retribution[god_id] then
        return false
    end

    local handler = handlers[god_id]

    if not handler then
        error("unimplemented divine retribution for " .. god_id)
    end

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
-- Jiyva's separate royal_jelly_dead flag has no saved owner yet, so that
-- availability condition remains a known gap in the local god catalog.
local function unavailable(ctx, player, god_id)
    if god_id ~= gods.IGNIS then
        return false
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    return (worship.worshipped[gods.IGNIS] or 0) > 0 and
        worship.god_id ~= gods.IGNIS and
        (worship.penance[gods.IGNIS] or 0) == 0
end

-- religion.cc:random_god redraws unavailable gods inside one card attempt,
-- preserving the outer hundred tries for gods who decline retribution.
local function random_god(ctx, player)
    while true do
        local index = ctx:random(streams.CARDS, #roster) + 1
        local god_id = roster[index]

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
