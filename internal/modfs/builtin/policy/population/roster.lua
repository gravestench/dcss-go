local roster = {}

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
    ["fixed-dungeon-population-v1"] = population,
    ["generated-dungeon-basic-v1"] = generated,
}

-- These bounds come from the ordinary natural profiles, not the broad
-- imported monster catalog. They guard the current playable roster.
local profiles = {
    MONS_RAT = { average = 25, minimum = 1, maximum = 4 },
    MONS_QUOKKA = { average = 55, minimum = 3, maximum = 8 },
    MONS_FRILLED_LIZARD = { average = 20, minimum = 1, maximum = 3 },
    MONS_GIANT_COCKROACH = { average = 50, minimum = 3, maximum = 7 },
    MONS_WORM = { average = 180, minimum = 12, maximum = 24 },
    MONS_JACKAL = { average = 55, minimum = 3, maximum = 8 },
    MONS_ADDER = { average = 110, minimum = 7, maximum = 15 },
    MONS_BAT = { average = 35, minimum = 2, maximum = 5 },
    MONS_BALL_PYTHON = { average = 35, minimum = 2, maximum = 5 },
    MONS_ENDOPLASM = { average = 60, minimum = 4, maximum = 8 },
    MONS_DART_SLUG = { average = 100, minimum = 6, maximum = 14 },
    MONS_GOBLIN = { average = 40, minimum = 2, maximum = 6 },
    MONS_HOBGOBLIN = { average = 55, minimum = 3, maximum = 8 },
    MONS_KOBOLD = { average = 35, minimum = 2, maximum = 5 },
}

function roster.allowed(scenario_id)
    local ids = scenarios[scenario_id]

    if not ids then
        error("unsupported population scenario " .. tostring(scenario_id))
    end

    local allowed = {}

    for _, id in ipairs(ids) do
        allowed[id] = true
    end

    return allowed
end

function roster.profile(id)
    local profile = profiles[id]

    if not profile then
        error("unsupported ordinary monster " .. tostring(id))
    end

    return profile
end

return roster
