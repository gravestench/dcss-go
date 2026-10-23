-- Theory of operation: Vehumet offers book spells in thirteen escalating
-- windows. An offer is temporary access on the player's existing spell
-- record, while this component remembers the current offer, expiry of the
-- replacement cooldown, and every past offer. Memorising makes a spell
-- permanent; renouncing removes access without erasing offer history.
local books = require("policy.magic.player_book_catalog")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local fighter = require("policy.combat.fighter")
local gifts = require("policy.religion.gifts")
local gods = require("constants.gods")
local piety = require("policy.religion.piety")
local records = require("policy.character.spell_records")
local schools = require("constants.spell_schools")
local skills = require("ids.skills")
local spell_ids = require("ids.spells")
local streams = require("constants.rng_streams")

local vehumet = {}

local MIN_LEVEL = { 1, 1, 2, 3, 3, 4, 4, 5, 5, 5, 5, 6, 8 }
local MAX_LEVEL = { 1, 2, 3, 4, 5, 7, 7, 7, 7, 7, 7, 8, 9 }
local LATE_GIFT_CHANCE = 20
local FIRST_LATE_GIFT = 6
local FINAL_GIFT = #MIN_LEVEL
local BASE_WEIGHT = 100
local BASELINE_DELAY = 10

-- Vehumet also likes destructive non-Conjurations. These IDs come from
-- god-abil.cc; the spell catalog still supplies the actual definition.
local destructive = {
    [spell_ids.SPELL_SHATTER] = true,
    [spell_ids.SPELL_LRD] = true,
    [spell_ids.SPELL_SANDBLAST] = true,
    [spell_ids.SPELL_AIRSTRIKE] = true,
    [spell_ids.SPELL_POLAR_VORTEX] = true,
    [spell_ids.SPELL_FREEZE] = true,
    [spell_ids.SPELL_IGNITE_POISON] = true,
    [spell_ids.SPELL_OZOCUBUS_REFRIGERATION] = true,
    [spell_ids.SPELL_OLGREBS_TOXIC_RADIANCE] = true,
    [spell_ids.SPELL_VIOLENT_UNRAVELLING] = true,
    [spell_ids.SPELL_INNER_FLAME] = true,
    [spell_ids.SPELL_IGNITION] = true,
    [spell_ids.SPELL_FROZEN_RAMPARTS] = true,
    [spell_ids.SPELL_MAXWELLS_COUPLING] = true,
    [spell_ids.SPELL_NOXIOUS_BOG] = true,
    [spell_ids.SPELL_POISONOUS_VAPOURS] = true,
    [spell_ids.SPELL_SCORCH] = true,
}

local elemental_skills = {
    [schools.AIR] = skills.SK_AIR_MAGIC,
    [schools.EARTH] = skills.SK_EARTH_MAGIC,
    [schools.FIRE] = skills.SK_FIRE_MAGIC,
    [schools.ICE] = skills.SK_ICE_MAGIC,
}

-- DCSS random2avg makes the first draw exclusive and the second inclusive.
-- Keep this local to the gift rule so other random streams are unaffected.
local function random2avg(ctx, bound)
    local first = ctx:random(streams.RELIGION, bound)
    local second = ctx:random(streams.RELIGION, bound + 1)

    return math.floor((first + second) / 2)
end

-- Late windows roll one-in-twenty on each gift check. Earlier windows use
-- the source piety curve, with a fresh 0..5 roll for gifts one through six.
local function due(ctx, state, count)
    if count >= FINAL_GIFT then
        return false
    end

    if count == 0 then
        return state.piety >= piety.breakpoint(1)
    end

    if count < FIRST_LATE_GIFT then
        local threshold = piety.breakpoint(1) +
            ctx:random(streams.RELIGION, 6) + 18 * count

        return state.piety >= threshold
    end

    local threshold = count == FINAL_GIFT - 1 and
        piety.breakpoint(6) or piety.breakpoint(5)

    return state.piety >= threshold and
        ctx:random(streams.RELIGION, LATE_GIFT_CHANCE) == 0
end

-- Check the source Conjuration school and its explicit destructive list.
-- The book catalog independently rules out monster-only spells.
local function supported(spell)
    if destructive[spell.id] then
        return true
    end

    for _, school in ipairs(spell.schools or {}) do
        if school == schools.CONJURATION then
            return true
        end
    end

    return false
end

-- Source elemental_preference adds trained elemental skills for schools
-- present in this spell. Conjurations have the same base weight as each
-- other when the player has no relevant elemental training.
local function weight(ctx, spell)
    local value = BASE_WEIGHT

    for _, school in ipairs(spell.schools or {}) do
        local skill_id = elemental_skills[school]

        if skill_id then
            value = value + fighter.skill(ctx, skill_id, 10)
        end
    end

    return value
end

