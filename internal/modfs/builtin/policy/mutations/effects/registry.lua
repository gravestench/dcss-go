local catalog = require("policy.catalog")
local levels = require("policy.mutations.levels")
local records = require("policy.mutations.records")
local capabilities = require("constants.mutation_capabilities")

local effects = {}
local registered = {}
local known_capabilities = {}
local event_capabilities = {
    [capabilities.AFTER_MONSTER_DAMAGE] = true,
    [capabilities.AFTER_MELEE_HIT] = true,
    [capabilities.ON_MELEE_ATTEMPT] = true,
}

for _, capability in pairs(capabilities) do
    known_capabilities[capability] = true
end

-- Example: adding a second handler for the same mutation capability fails at registration.
-- Validate the whole handler set before storing any entry so a failed mod
-- registration cannot leave half of a mutation's effects installed.
function effects.add(mutation_id, handlers)
    catalog.get("mutations", mutation_id)

    if type(handlers) ~= "table" or next(handlers) == nil then
        error("mutation " .. mutation_id .. " has no effect handlers")
    end

    local existing = registered[mutation_id] or {}

    for capability, handler in pairs(handlers) do
        if not known_capabilities[capability] or type(handler) ~= "function" then
            error("mutation " .. mutation_id .. " has invalid capability " ..
                tostring(capability))
        end

        if existing[capability] then
            error("duplicate mutation capability " .. mutation_id .. "/" ..
                capability)
        end
    end

    for capability, handler in pairs(handlers) do
        existing[capability] = handler
    end

    registered[mutation_id] = existing
end

-- Return the registered handlers directly because dispatch needs the same
-- functions installed during mod loading, without rebuilding a lookup table.
function effects.get(mutation_id)
    return registered[mutation_id]
end

-- Sum one numeric capability across owned mutations. The supplied level
-- reader lets callers choose effective, base, or full levels without copying
-- the dispatch rules or accidentally treating event handlers as numbers.
local function sum(ctx, owner, capability, level_of, subject)
    if not known_capabilities[capability] or
        capability == capabilities.ON_CHANGE or
        event_capabilities[capability] then
        error("unknown mutation capability " .. tostring(capability))
    end

    local total = 0

    for _, entry in ipairs(records.list(ctx, owner)) do
        local mutation_id = entry.state.mutation_id
        local handler = registered[mutation_id] and
            registered[mutation_id][capability]

        if handler then
            local level = level_of(ctx, owner, mutation_id)

            if level > 0 then
                total = total + handler(level, ctx, owner, subject)
            end
        end
    end

    return total
end

-- Dispatch event effects at effective levels, so suppressed mutations do not
-- react to combat events even while their underlying records remain present.
function effects.trigger(ctx, owner, capability, subject)
    if not event_capabilities[capability] then
        error("unknown mutation event " .. tostring(capability))
    end

    for _, entry in ipairs(records.list(ctx, owner)) do
        local mutation_id = entry.state.mutation_id
        local handler = registered[mutation_id] and
            registered[mutation_id][capability]

        if handler then
            local level = levels.effective(ctx, owner, mutation_id)

            if level > 0 then
                handler(level, ctx, owner, subject)
            end
        end
    end
end

-- Most game queries use effective levels, which account for temporary
-- suppression; the common sum helper performs the actual handler traversal.
function effects.sum(ctx, owner, capability, subject)
    return sum(ctx, owner, capability, levels.effective, subject)
end

-- Source stat modifiers use base mutation levels even when a form suppresses
-- other consequences of that mutation.
function effects.base_sum(ctx, owner, capability)
    return sum(ctx, owner, capability, levels.base)
end

-- Full levels include temporary and permanent mutation contributions when a
-- rule needs the total independent of current activity restrictions.
function effects.full_sum(ctx, owner, capability)
    return sum(ctx, owner, capability, levels.full)
end

-- Notify the changed mutation after vitals exist. Starting mutations are
-- recorded earlier, so dispatching their resource recalculation then would
-- read components that character creation has not installed yet.
function effects.changed(ctx, owner, mutation_id)
    -- Starting mutations are recorded before live resources exist. Once the
    -- player has health, changes must update derived resources immediately.
    if not ctx:get(owner, "core.health") then
        return
    end

    local handlers = registered[mutation_id]
    local handler = handlers and handlers[capabilities.ON_CHANGE]

    if handler then
        handler(ctx, owner)
    end
end

-- Find active mutations without any behavior provider, including providers
-- outside this registry. Checking all providers keeps legitimate combat and
-- ability mutations from being reported as empty definitions.
function effects.missing()
    local missing = {}
    local abilities = require("policy.abilities.registry")
    local auxiliary = require("policy.combat.auxiliary")
    local kill_effects = require("policy.combat.player_kill_effects")
    local melee_reactions = require("policy.combat.player_reactions")
    local damage_reactions = require("policy.combat.player_damage_reactions")
    local evolution = require("policy.mutations.evolution")

    for _, definition in ipairs(catalog.all("mutations")) do
        if definition.status == "active" and
            not registered[definition.id] and
            not abilities.has_mutation(definition.id) and
            not auxiliary.has_mutation(definition.id) and
            not kill_effects.has_mutation(definition.id) and
            not melee_reactions.has_mutation(definition.id) and
            not damage_reactions.has_mutation(definition.id) and
            not evolution.has_mutation(definition.id) then
            missing[#missing + 1] = definition.id
        end
    end

    return missing
end

-- Fail bootstrap on the first behaviorless active mutation and report its
-- defining mod file, so authors can repair the definition before play starts.
function effects.validate()
    local missing = effects.missing()

    if #missing > 0 then
        local id = missing[1]
        local origin = register.origin("mutations", id)

        error(origin .. ": mutation " .. id .. " has no behavior")
    end
end

return effects
