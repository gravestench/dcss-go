-- Theory of operation: a Demonspawn rolls source facets once at creation,
-- orders their three grants within each facet, and saves one ECS record per
-- future level. Level gains and Ru read those records; neither rerolls them.
local armour_slots = require("constants.armour_slots")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local facets = require("constants.demonspawn_facets")
local mutation_classes = require("constants.mutation_classes")
local mutation_records = require("policy.mutations.records")
local mutation_transition = require("policy.mutations.transition")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local demonspawn = {}

local required = {
    [facets.BODY] = 1,
    [facets.SCALE] = 1,
    [facets.SECONDARY] = 2,
    [facets.FINAL] = 1,
}

local body_slots = {
    [armour_slots.HELMET] = true,
    [armour_slots.GLOVES] = true,
    [armour_slots.BOOTS] = true,
    [armour_slots.CLOAK] = true,
}

local windows = {
    [facets.EARLY] = true,
    [facets.ANY] = true,
    [facets.LATE] = true,
}

-- Keep content errors at character creation, before any partial schedule
-- enters a save. Mod facets use the same checks as the bundled source set.
local function validate_definition(definition)
    if type(definition.id) ~= "string" or definition.id == "" or
        not required[definition.tier] or
        type(definition.mutations) ~= "table" or
        type(definition.windows) ~= "table" or
        #definition.mutations ~= 3 or #definition.windows ~= 3 then
        error("invalid Demonspawn facet definition")
    end

    local counts = {}

    for rank = 1, 3 do
        local id = definition.mutations[rank]
        local mutation = catalog.get(categories.MUTATIONS, id)

        counts[id] = (counts[id] or 0) + 1

        if counts[id] > mutation.max_level then
            error("Demonspawn facet exceeds mutation cap " .. id)
        end

        if not windows[definition.windows[rank]] then
            error("invalid Demonspawn facet window " .. definition.id)
        end
    end

    if definition.tier == facets.BODY then
        if not body_slots[definition.body_slot] then
            error("invalid Demonspawn body slot " .. definition.id)
        end
    elseif definition.body_slot ~= nil then
        error("non-body Demonspawn facet has a body slot")
    end

    if definition.elemental ~= nil and
        type(definition.elemental) ~= "boolean" then
        error("invalid Demonspawn elemental flag")
    end

    if definition.cloud_producing ~= nil and
        type(definition.cloud_producing) ~= "boolean" then
        error("invalid Demonspawn cloud flag")
    end
end

