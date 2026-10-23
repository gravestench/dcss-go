-- Theory of operation: prayer reads the saved altar record at the player's
-- cell, offers a no-time confirmation, and rechecks that same record before
-- spending a turn. The timed resolver changes worship and, for an unknown
-- altar, replaces its saved god ID. Go only supplies typed records and time.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local eligibility = require("policy.religion.eligibility")
local gods = require("constants.gods")
local intents = require("constants.intent")
local names = require("policy.religion.names")
local sources = require("constants.religion_sources")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local worship = require("policy.religion.worship")

local prayer = {}

-- The generic terrain cell cannot identify a god. Exactly one saved source
-- feature at this coordinate supplies the authoritative altar identity.
local function altar_at(ctx, position)
    -- The pocket Abyss has a typed Lugonu altar without a DES source
    -- record. Other altars still derive their god from authored records.
    if ctx:cell(position.level_id, position.x, position.y) ==
        terrain.DNGN_ALTAR_LUGONU then
        return {}, gods.LUGONU
    end

    if ctx:cell(position.level_id, position.x, position.y) ~=
        terrain.DNGN_RANDOM_ALTAR then
        return nil
    end

    local altar

    for _, record in ipairs(ctx:records_at(position.level_id,
        position.x, position.y)) do
        if record.kind == effects.SOURCE_FEATURE and
            record.identity == terrain.DNGN_RANDOM_ALTAR and
            not record.pending and not record.overridden then
            if altar then
                error("altar cell contains multiple source altar records")
            end

            altar = record
        end
    end

    if not altar then
        error("altar terrain has no saved god record")
    end

    local god_id = altar.arguments.god_id

    if type(god_id) ~= "string" or god_id == "" then
        error("altar record has no god ID")
    end

    if god_id ~= gods.ECUMENICAL then
        catalog.get(categories.GODS, god_id)
    end

    return altar, god_id
end

-- A refusal must be settled before the confirmation prompt; the player can
-- return when a temporary form or Gozag's wallet condition changes.
local function refusal(ctx, player, god_id)
    if god_id == gods.ECUMENICAL then
        return nil
    end

    return eligibility.check(ctx, player, god_id, true)
end

-- An unknown altar must know that at least one patron can accept the
-- player before prompting. This scan reads stable catalog IDs and no RNG.
local function unknown_candidate(ctx, player)
    for _, id in ipairs(register.ids(categories.GODS)) do
        local temporary = id ~= gods.GOZAG

        if not eligibility.check(ctx, player, id, temporary) then
            return true
        end
    end

    return false
end

-- The proposal carries the exact saved god ID to the terminal. No RNG is
-- consumed here, including when an ecumenical altar remains unidentified.
function prayer.prepare(ctx, player, input, position)
    local altar, god_id = altar_at(ctx, position)

    if not altar then
        return { message = "There is no altar here." }
    end

    local current = ctx:get(player, component.RELIGION_WORSHIP)

    if not current then
        error("prayer requires worship state")
    end

    if god_id == current.god_id then
        return {
            message = "You offer a prayer to " .. names[god_id] .. ".",
        }
    end

    local denied = refusal(ctx, player, god_id)

    if denied then
        return { message = denied }
    end

    if god_id == gods.ECUMENICAL and
        not unknown_candidate(ctx, player) then
        return { message = "No god will accept your worship." }
    end

    if not input.forced then
        local prompt

        if god_id == gods.ECUMENICAL then
            prompt = "You cannot tell which god this altar belongs to. Convert anyway?"
        elseif current.god_id == gods.NO_GOD then
            prompt = "Really worship " .. names[god_id] .. "?"
        else
            prompt = "Really abandon " .. names[current.god_id] ..
                " for " .. names[god_id] .. "?"
        end

        return {
            confirmation = prompt,
            confirmation_id = god_id,
        }
    end

    if input.target_id ~= god_id then
        return { message = "The altar has changed since you answered." }
    end

    return {
        intent = {
            kind = intents.PRAYER,
            target_id = god_id,
        },
        cost = 10,
    }
end

-- Source random_god draws from the active pantheon until an eligible god
-- appears. Sorted stable IDs keep file names and load order out of the draw.
local function unknown_god(ctx, player)
    local ids = register.ids(categories.GODS)

    if not unknown_candidate(ctx, player) then
        error("no god can accept this player at the unknown altar")
    end

    while true do
        local index = ctx:random(streams.RELIGION, #ids) + 1
        local id = ids[index]
        local temporary = id ~= gods.GOZAG

        if not eligibility.check(ctx, player, id, temporary) then
            return id
        end
    end
end

-- The confirmed intent still must match the saved record. The unknown
-- altar is identified only after acceptance; its new identity survives
-- save/restore through the generic staged record operation.
function prayer.resolve(ctx, player, intent)
    local position = ctx:get(player, component.POSITION)

    if not position then
        error("praying player has no position")
    end

    local altar, saved_id = altar_at(ctx, position)

    if not altar or saved_id ~= intent.target_id then
        error("altar changed before prayer resolved")
    end

    local god_id = saved_id
    local source = sources.ALTAR

    if saved_id == gods.ECUMENICAL then
        god_id = unknown_god(ctx, player)
        source = sources.ECUMENICAL
    end

    local current = ctx:get(player, component.RELIGION_WORSHIP)

    if current.god_id ~= god_id then
        worship.join(ctx, player, god_id, source)
    end

    if saved_id == gods.ECUMENICAL then
        ctx:replace_record_string(position.level_id,
            position.x, position.y, altar.source_id,
            altar.kind, altar.identity, "god_id", saved_id, god_id)
    end

    return names[god_id] .. " accepts your prayer!"
end

return prayer
