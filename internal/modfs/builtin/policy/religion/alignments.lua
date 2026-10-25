-- Divine alignment belongs to the effective god definition. A layered god
-- file can change a patron's relationships without replacing a shared
-- constant table or teaching the engine about another source ID.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local gods = require("constants.gods")

local alignments = {}

-- Sentinels represent no patron, so they have no alignment traits.
local function definition(god_id)
    if god_id == nil or god_id == gods.NO_GOD or
        god_id == gods.NAMELESS or
        god_id == gods.ECUMENICAL or god_id == "" then
        return nil
    end

    return catalog.get(categories.GODS, god_id)
end

-- Good gods share worship restrictions and spare one another's followers.
function alignments.good(god_id)
    local god = definition(god_id)

    return god ~= nil and god.good == true
end

-- Evil alignment is a relationship trait, not a retribution capability.
function alignments.evil(god_id)
    local god = definition(god_id)

    return god ~= nil and god.evil == true
end

-- Zin also objects to chaos, including chaos introduced by a mod god.
function alignments.chaotic(god_id)
    local god = definition(god_id)

    return god ~= nil and god.chaotic == true
end

-- Source god_hates_your_god: Ru does not care, no god hates itself,
-- non-good gods hate every other patron, and good gods hate evil.
function alignments.hates(god_id, worship_id)
    if god_id == gods.RU or god_id == worship_id then
        return false
    end

    if not alignments.good(god_id) then
        return true
    end

    if god_id == gods.ZIN and alignments.chaotic(worship_id) then
        return true
    end

    return alignments.evil(worship_id)
end

return alignments