-- Prefer unseen spells, falling back to old gifts only when an entire
-- candidate window has already been offered. A known or library spell is
-- never offered, even if it came from a different god.
local function candidates(ctx, player, state, count, excluded)
    local fresh = {}
    local old = {}
    local progress = ctx:get(player, component.PROGRESSION)

    if MIN_LEVEL[count + 1] > progress.level then
        return fresh
    end

    for _, spell in ipairs(books.ordered()) do
        local entry = records.find(ctx, player, spell.id)
        local known = entry and (entry.state.in_library or
            entry.state.known_slot > 0)

        if supported(spell) and not known and not excluded[spell.id] and
            spell.level >= MIN_LEVEL[count + 1] and
            spell.level <= MAX_LEVEL[count + 1] then
            local destination = state.old_ids[spell.id] and old or fresh

            destination[#destination + 1] = spell
        end
    end

    if #fresh == 0 then
        return old
    end

    return fresh
end

-- Weighted reservoir sampling follows the source's numeric spell order.
-- Sorting is owned by the book catalog, independent of Lua file load order.
local function select_one(ctx, choices)
    local total = 0
    local selected

    for _, spell in ipairs(choices) do
        local chance = weight(ctx, spell)

        total = total + chance

        if ctx:random(streams.RELIGION, total) < chance then
            selected = spell
        end
    end

    return selected
end

-- Only the final gift offers three spells. Exclusion is recalculated after
-- every selection, as in the source, so each offer is unique.
local function select_offers(ctx, player, state, count)
    local selected = {}
    local excluded = {}
    local target = count == FINAL_GIFT - 1 and 3 or 1

    for _ = 1, target do
        local pool = candidates(ctx, player, state, count, excluded)

        if #pool == 0 then
            break
        end

        local spell = select_one(ctx, pool)

        selected[#selected + 1] = spell.id
        excluded[spell.id] = true
    end

    return selected
end

-- New offers replace old temporary access. Their past IDs stay in old_ids
-- so later windows can still avoid repeats after renunciation or reload.
local function replace(ctx, player, state, selected)
    for _, spell_id in ipairs(state.offer_ids) do
        records.clear_offer(ctx, player, spell_id, gods.VEHUMET)
    end

    state.offer_ids = selected

    for _, spell_id in ipairs(selected) do
        state.old_ids[spell_id] = true
        records.offer(ctx, player, spell_id, gods.VEHUMET)
    end

    state.cooldown_end_aut = ctx:aut() +
        (100 + random2avg(ctx, 100)) * BASELINE_DELAY
    ctx:set(player, component.RELIGION_VEHUMET, state)
end

-- Example: at 30 piety a non-innate caster receives one level-one spell;
-- at the last window they receive up to three distinct level-eight/nine
-- spells, still available after the replacement cooldown ends.
function vehumet.check(ctx, player, worship)
    local state = ctx:get(player, component.RELIGION_VEHUMET)

    if not state then
        ctx:add(player, component.RELIGION_VEHUMET, {})
        state = ctx:get(player, component.RELIGION_VEHUMET)
    end

    if state.cooldown_end_aut > ctx:aut() then
        return false
    end

    local count = worship.gift_total[gods.VEHUMET] or 0

    if not due(ctx, worship, count) then
        return false
    end

    local selected = select_offers(ctx, player, state, count)

    if #selected == 0 then
        -- Source advances a gift window if it contains no usable spell.
        gifts.record(ctx, player, 0)
        return false
    end

    replace(ctx, player, state, selected)

    local timeout = count >= 5 and 30 + random2avg(ctx, 30) or 0

    gifts.record(ctx, player, timeout)

    local names = {}

    for _, spell_id in ipairs(selected) do
        names[#names + 1] = catalog.get(categories.SPELLS, spell_id).name
    end

    ctx:emit(channels.RELIGION,
        "Vehumet offers you knowledge of " .. table.concat(names, ", ") .. ".")

    return true
end

-- Check saved current access instead of trusting a stale spell record.
function vehumet.offering(ctx, player, spell_id)
    local state = ctx:get(player, component.RELIGION_VEHUMET)

    if not state then
        return false
    end

    for _, offered in ipairs(state.offer_ids) do
        if offered == spell_id then
            return true
        end
    end

    return false
end

-- Accepting one spell removes its temporary tag and replacement cooldown.
-- Other spells in the final three-spell offer remain available.
function vehumet.accept(ctx, player, spell_id)
    if not vehumet.offering(ctx, player, spell_id) then
        return false
    end

    local state = ctx:get(player, component.RELIGION_VEHUMET)
    local remaining = {}

    for _, offered in ipairs(state.offer_ids) do
        if offered ~= spell_id then
            remaining[#remaining + 1] = offered
        end
    end

    state.offer_ids = remaining
    state.cooldown_end_aut = 0
    ctx:set(player, component.RELIGION_VEHUMET, state)
    records.clear_offer(ctx, player, spell_id, gods.VEHUMET)

    return true
end

-- Departure ends every current offer. The next conversion to Vehumet
-- retains lifetime count and old spell history, just as source DCSS does.
function vehumet.leave(ctx, player)
    local state = ctx:get(player, component.RELIGION_VEHUMET)

    if not state then
        return
    end

    for _, spell_id in ipairs(state.offer_ids) do
        records.clear_offer(ctx, player, spell_id, gods.VEHUMET)
    end

    state.offer_ids = {}
    state.cooldown_end_aut = 0
    ctx:set(player, component.RELIGION_VEHUMET, state)
end

return vehumet
