-- Example: A fixture roster includes its pinned IDs and scenario-tagged catalog monsters.
local roster = {}
local catalog = require("policy.catalog")
local spell_coverage = require("policy.combat.monster_spell_coverage")

local fixed = {
    "MONS_RAT",
    "MONS_QUOKKA",
    "MONS_FRILLED_LIZARD",
}

local population = {
    "MONS_RAT",
    "MONS_QUOKKA",
    "MONS_FRILLED_LIZARD",
    "MONS_GIANT_COCKROACH",
    "MONS_WORM",
    "MONS_JACKAL",
    "MONS_ADDER",
}

local generated = {
    "MONS_RAT",
    "MONS_QUOKKA",
    "MONS_FRILLED_LIZARD",
    "MONS_GIANT_COCKROACH",
    "MONS_WORM",
    "MONS_JACKAL",
    "MONS_ADDER",
    "MONS_BAT",
    "MONS_BALL_PYTHON",
    "MONS_ENDOPLASM",
    "MONS_DART_SLUG",
    "MONS_HOBGOBLIN",
}

local scenarios = {
    [""] = { "MONS_RAT" },
    ["fixed-dungeon-rat-quokka-v1"] = { "MONS_RAT", "MONS_QUOKKA" },
    ["fixed-dungeon-rat-quokka-lizard-v2"] = fixed,
    ["fixed-dungeon-shops-v1"] = fixed,
    ["fixed-dungeon-population-v1"] = population,
    ["generated-dungeon-basic-v1"] = generated,
}

-- A scenario roster starts with fixture IDs, then admits catalog monsters tagged for that same scenario.
function roster.allowed(scenario_id)
    local ids = scenarios[scenario_id]

    if not ids then
        error("unsupported population scenario " .. tostring(scenario_id))
    end

    local allowed = {}

    for _, id in ipairs(ids) do
        allowed[id] = true
    end

    for _, definition in ipairs(catalog.all("monsters")) do
        for _, row in ipairs(definition.population or {}) do
            if row.scenario_id == scenario_id then
                allowed[definition.id] = true
            end
        end
    end

    local missing = spell_coverage.missing(allowed)

    if #missing > 0 then
        local first = missing[1]

        error("population scenario " .. scenario_id .. " admits " ..
            first.monster_id .. " with " .. first.reason .. " for " ..
            first.book_id .. "/" .. first.spell_id)
    end

    return allowed
end

-- Spawn profiles expose the catalog habitat and flags needed by placement after a roster pick.
function roster.profile(id)
    local definition = catalog.get("monsters", id)
    local average = definition.average_hp_10x
    local variance = math.ceil(average * 33 / 100)

    return {
        average = average,
        minimum = math.max(1, math.floor((average - variance) / 10)),
        maximum = math.min(10000, math.ceil((average + variance) / 10)),
    }
end

return roster
