local intent = require("constants.intent")
local registry = require("policy.abilities.registry")

local abilities = {}

-- Ability commands delegate preparation to the ability registry before action timing begins.
-- Example: abilities.prepare(ctx, player, { ability_id = abilities.HOP, dx = 1 }) preflights Hop.
function abilities.prepare(ctx, player, input)
    local id = input.ability_id
    local definition = registry.get(id)

    if not definition or not registry.usable_now(ctx, player, definition) then
        return { message = "You do not have that ability." }
    end

    local rejection = definition.prepare(ctx, player, input)

    -- An ability may request another free confirmation before it creates an
    -- intent. Renunciation uses two source prompts with one shared bridge.
    if type(rejection) == "table" then
        return rejection
    end

    if rejection then
        return { message = rejection }
    end

    return {
        intent = {
            kind = intent.PLAYER_ABILITY,
            ability_id = id,
            dx = input.dx or 0,
            dy = input.dy or 0,
            forced = input.forced or false,
        },
        cost = 10,
    }
end

return abilities
