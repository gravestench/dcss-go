-- Example: A fixed benchmark keeps its pinned actors, while generated play
-- reads the active branch's source rows and mod additions.
local roster = {}
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local sentinels = require("constants.population_sentinels")
local spell_coverage = require("policy.combat.monster_spell_coverage")
local monsters = require("ids.monsters")
local scenario_ids = require("constants.scenarios")

local fixed = {
    monsters.MONS_RAT,
    monsters.MONS_QUOKKA,
    monsters.MONS_FRILLED_LIZARD,
}

local population = {
    monsters.MONS_RAT,
    monsters.MONS_QUOKKA,
    monsters.MONS_FRILLED_LIZARD,
    monsters.MONS_GIANT_COCKROACH,
    monsters.MONS_WORM,
    monsters.MONS_JACKAL,
    monsters.MONS_ADDER,
}

local scenarios = {
    [scenario_ids.FIXED_RAT] = { monsters.MONS_RAT },
    [scenario_ids.FIXED_RAT_QUOKKA] = {
        monsters.MONS_RAT,
        monsters.MONS_QUOKKA,
    },
    [scenario_ids.FIXED_LIZARD] = fixed,
    [scenario_ids.FIXED_SHOPS] = fixed,
    [scenario_ids.FIXED_POPULATION] = population,
    [scenario_ids.GENERATED_DUNGEON_BASIC] = {},
}

-- Fixed fixtures keep their pinned actors. A generated branch admits every
-- monster in its effective population data; sparse mod rows enter the same
-- roster without a second handwritten allowlist.
function roster.allowed(scenario_id, branch_id)
    local ids = scenarios[scenario_id]

    if not ids then
        error("unsupported population scenario " .. tostring(scenario_id))
    end

    local allowed = {}

    for _, id in ipairs(ids) do
        allowed[id] = true
    end

    if scenario_id == scenario_ids.GENERATED_DUNGEON_BASIC then
        if not branch_id then
            error("generated population requires a branch ID")
        end

        for _, definition in ipairs(catalog.all(categories.POPULATIONS)) do
            if definition.branch_id == branch_id and
                (not definition.scenario_id or
                    definition.scenario_id == scenario_id) then
                for _, row in ipairs(definition.rows) do
                    if row.monster_id ~= sentinels.NO_MONSTER then
                        allowed[row.monster_id] = true
                    end
                end
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
function roster.profile(id, hit_dice)
    local definition = catalog.get(categories.MONSTERS, id)
    local average = definition.average_hp_10x
    local low_average = average
    local high_average = average

    if hit_dice and hit_dice ~= definition.hd then
        low_average = math.floor(average * hit_dice / definition.hd)
        high_average = math.ceil(average * hit_dice / definition.hd)
    end

    local low_variance = math.ceil(low_average * 33 / 100)
    local high_variance = math.ceil(high_average * 33 / 100)

    return {
        average = average,
        minimum = math.max(1,
            math.floor((low_average - low_variance) / 10)),
        maximum = math.min(10000,
            math.ceil((high_average + high_variance) / 10)),
    }
end

return roster
