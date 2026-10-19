-- Source: traps.cc. Weights are source order, not a Go switch.
local ids = require("ids.zot_outcomes")
local streams = require("constants.rng_streams")

local catalog = {}

local outcomes = {
    {
        id = ids.STAT_LOSS,
        weight = 4,
        module = "policy.traps.zot.stat_loss",
    },
    {
        id = ids.CONTAMINATION,
        weight = 4,
        module = "policy.traps.zot.contamination",
    },
    {
        id = ids.PARALYSIS,
        weight = 1,
        module = "policy.traps.zot.paralysis",
    },
    {
        id = ids.MP_DRAIN,
        weight = 2,
        module = "policy.traps.zot.mp_drain",
    },
    {
        id = ids.PETRIFICATION,
        weight = 1,
        module = "policy.traps.zot.petrification",
    },
    {
        id = ids.LOWER_WILL,
        weight = 4,
        module = "policy.traps.zot.lower_will",
    },
    {
        id = ids.RECALL,
        weight = 3,
        module = "policy.traps.zot.recall",
    },
    {
        id = ids.GREATER_DEMON,
        weight = 3,
        module = "policy.traps.zot.greater_demon",
    },
    {
        id = ids.MALIGN_GATEWAY,
        weight = 1,
        module = "policy.traps.zot.malign_gateway",
    },
    {
        id = ids.TWISTER,
        weight = 1,
        module = "policy.traps.zot.twister",
    },
}

-- Expose the fixed weighted Zot table to activation and validation.
function catalog.outcomes()
    return outcomes
end

-- Use the traps RNG stream against explicit weights so every Zot activation selects one outcome.
-- Example: stat loss has four slots in the 24-weight Zot table; each trigger spends one traps-stream draw.
function catalog.choose(ctx)
    local total = 0

    for _, outcome in ipairs(outcomes) do
        total = total + outcome.weight
    end

    local draw = ctx:random(streams.TRAPS, total)

    for _, outcome in ipairs(outcomes) do
        if draw < outcome.weight then
            return outcome
        end

        draw = draw - outcome.weight
    end

    error("Zot draw exceeded weighted table")
end

-- Validate each module at boot so a selected outcome cannot fail only when its trap fires.
function catalog.validate()
    local seen = {}

    for _, outcome in ipairs(outcomes) do
        if seen[outcome.id] or outcome.weight < 1 or
            outcome.weight % 1 ~= 0 then
            error("invalid Zot outcome " .. tostring(outcome.id))
        end

        seen[outcome.id] = true
        local module = require(outcome.module)

        if type(module.apply) ~= "function" then
            error("Zot outcome has no apply method " .. outcome.id)
        end
    end
end

return catalog
