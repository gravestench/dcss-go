local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local ids = require("ids.traps")
local streams = require("constants.rng_streams")

local placement = {}

-- Include the vault source and glyph in errors so a bad trap token can be located.
local function site_name(record)
    return string.format("vault %s:%d glyph %s",
        record.source_id, record.line or 0, record.source)
end

-- Match authored names against registered aliases before choosing a kind.
local function matches(definition, name)
    if definition.name:lower() == name:lower() or
        definition.id == name or definition.source_feature == name then
        return true
    end

    for _, alias in ipairs(definition.vault_names or {}) do
        if alias:lower() == name:lower() then
            return true
        end
    end

    return false
end

-- Resolve an explicit vault trap before random alternatives.
local function named_trap(name, record)
    for _, definition in ipairs(catalog.all(categories.TRAPS)) do
        if matches(definition, name) then
            return definition.id
        end
    end

    if name:lower():find("trap", 1, true) then
        error(site_name(record) .. ": unknown trap " .. name)
    end

    return nil
end

-- Recognize random and named trap directives before the vault builder instantiates a feature.
-- Example: placement.is_trap(vault_record) distinguishes trap directives from other feature records.
function placement.is_trap(record)
    if record.identity == "random_trap" then
        return true
    end

    for part in (record.identity .. "/"):gmatch("(.-)/") do
        local name = part:match("^%s*(.-)%s+w:%d+%s*$") or
            part:match("^%s*(.-)%s*$")

        if name:lower():find("trap", 1, true) then
            return true
        end

        for _, definition in ipairs(catalog.all(categories.TRAPS)) do
            if matches(definition, name) then
                return true
            end
        end
    end

    return false
end

-- Split vault alternatives while retaining the authored record for diagnostics.
local function alternatives(expression, record)
    local choices = {}

    for part in (expression .. "/"):gmatch("(.-)/") do
        local text = part:match("^%s*(.-)%s*$")
        local name, weight = text:match("^(.-)%s+w:(%d+)$")

        name = name or text
        weight = tonumber(weight) or 10

        if name == "" or weight < 1 then
            error(site_name(record) .. ": invalid trap choice " .. text)
        end

        choices[#choices + 1] = {
            id = named_trap(name, record),
            name = name,
            weight = weight,
        }
    end

    return choices
end

-- A single authored trap spends no RNG; slash alternatives consume one weighted trap-stream draw.
local function choose(ctx, choices)
    if #choices == 1 then
        return choices[1].id, choices[1].name
    end

    local total = 0

    for _, choice in ipairs(choices) do
        total = total + choice.weight
    end

    local draw = ctx:random(streams.TRAPS, total)

    for _, choice in ipairs(choices) do
        if draw < choice.weight then
            return choice.id, choice.name
        end

        draw = draw - choice.weight
    end

    error("trap choice fell outside weighted table")
end

-- Fix charges when placing a chosen trap so later activation has no placement draw.
function placement.resolve(ctx, record, depth)
    local expression = record.identity

    if expression == "random_trap" then
        local choices = {}

        -- dungeon.cc repeatedly draws until it finds a regular trap.
        -- The accepted distribution is uniform over this effective set.
        for _, definition in ipairs(catalog.all(categories.TRAPS)) do
            if definition.regular and
                (definition.id ~= ids.TRAP_SHAFT or depth < 2) then
                choices[#choices + 1] = {
                    id = definition.id,
                    name = definition.id,
                    weight = 1,
                }
            end
        end

        if #choices == 0 then
            error(site_name(record) .. ": no eligible regular trap")
        end

        return choose(ctx, choices)
    end

    return choose(ctx, alternatives(expression, record))
end

-- Materialization verifies walkability and cell uniqueness before writing a WORLD_TRAP component.
function placement.materialize(ctx, level, record)
    if not ctx:walkable(level.id, record.x, record.y) then
        error(site_name(record) .. ": trap cell is blocked")
    end

    local kind_id = placement.resolve(ctx, record, level.id)

    if not kind_id then
        return nil
    end

    for _, entity in ipairs(ctx:query({ component.WORLD_TRAP })) do
        local trap = ctx:get(entity, component.WORLD_TRAP)

        if trap.level_id == level.id and trap.x == record.x and
            trap.y == record.y then
            error(site_name(record) .. ": duplicate trap cell")
        end
    end

    local entity = ctx:create()
    local definition = catalog.get(categories.TRAPS, kind_id)
    local charges = definition.one_shot and 1 or 0

    if definition.lifetime_turns then
        local lifetime = definition.lifetime_turns

        charges = lifetime.minimum + ctx:random(streams.TRAPS, lifetime.random)
    end

    local position = {
        level_id = level.id,
        x = record.x,
        y = record.y,
    }

    ctx:add(entity, component.POSITION, position)
    ctx:add(entity, component.WORLD_TRAP, {
        kind_id = kind_id,
        level_id = level.id,
        x = record.x,
        y = record.y,
        charges = charges,
        revealed = true,
        source_record = record.source_id .. ":" .. record.index,
    })

    return kind_id
end

return placement
