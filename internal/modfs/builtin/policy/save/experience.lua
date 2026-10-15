local catalog = require("policy.catalog")
local death = require("policy.death")
local roster = require("policy.population.roster")

local module = {}

function module.run(ctx, input)
    local player = ctx:player()
    local progress = ctx:get(player, "core.progression")
    local allowed = roster.allowed(input.scenario_id)
    local uses_population = input.scenario_id == "fixed-dungeon-population-v1" or
        input.scenario_id == "generated-dungeon-basic-v1"
    local live = {}
    local live_count = 0

    for _, entity in ipairs(ctx:query({ "core.ai", "core.actor" })) do
        if not ctx:get(entity, "magic.summon") then
            local actor = ctx:get(entity, "core.actor")

            live[actor.kind_id] = true
            live_count = live_count + 1
        end
    end

    local maximum = 0

    for id in pairs(allowed) do
        if uses_population or not live[id] then
            local definition = catalog.get("monsters", id)
            local profile = roster.profile(id)
            local amount = death.experience(definition, profile.maximum)

            if uses_population then
                maximum = math.max(maximum, amount)
            else
                maximum = maximum + amount
            end
        end
    end

    if uses_population then
        maximum = maximum * (input.initial_count - live_count)
    end

    if progress.total_xp > maximum then
        error("saved experience exceeds possible Dungeon kills")
    end

    return {}
end

register.policy({
    id = "save.validate_experience",
    run = module.run,
})

return module
