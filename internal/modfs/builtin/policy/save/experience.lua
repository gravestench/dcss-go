local catalog = require("policy.catalog")
local death = require("policy.death")
local roster = require("policy.population.roster")
local component = require("constants.component")
local effects = require("constants.vault_effects")

local module = {}

function module.run(ctx, input)
    local player = ctx:player()
    local progress = ctx:get(player, "core.progression")
    local potion = ctx:get(player, component.POTION_EXPERIENCE)
    local clone_rewards = ctx:get(player, component.CHAOS_CLONE_REWARDS)
    local allowed = roster.allowed(input.scenario_id)
    local uses_population = input.scenario_id == "fixed-dungeon-population-v1" or
        input.scenario_id == "generated-dungeon-basic-v1"
    local live = {}
    local live_count = 0
    local live_vault = {}

    for _, entity in ipairs(ctx:query({ "core.ai", "core.actor" })) do
        if not ctx:has(entity, component.SUMMON) and
            not ctx:has(entity, component.CHAOS_CLONE) then
            local actor = ctx:get(entity, "core.actor")

            local origin = ctx:get(entity, component.VAULT_ORIGIN)

            if origin then
                local key = origin.level_id .. ":" .. origin.record_index

                live_vault[key] = true
            else
                live[actor.kind_id] = true
                live_count = live_count + 1
            end
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

    for _, level in ipairs(input.vault_levels or {}) do
        for index, record in ipairs(level.vault_records or {}) do
            local arguments = record.arguments or {}
            local key = level.id .. ":" .. index

            if record.kind == effects.MONSTER and not record.pending and
                not arguments.no_spawn and arguments.kind_id and
                arguments.kind_id ~= "" and
                not live_vault[key] then
                local profile_id = arguments.base_id and
                    arguments.base_id ~= "" and
                    arguments.base_id or arguments.kind_id
                local definition = catalog.get("monsters", profile_id)
                local profile = roster.profile(profile_id)

                maximum = maximum + death.experience(definition, profile.maximum)
            end
        end
    end

    local level_adjustment = potion and potion.untrained_level_xp or 0
    local clone_xp = clone_rewards and clone_rewards.earned_xp or 0

    if level_adjustment < 0 or clone_xp < 0 or
        level_adjustment + clone_xp > progress.total_xp or
        progress.total_xp - level_adjustment - clone_xp > maximum then
        error("saved experience exceeds possible Dungeon kills")
    end

    return {}
end

register.policy({
    id = "save.validate_experience",
    run = module.run,
})

return module
