local catalog = require("policy.catalog")
local classes = require("constants.mutation_classes")

local records = {}
local component_id = "character.mutation"
local timer_id = "character.mutation_timer"

-- Read the one XP expiry clock shared by all temporary mutation ranks.
function records.timer(ctx, owner)
    return ctx:get(owner, timer_id)
end

-- Update an existing timer or create it on first temporary grant.
function records.set_timer(ctx, owner, remaining_xp)
    local timer = records.timer(ctx, owner)
    local value = { remaining_xp = remaining_xp }

    if timer then
        ctx:set(owner, timer_id, value)
    else
        ctx:add(owner, timer_id, value)
    end
end

-- Filter mutation entities by owner so rank operations cannot borrow another actor’s record.
function records.list(ctx, owner)
    local found = {}

    for _, entity in ipairs(ctx:query({ component_id })) do
        local state = ctx:get(entity, component_id)

        if state.owner == owner then
            found[#found + 1] = {
                entity = entity,
                state = state,
            }
        end
    end

    return found
end

-- Sum temporary ranks across owned IDs before deciding whether the shared timer remains live.
function records.temporary_count(ctx, owner)
    local total = 0

    for _, entry in ipairs(records.list(ctx, owner)) do
        total = total + entry.state.temporary
    end

    return total
end

-- Return the first owned record for this ID; restore validation rejects duplicate entities.
function records.find(ctx, owner, mutation_id)
    for _, entry in ipairs(records.list(ctx, owner)) do
        if entry.state.mutation_id == mutation_id then
            return entry
        end
    end

    return nil
end

-- Require a positive integer for rank changes and temporary expiry progress.
local function valid_count(count)
    return type(count) == "number" and count >= 1 and count % 1 == 0
end

-- Enforce the catalog cap across all rank classes before writing the single mutation entity.
local function grant(ctx, owner, mutation_id, field, count, progress)
    if not valid_count(count) then
        error("mutation grant requires a positive integer count")
    end

    local definition = catalog.get("mutations", mutation_id)

    if definition.status ~= "active" then
        error("cannot grant removed mutation " .. mutation_id)
    end

    local entry = records.find(ctx, owner, mutation_id)
    local state = entry and entry.state or {
        owner = owner,
        mutation_id = mutation_id,
        innate = 0,
        acquired = 0,
        temporary = 0,
    }
    local total = state.innate + state.acquired + state.temporary + count

    if total > definition.max_level then
        error("mutation " .. mutation_id .. " exceeds source maximum")
    end

    state[field] = state[field] + count

    if field == classes.TEMPORARY and not valid_count(progress) then
        error("temporary mutation requires positive expiry progress")
    end

    if entry then
        ctx:set(entry.entity, component_id, state)
    else
        local entity = ctx:create()

        ctx:add(entity, component_id, state)
    end

    if field == classes.TEMPORARY then
        records.set_timer(ctx, owner, progress)
    end
end

-- Add inherited rank without invoking transition resistance or conflict rules.
function records.grant_innate(ctx, owner, id, count)
    grant(ctx, owner, id, classes.INNATE, count)
end

-- Add an acquired rank through the shared cap and owner checks.
function records.grant_acquired(ctx, owner, id, count)
    grant(ctx, owner, id, classes.ACQUIRED, count)
end

-- Example: a temporary grant increments its rank and sets expiry progress without replacing innate ranks.
-- Store expiry progress on the owner’s shared timer after adding temporary rank.
function records.grant_temporary(ctx, owner, id, count, progress)
    grant(ctx, owner, id, classes.TEMPORARY, count, progress)
end

-- Remove the entity at zero total rank and clear the timer after the last temporary rank.
function records.delete(ctx, owner, mutation_id, class, count)
    if class ~= classes.INNATE and class ~= classes.ACQUIRED and
        class ~= classes.TEMPORARY then
        error("unknown mutation class " .. tostring(class))
    end

    if not valid_count(count) then
        error("mutation deletion requires a positive integer count")
    end

    local entry = records.find(ctx, owner, mutation_id)

    if not entry or entry.state[class] < count then
        error("mutation " .. mutation_id .. " lacks " .. class .. " levels")
    end

    local state = entry.state
    state[class] = state[class] - count

    if state.innate + state.acquired + state.temporary == 0 then
        ctx:remove(entry.entity, component_id)
    else
        ctx:set(entry.entity, component_id, state)
    end

    if class == classes.TEMPORARY and records.temporary_count(ctx, owner) == 0 then
        records.set_timer(ctx, owner, 0)
    end
end

-- Source: species.cc:give_basic_mutations writes XL1 innate levels without
-- mutation messages or conflict resolution.
function records.grant_starting(ctx, owner, species)
    for _, entry in ipairs(species.mutations or {}) do
        if entry.level == 1 and entry.amount > 0 then
            records.grant_innate(ctx, owner, entry.id, entry.amount)
        end
    end
end

-- Check record ownership, species innate minima, caps, and timer consistency on restore.
function records.validate(ctx, owner, species, level)
    local seen = {}
    local expected_innate = {}
    local temporary_total = 0

    for _, scheduled in ipairs(species.mutations or {}) do
        if scheduled.level <= level and scheduled.amount > 0 then
            expected_innate[scheduled.id] =
                (expected_innate[scheduled.id] or 0) + scheduled.amount
        end
    end

    for _, entity in ipairs(ctx:query({ component_id })) do
        local state = ctx:get(entity, component_id)
        local id = state.mutation_id

        if state.owner ~= owner or id == "" or seen[id] then
            error("mutation record has invalid owner or duplicate ID")
        end

        local definition = catalog.get("mutations", id)
        local total = state.innate + state.acquired + state.temporary

        if total < 1 or total > definition.max_level or
            state.innate < 0 or state.acquired < 0 or
            state.temporary < 0 then
            error("invalid mutation levels for " .. id)
        end

        temporary_total = temporary_total + state.temporary

        -- Species grants are the minimum innate levels. Permanent mutation
        -- gains from later gameplay or mods may add more levels.
        if state.innate < (expected_innate[id] or 0) then
            error("invalid innate mutation levels for " .. id)
        end

        seen[id] = true
    end

    for id in pairs(expected_innate) do
        if not seen[id] then
            error("missing innate mutation " .. id)
        end
    end

    local timer = records.timer(ctx, owner)

    if (temporary_total > 0 and not timer) or
        (temporary_total == 0 and timer and timer.remaining_xp ~= 0) then
        error("invalid shared temporary mutation timer")
    end
end

return records
