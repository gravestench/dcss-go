-- Source: traps.cc:652-697. Permanent webs remain after a victim escapes.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flight = require("policy.combat.flight")
local held = require("policy.traps.held")
local streams = require("constants.rng_streams")

local effect = {}

local function immune(ctx, actor)
    if flight.active(ctx, actor) then
        return true
    end

    if actor == ctx:player() then
        return false
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get("monsters", state.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == "M_INSUBSTANTIAL" or flag == "M_WEB_IMMUNE" then
            return true
        end
    end

    return false
end

function effect.trigger(ctx, _, actor)
    if immune(ctx, actor) then
        return
    end

    if ctx:random(streams.TRAPS, 3) == 0 then
        if actor == ctx:player() then
            ctx:emit("trap", "You pick your way through the web.")
        end

        return
    end

    if held.catch_web(ctx, actor) then
        if actor == ctx:player() then
            ctx:emit("trap", "You are caught in the web!")
        else
            ctx:emit("trap", "A monster is caught in a web!")
        end
    end
end

return effect
