-- Source gates keep their historical order. New Lua events join that order
-- by an explicit stage, so file names and VFS traversal cannot change RNG.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local source_ids = require("ids.xom_events")

local selection_mods = {}
local built_in = {}

-- Only newly declared events need a selector. Replacing a source event's
-- definition already changes its effect without changing its source gate.
for _, id in pairs(source_ids) do
    built_in[id] = true
end

-- Build an ephemeral priority view from the effective catalog. Nothing is
-- cached across games, and a stage shared with source rules runs after them.
local function ordered(side, gates)
    local stages = {}
    local at_stage = {}

    for stage in pairs(gates) do
        stages[#stages + 1] = stage
    end

    for _, definition in ipairs(catalog.all(categories.XOM_EVENTS)) do
        local active = definition.status ~= "removed" and
            definition.status ~= "enum_only"

        if active and definition.side == side and
            not built_in[definition.id] then
            local stage = definition.selection_stage
            local module = definition.selector_module

            if type(stage) ~= "number" or stage < 1 or
                stage ~= math.floor(stage) then
                error("Xom event " .. definition.id ..
                    " needs a positive integer selection_stage")
            end

            if type(module) ~= "string" or module == "" then
                error("Xom event " .. definition.id ..
                    " needs a selector_module")
            end

            if not at_stage[stage] then
                at_stage[stage] = {}
                stages[#stages + 1] = stage
            end

            at_stage[stage][#at_stage[stage] + 1] = definition
        end
    end

    table.sort(stages)

    return stages, at_stage
end

-- Each candidate pays its own chance only after earlier gates fail. Stable
-- catalog ID order breaks ties between mod events at the same stage.
function selection_mods.choose(ctx, player, state,
    severity, tension, stream, side, gates)
    local stages, at_stage = ordered(side, gates)

    for _, stage in ipairs(stages) do
        local gate = gates[stage]
        local chosen = gate and gate(ctx, player, state,
            severity, tension, stream)

        if chosen then
            return chosen
        end

        for _, definition in ipairs(at_stage[stage] or {}) do
            local selector = require(definition.selector_module)

            if type(selector) ~= "table" or
                type(selector.eligible) ~= "function" then
                error("Xom event " .. definition.id ..
                    " needs a Lua eligible function")
            end

            if selector.eligible(ctx, player, state,
                severity, tension, stream) then
                return definition.id
            end
        end
    end
end

return selection_mods
