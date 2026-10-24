-- Xom's action selector names events; this owner resolves the effective
-- layered definition and its Lua effect without a content-ID switch.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local sides = require("constants.xom_sides")

local events = {}

-- Validate a definition at the point it is used. Mods can replace a file
-- without recompiling the engine, so a malformed replacement must fail by
-- its own ID rather than becoming a silent no-op in the action loop.
function events.get(event_id)
    local definition = catalog.get(categories.XOM_EVENTS, event_id)

    if definition.side ~= sides.GOOD and
        definition.side ~= sides.BAD then
        error("Xom event " .. event_id .. " has no valid side")
    end

    if type(definition.effect_module) ~= "string" or
        definition.effect_module == "" then
        error("Xom event " .. event_id .. " has no effect module")
    end

    local effect = require(definition.effect_module)

    if type(effect) ~= "table" or
        type(effect.apply) ~= "function" then
        error("Xom event " .. event_id .. " has no Lua apply function")
    end

    return definition, effect
end

-- Pass the chosen ID to a focused effect family. Several source events
-- share mechanics but keep separate definitions, messages, and mod paths.
function events.apply(ctx, player, event_id, severity, request)
    local _, effect = events.get(event_id)

    return effect.apply(ctx, player, event_id, severity, request)
end

return events
