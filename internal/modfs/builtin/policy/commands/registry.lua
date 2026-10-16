local intent = require("constants.intent")

local registry = {}
local handlers = {}

function registry.register(kind, prepare)
    if type(kind) ~= "number" or type(prepare) ~= "function" then
        error("command registration needs a kind and prepare function")
    end

    if handlers[kind] then
        error("duplicate command kind " .. kind)
    end

    handlers[kind] = prepare
end

function registry.wait(message)
    local decision = {
        intent = {
            kind = intent.WAIT,
        },
        cost = 10,
    }

    if message then
        decision.events = {
            {
                kind = "status",
                text = message,
            },
        }
    end

    return decision
end

function registry.dispatch(kind, ctx, player, input, position, delay)
    local prepare = handlers[kind]

    if not prepare then
        return {
            message = "Unknown command.",
        }
    end

    return prepare(ctx, player, input, position, delay)
end

return registry
