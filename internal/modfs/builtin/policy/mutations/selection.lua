local catalog = require("policy.catalog")
local uses = require("constants.mutation_uses")
local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local categories = require("constants.catalog")
local mutations = require("ids.mutations")
local physiology = require("policy.mutations.physiology")
local levels = require("policy.mutations.levels")
local records = require("policy.mutations.records")
local mutation_enum = require("data.mutation_enum")

local selection = {}

-- Read declared use tags so a definition enters only the requested mutation pool.
local function has_use(definition, wanted)
    for _, use in ipairs(definition.uses) do
        if use == wanted then
            return true
        end
    end

    return false
end

-- GOOD and BAD use authored weights; god-specific pools use unit weights.
local function weight(definition, wanted)
    if definition.status ~= "active" or not has_use(definition, wanted) then
        return 0
    end

    if wanted == uses.GOOD or wanted == uses.BAD then
        return definition.weight
    end

    return 1
end

-- Example: a GOOD mutation draw weights active candidates, then consumes one mutation-stream roll.
-- Source: mutation.cc:_get_mut_with_use. Weight determines probability; the
-- catalog traverses stable IDs so file loading cannot change a seeded draw.
function selection.weighted(ctx, wanted)
    local definitions = catalog.all("mutations")
    local total = 0

    for _, definition in ipairs(definitions) do
        total = total + weight(definition, wanted)
    end

    if total <= 0 then
        error("mutation use " .. tostring(wanted) .. " has no candidates")
    end

    local drawn = ctx:random("mutation", total)

    for _, definition in ipairs(definitions) do
        drawn = drawn - weight(definition, wanted)

        if drawn < 0 then
            return definition.id
        end
    end

    error("mutation weighted selection exhausted")
end

-- Source: mutation.cc:_accept_mutation. Category draws ignore the second
-- weight gate, while Xom's raw-enum path uses it.
function selection.accept(ctx, owner, mutation_id, class, ignore_weight)
    local definition = register.get(categories.MUTATIONS, mutation_id)

    if definition.status ~= "active" or
        not physiology.permitted(ctx, owner, mutation_id) or
        levels.base(ctx, owner, mutation_id) >= definition.max_level then
        return false
    end

    if class == classes.TEMPORARY and
        mutation_id == mutations.MUT_DEVOLUTION then
        return false
    end

    if ignore_weight then
        return true
    end

    if definition.weight == 0 then
        return false
    end

    local entry = records.find(ctx, owner, mutation_id)
    local innate = entry and entry.state.innate or 0

    return ctx:random("mutation", 10) < definition.weight + innate
end

-- Resolve ANY with a three-in-five good draw before sampling a concrete mutation.
local function use_for_choice(ctx, choice)
    if choice == choices.ANY then
        return ctx:random("mutation", 5) < 3 and uses.GOOD or uses.BAD
    end

    if choice == choices.GOOD then
        return uses.GOOD
    end

    if choice == choices.BAD or choice == choices.CORRUPT then
        return uses.BAD
    end

    if choice == choices.JIYVA then
        return uses.JIYVA
    end

    if choice == choices.QAZLAL then
        return uses.QAZLAL
    end

    error("unsupported random mutation choice " .. tostring(choice))
end

-- Source: mutation.cc:_get_random_mutation retries at most 100 draws.
function selection.choose(ctx, owner, choice, class)
    if choice == choices.XOM then
        return selection.choose_xom(ctx, owner)
    end

    local wanted = use_for_choice(ctx, choice)

    for _ = 1, 100 do
        local mutation_id = selection.weighted(ctx, wanted)

        if selection.accept(ctx, owner, mutation_id, class, true) then
            return mutation_id
        end
    end

    return nil
end

-- Source: mutation.cc:_get_random_xom_mutation. Xom samples the actual
-- mutation enum first, occasionally substitutes a unit-weight Xom mutation,
-- and checks the normal acquisition-weight gate before accepting it.
function selection.choose_xom(ctx, owner)
    while true do
        local index = ctx:random("mutation", #mutation_enum) + 1
        local mutation_id = mutation_enum[index]

        if ctx:random("mutation", 1000) == 0 then
            return nil
        end

        if ctx:random("mutation", 5) == 0 then
            mutation_id = selection.weighted(ctx, uses.XOM)
        end

        if selection.accept(ctx, owner, mutation_id,
            classes.ACQUIRED, false) then
            return mutation_id
        end
    end
end

-- Map deletion categories to use filters; ANY intentionally accepts every acquired ID.
local function deletion_use(choice)
    if choice == choices.ANY then
        return nil
    end

    if choice == choices.GOOD then
        return uses.GOOD
    end

    if choice == choices.BAD or choice == choices.CORRUPT then
        return uses.BAD
    end

    if choice == choices.JIYVA then
        return uses.JIYVA
    end

    if choice == choices.QAZLAL then
        return uses.QAZLAL
    end

    if choice == choices.XOM then
        return uses.XOM
    end

    error("unsupported mutation deletion choice " .. tostring(choice))
end

-- Source: mutation.cc:_concretize_mut_deletion. Acquired mutation IDs are
-- selected uniformly by reservoir sampling, regardless of their levels or
-- acquisition weights. Form appendages live outside mutation records.
function selection.choose_removable(ctx, owner, choice)
    local wanted = deletion_use(choice)
    local acquired = {}
    local seen = 0
    local chosen

    for _, entry in ipairs(records.list(ctx, owner)) do
        acquired[entry.state.mutation_id] = entry.state.acquired
    end

    for _, definition in ipairs(catalog.all("mutations")) do
        if (acquired[definition.id] or 0) > 0 and
            (not wanted or has_use(definition, wanted)) then
            seen = seen + 1

            if ctx:random("mutation", seen) == 0 then
                chosen = definition.id
            end
        end
    end

    return chosen
end

return selection
