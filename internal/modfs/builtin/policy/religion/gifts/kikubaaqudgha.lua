-- Theory of operation: Kiku gives two permanent spell sets. The first
-- candidate that reaches one star grants Necrotise and three distinct early
-- necromancy spells; three stars grants five distinct later spells. Lifetime
-- gift counts live on the worshipper, so renouncing and rejoining cannot
-- repeat either set. The library owner merges with any existing spell record.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gifts = require("policy.religion.gifts")
local gods = require("constants.gods")
local piety = require("policy.religion.piety")
local records = require("policy.character.spell_records")
local species_ids = require("ids.species")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local undead = require("constants.undead_states")

local kiku = {}

local early = {
    spells.SPELL_SUBLIMATION_OF_BLOOD,
    spells.SPELL_VAMPIRIC_DRAINING,
    spells.SPELL_ANGUISH,
    spells.SPELL_ANIMATE_DEAD,
}

local late = {
    spells.SPELL_DISPEL_UNDEAD,
    spells.SPELL_CORPSE_ROT,
    spells.SPELL_AGONY,
    spells.SPELL_BORGNJORS_VILE_CLUTCH,
    spells.SPELL_DEATH_CHANNEL,
    spells.SPELL_SIMULACRUM,
}

-- The source's can_bleed(false) ignores temporary forms. Fully undead and
-- permanently nonliving species cannot use Sublimation of Blood, even if a
-- temporary status later changes their appearance or current blood state.
local function can_bleed(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)

    return species.undead_type ~= undead.UNDEAD and
        identity.species_id ~= species_ids.SP_GARGOYLE and
        identity.species_id ~= species_ids.SP_DJINNI
end

-- Sample without replacement from the source candidate pool. Repeated
-- source random_choose calls have this same uniform subset distribution;
-- removing a chosen candidate also guarantees termination for sparse mods.
local function choose(ctx, candidates, count)
    local pool = {}
    local selected = {}

    for _, spell_id in ipairs(candidates) do
        pool[#pool + 1] = spell_id
    end

    if #pool < count then
        error("Kikubaaqudgha has too few gift spells")
    end

    for _ = 1, count do
        local index = ctx:random(streams.RELIGION, #pool) + 1

        selected[#selected + 1] = table.remove(pool, index)
    end

    return selected
end

-- Example: a Human at thirty piety gets Necrotise plus three spells; a
-- Mummy gets the three remaining early spells without Sublimation.
local function first_set(ctx, player)
    local candidates = {}

    for _, spell_id in ipairs(early) do
        if spell_id ~= spells.SPELL_SUBLIMATION_OF_BLOOD or
            can_bleed(ctx, player) then
            candidates[#candidates + 1] = spell_id
        end
    end

    local selected = choose(ctx, candidates, 3)

    table.insert(selected, 1, spells.SPELL_NECROTISE)

    return selected
end

-- The second set keeps five of the six source higher-level spells, even
-- when the character has already learned one from a floor book.
local function second_set(ctx)
    return choose(ctx, late, 5)
end

-- Grant one complete set at each threshold and count it even if every
-- selected spell was already in the library, matching the source gift note.
function kiku.check(ctx, player, state)
    local count = state.gift_total[gods.KIKUBAAQUDGHA] or 0
    local selected

    if count == 0 and state.piety >= piety.breakpoint(1) then
        selected = first_set(ctx, player)
    elseif count == 1 and state.piety >= piety.breakpoint(3) then
        selected = second_set(ctx)
    else
        return false
    end

    local added = records.grant_library(ctx, player, selected)

    if added > 0 then
        ctx:emit(channels.RELIGION, "Kikubaaqudgha grants you a gift!")
    else
        ctx:emit(channels.RELIGION,
            "Kikubaaqudgha has no new spells for you at this time.")
    end

    gifts.record(ctx, player, 0)

    return true
end

return kiku
