local intent = require("constants.intent")
local registry = require("policy.abilities.registry")

local abilities = {}

function abilities.prepare(ctx, player, input)
    local id = input.ability_id
    local definition = registry.get(id)

    if not definition or not registry.usable_now(ctx, player, definition) then
        return { message = "You do not have that ability." }
    end

    local rejection = definition.prepare(ctx, player, input)

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