-- Validate the entire effective catalog, including mod additions, before
-- sampling it. Uniform sampling of a tier requires enough eligible files.
local function pools()
    local by_tier = {
        [facets.BODY] = {},
        [facets.SCALE] = {},
        [facets.SECONDARY] = {},
        [facets.FINAL] = {},
    }
    local distinct_slots = {}

    for _, definition in ipairs(catalog.all(
        categories.DEMONSPAWN_FACETS)) do
        validate_definition(definition)
        local pool = by_tier[definition.tier]

        pool[#pool + 1] = definition

        if definition.body_slot then
            distinct_slots[definition.body_slot] = true
        end
    end

    local slots = 0

    for _ in pairs(distinct_slots) do
        slots = slots + 1
    end

    if #by_tier[facets.BODY] < 3 or slots < 3 or
        #by_tier[facets.SCALE] < 1 or
        #by_tier[facets.SECONDARY] < 2 or
        #by_tier[facets.FINAL] < 1 then
        error("Demonspawn facet catalog lacks a complete selection")
    end

    return by_tier
end

-- The source chooses distinct facets while rejecting reused equipment
-- slots. Filtering a tier before drawing preserves its uniform choice.
local function pick(ctx, pool, used_facets, used_slots)
    local eligible = {}

    for _, definition in ipairs(pool) do
        if not used_facets[definition.id] and
            (not definition.body_slot or
                not used_slots[definition.body_slot]) then
            eligible[#eligible + 1] = definition
        end
    end

    if #eligible == 0 then
        error("Demonspawn facet selection has no eligible candidate")
    end

    local chosen = eligible[ctx:random(streams.DEMONSPAWN,
        #eligible) + 1]

    used_facets[chosen.id] = true

    if chosen.body_slot then
        used_slots[chosen.body_slot] = true
    end

    return chosen
end

-- Rejection checks are over whole selected facets. Ignite Blood can
-- conflict with Condensation Shield and Foul Stench in separate ways.
local function compatible(selected)
    local elemental = 0
    local clouds = 0
    local mutation_counts = {}

    for _, definition in ipairs(selected) do
        if definition.elemental then
            elemental = elemental + 1
        end

        if definition.cloud_producing then
            clouds = clouds + 1
        end

        -- Separate mod files may share a mutation ID. Reject their joint
        -- schedule before it can reach a later XL with no legal rank left.
        for _, id in ipairs(definition.mutations) do
            mutation_counts[id] = (mutation_counts[id] or 0) + 1

            if mutation_counts[id] > catalog.get(categories.MUTATIONS,
                id).max_level then
                return false
            end
        end
    end

    return elemental <= 1 and clouds <= 1
end

-- Source selects the highest tier first and retries an entire group when
-- the two environmental exclusion rules clash.
local function select_facets(ctx, by_tier)
    local monstrous = ctx:random(streams.DEMONSPAWN, 10) == 0
    local counts = {
        [facets.BODY] = monstrous and 3 or required[facets.BODY],
        [facets.SCALE] = monstrous and 0 or required[facets.SCALE],
        [facets.SECONDARY] = required[facets.SECONDARY],
        [facets.FINAL] = required[facets.FINAL],
    }

    for _ = 1, 1000 do
        local selected = {}
        local used_facets = {}
        local used_slots = {}

        for tier = facets.FINAL, facets.BODY, -1 do
            for _ = 1, counts[tier] do
                selected[#selected + 1] = pick(ctx,
                    by_tier[tier], used_facets, used_slots)
            end
        end

        if compatible(selected) then
            return selected
        end
    end

    error("Demonspawn facets cannot satisfy source exclusions")
end

-- Compare the unique source timing slot assigned to each grant.
local function earlier_grant(left, right)
    return left.time < right.time
end

-- Give each grant a unique source timing slot. Sorting slots after swaps
-- preserves rank order inside a facet even when random times reverse it.
local function order_grants(ctx, selected)
    local grants = {}
    local occupied = {}

    for _, definition in ipairs(selected) do
        for rank = 1, 3 do
            local window = definition.windows[rank]
            local first = math.max(0, window)
            local last = math.min(100, window + 100)
            local time

            -- A broken scripted RNG must fail clearly instead of keeping
            -- character creation in an unbounded collision loop.
            for _ = 1, 1000 do
                time = 10 * first + ctx:random(streams.DEMONSPAWN,
                    10 * (last - first))

                if not occupied[time] then
                    break
                end
            end

            if occupied[time] then
                error("Demonspawn timing RNG repeated one slot")
            end

            occupied[time] = true
            grants[#grants + 1] = {
                facet = definition,
                rank = rank,
                time = time,
            }

            local index = #grants

            while index > 1 and grants[index - 1].facet == definition and
                grants[index].time < grants[index - 1].time do
                grants[index].time, grants[index - 1].time =
                    grants[index - 1].time, grants[index].time
                index = index - 1
            end
        end
    end

    table.sort(grants, earlier_grant)

    return grants
end

-- The source walks XL2–27, always assigning the first grant at XL2 and
-- otherwise drawing in proportion to remaining grants and level slots.
local function assign_levels(ctx, grants)
    local next_grant = 1

    for level = 2, 27 do
        if next_grant > #grants then
            break
        end

        local remaining = #grants - next_grant + 1
        local slots = 28 - level

        if level == 2 or
            ctx:random(streams.DEMONSPAWN, slots) < remaining then
            grants[next_grant].level = level
            next_grant = next_grant + 1
        end
    end

    if next_grant <= #grants then
        error("Demonspawn level schedule left grants unassigned")
    end
end

-- Compare levels instead of ECS entity IDs, which can change on restore.
local function earlier_trait(left, right)
    return left.state.level < right.state.level
end

-- Read only this player's records; sorting by scheduled level makes every
-- consumer independent of ECS entity order and save serialization order.
function demonspawn.list(ctx, player)
    local found = {}

    for _, entity in ipairs(ctx:query({
        component.DEMONSPAWN_TRAIT,
    })) do
        local state = ctx:get(entity, component.DEMONSPAWN_TRAIT)

        if state.owner == player then
            found[#found + 1] = {
                entity = entity,
                state = state,
            }
        end
    end

    table.sort(found, earlier_trait)

    return found
end

-- Other rules, including Ru, ask whether the future plan contains a
-- mutation without knowing the schema or whether it has been granted.
function demonspawn.has(ctx, player, mutation_id)
    for _, entry in ipairs(demonspawn.list(ctx, player)) do
        if entry.state.mutation_id == mutation_id then
            return true
        end
    end

    return false
end

-- Roll exactly once for a Demonspawn. Human and other species must never
-- acquire hidden trait entities from this owner.
function demonspawn.start(ctx, player)
    local identity = ctx:get(player, component.PLAYER)

    if not identity then
        error("Demonspawn schedule requires player identity")
    end

    if identity.species_id ~= species.SP_DEMONSPAWN then
        return
    end

    if #demonspawn.list(ctx, player) > 0 then
        error("Demonspawn schedule already exists")
    end

    if ctx:has(player, component.DEMONSPAWN_ANCESTRY) then
        error("Demonspawn ancestry already exists")
    end

    local selected = select_facets(ctx, pools())
    local grants = order_grants(ctx, selected)

    assign_levels(ctx, grants)

    ctx:add(player, component.DEMONSPAWN_ANCESTRY, {
        highest_level = 1,
    })

    for _, grant in ipairs(grants) do
        local entity = ctx:create()

        ctx:add(entity, component.DEMONSPAWN_TRAIT, {
            owner = player,
            facet_id = grant.facet.id,
            rank_index = grant.rank,
            mutation_id = grant.facet.mutations[grant.rank],
            level = grant.level,
            granted = false,
        })
    end
end

-- A level's future grant is permanent. The flag is historical, so Ru's
-- Experience loss and a later return to this XL do not grant it twice.
function demonspawn.grant_level(ctx, player, level)
    local history = ctx:get(player, component.DEMONSPAWN_ANCESTRY)

    if not history then
        return
    end

    local gained = false

    for _, entry in ipairs(demonspawn.list(ctx, player)) do
        local trait = entry.state

        if trait.level == level and not trait.granted then
            local completed = false

            for _ = 1, 100 do
                local result = mutation_transition.grant(ctx, player,
                    trait.mutation_id, mutation_classes.INNATE, true)

                if result.kind == "granted" or
                    result.kind == "permanent" then
                    completed = true
                    break
                end

                if result.kind ~= "traded" then
                    error("Demonspawn trait was blocked: " ..
                        trait.mutation_id)
                end
            end

            if not completed then
                error("Demonspawn trait exhausted conflicts: " ..
                    trait.mutation_id)
            end

            trait.granted = true
            ctx:set(entry.entity, component.DEMONSPAWN_TRAIT, trait)
            gained = true
        end
    end

    if gained then
        ctx:emit("mutation", "Your demonic ancestry asserts itself...")
    end

    history.highest_level = math.max(history.highest_level, level)
    ctx:set(player, component.DEMONSPAWN_ANCESTRY, history)
end

-- Confirm one saved plan's facet shapes and level ownership on restore.
-- A mutation may repeat across three ranks but each rank and XL is unique.
function demonspawn.validate(ctx, player, species_id, level)
    -- During save validation this is the sole player. A trait attached
    -- elsewhere must not disappear behind the owner-filtered list.
    if level then
        for _, entity in ipairs(ctx:query({
            component.DEMONSPAWN_TRAIT,
        })) do
            local trait = ctx:get(entity, component.DEMONSPAWN_TRAIT)

            if trait.owner ~= player then
                error("foreign Demonspawn ancestry record")
            end
        end
    end

    local entries = demonspawn.list(ctx, player)
    local history = ctx:get(player, component.DEMONSPAWN_ANCESTRY)

    if species_id ~= species.SP_DEMONSPAWN then
        if #entries > 0 or history then
            error("non-Demonspawn has scheduled ancestry")
        end

        return
    end

    if #entries ~= 15 and #entries ~= 18 then
        error("Demonspawn has incomplete ancestry")
    end

    if not history or history.highest_level < 1 or
        history.highest_level > 27 or
        level and history.highest_level < level then
        error("invalid Demonspawn ancestry history")
    end

    if entries[1].state.level ~= 2 then
        error("Demonspawn ancestry lacks XL2 grant")
    end

    local by_facet = {}
    local seen_levels = {}
    local tier_counts = {}
    local used_slots = {}
    local selected = {}
    local granted = {}

    for _, entry in ipairs(entries) do
        local trait = entry.state
        local definition = catalog.get(categories.DEMONSPAWN_FACETS,
            trait.facet_id)

        validate_definition(definition)

        if trait.rank_index < 1 or trait.rank_index > 3 or
            trait.level < 2 or trait.level > 27 or
            seen_levels[trait.level] or
            trait.mutation_id ~= definition.mutations[trait.rank_index] then
            error("invalid Demonspawn scheduled grant")
        end

        if trait.granted ~= (trait.level <= history.highest_level) then
            error("Demonspawn grant flag disagrees with level history")
        end

        if trait.granted then
            granted[trait.mutation_id] =
                (granted[trait.mutation_id] or 0) + 1
        end

        seen_levels[trait.level] = true
        local ranks = by_facet[trait.facet_id]

        if not ranks then
            ranks = {}
            by_facet[trait.facet_id] = ranks
            selected[#selected + 1] = definition
            tier_counts[definition.tier] =
                (tier_counts[definition.tier] or 0) + 1

            if definition.body_slot then
                if used_slots[definition.body_slot] then
                    error("Demonspawn body facets share a slot")
                end

                used_slots[definition.body_slot] = true
            end
        end

        if ranks[trait.rank_index] then
            error("duplicate Demonspawn facet rank")
        end

        ranks[trait.rank_index] = trait.level
    end

    for _, ranks in pairs(by_facet) do
        if not ranks[1] or not ranks[2] or not ranks[3] or
            ranks[1] >= ranks[2] or ranks[2] >= ranks[3] then
            error("Demonspawn facet grants are out of order")
        end
    end

    local body_count = #entries == 18 and 3 or 1
    local scale_count = #entries == 18 and 0 or 1

    if tier_counts[facets.BODY] ~= body_count or
        (tier_counts[facets.SCALE] or 0) ~= scale_count or
        tier_counts[facets.SECONDARY] ~= 2 or
        tier_counts[facets.FINAL] ~= 1 or
        not compatible(selected) then
        error("Demonspawn ancestry has invalid facet selection")
    end

    if level then
        for id, count in pairs(granted) do
            local record = mutation_records.find(ctx, player, id)

            if not record or record.state.innate < count then
                error("Demonspawn trait lacks innate mutation " .. id)
            end
        end
    end
end

return demonspawn
