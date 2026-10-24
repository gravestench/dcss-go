local catalog = require("policy.catalog")
local death = require("policy.death")
local roster = require("policy.population.roster")
local wizlab_experience = require("policy.world.wizlab.events.experience")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local doom_howl = require("policy.combat.monster_doom_howl.ids")
local branches = require("ids.branches")
local trigger_ids = require("constants.vault_triggers")
local monsters = require("ids.monsters")
local scenarios = require("constants.scenarios")

local module = {}

-- Saved XP and level progress are checked against the same progression limits used in play.
-- Example: module.run(ctx, input) checks saved XP against the scenario's available monster rewards.
function module.run(ctx, input)
    local player = ctx:player()
    local progress = ctx:get(player, "core.progression")
    local potion = ctx:get(player, component.POTION_EXPERIENCE)
    local clone_rewards = ctx:get(player, component.CHAOS_CLONE_REWARDS)
    local doom_rewards = ctx:get(player, doom_howl.REWARDS)
    local level_adjustment = potion and potion.untrained_level_xp or 0
    local clone_xp = clone_rewards and clone_rewards.earned_xp or 0
    local doom_xp = doom_rewards and doom_rewards.earned_xp or 0

    if level_adjustment < 0 or clone_xp < 0 or doom_xp < 0 or
        level_adjustment + clone_xp + doom_xp > progress.total_xp then
        error("saved experience has invalid grant history")
    end

    -- Generated runs can keep earning XP from respawns and transient Pan
    -- regions after the source floor has disappeared from the save. Their
    -- current population cannot cap lifetime kills. The player validator
    -- checks the level/XP relation; explicit non-kill grants are checked
    -- above. Finite test scenarios retain the stronger roster bound below.
    if input.scenario_id == scenarios.GENERATED_DUNGEON_BASIC then
        return {}
    end

    local allowed = roster.allowed(input.scenario_id, branches.BRANCH_DUNGEON)
    local uses_population =
        input.scenario_id == scenarios.FIXED_POPULATION
    local live = {}
    local live_count = 0
    local live_vault = {}
    local live_delayed = {}
    local armed_delayed = {}

    -- A source movement trigger can produce one permanent monster after
    -- ordinary population. Its presence must not spend a roster slot.
    for _, entity in ipairs(ctx:query({ component.WORLD_VAULT_TRIGGER })) do
        local trigger = ctx:get(entity, component.WORLD_VAULT_TRIGGER)

        if trigger_ids.PREFIX .. trigger.callback_module .. "." ..
            trigger.callback_method == trigger_ids.LADY_OF_LAKE_SPAWN then
            armed_delayed[trigger.level_id .. ":" .. trigger.vault_id] = true
        end
    end

    for _, entity in ipairs(ctx:query({ "core.ai", "core.actor" })) do
        local growth = ctx:get(entity, component.JIYVA_GROWTH)
        local born_from_split = growth and growth.born_from_split or
            ctx:has(entity, component.SLIME_BIRTH)

        -- Jiyva and ordinary slime births do not consume a second slot in
        -- the initial population used to bound possible Dungeon rewards.
        if not ctx:has(entity, component.SUMMON) and
            -- Pacification already paid the monster's XP even though its
            -- neutral body remains on the floor until it departs.
            not ctx:has(entity, component.ELYVILON_PACIFIED) and
            not ctx:has(entity, component.CHAOS_CLONE) and
            not ctx:has(entity, doom_howl.ARRIVAL) and
            not ctx:has(entity, component.JIYVA_SPAWN) and
            not ctx:has(entity, component.BEOGH_RESURRECTED) and
            not born_from_split then
            local actor = ctx:get(entity, "core.actor")

            local origin = ctx:get(entity, component.VAULT_ORIGIN)
            local delayed = ctx:get(entity, component.WORLD_VAULT_SPAWN)
            local wizlab_event = ctx:get(entity,
                component.WORLD_WIZLAB_EVENT_ACTOR)

            -- Event actors are born after population; their separate
            -- provenance is checked by the lab event owner.
            if delayed then
                live_delayed[delayed.level_id .. ":" .. delayed.vault_id] = true
            elseif origin then
                local key = origin.level_id .. ":" .. origin.record_index

                live_vault[key] = true
            elseif not wizlab_event then
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

    -- Once the source entrance has fired, its avatar can die and award XP.
    -- Count that one source body only when no armed entrance or live avatar
    -- remains; otherwise the ordinary maximum would allow premature XP.
    local counted_delayed = {}

    for _, level in ipairs(input.vault_levels or {}) do
        for _, record in ipairs(level.vault_records or {}) do
            if record.kind == effects.MARKER and
                record.identity == trigger_ids.LADY_OF_LAKE_SPAWN then
                local key = level.id .. ":" .. record.source_id

                if not counted_delayed[key] and
                    not armed_delayed[key] and not live_delayed[key] then
                    local id = monsters.MONS_MERFOLK_AVATAR
                    local definition = catalog.get("monsters", id)
                    local profile = roster.profile(id)

                    maximum = maximum + death.experience(
                        definition, profile.maximum)
                    counted_delayed[key] = true
                end
            end
        end
    end

    -- The source encounter owner bounds XP from monsters it created
    -- after the fixed population budget was established.
    maximum = maximum + wizlab_experience.maximum(ctx)

    if progress.total_xp - level_adjustment - clone_xp - doom_xp > maximum then
        error("saved experience exceeds possible Dungeon kills")
    end

    return {}
end

register.policy({
    id = "save.validate_experience",
    run = module.run,
})

return module
