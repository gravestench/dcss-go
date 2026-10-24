local intent = require("constants.intent")
local registry = require("policy.abilities.registry")
local confusion = require("policy.magic.player_confusion")

local abilities = {}

-- Ability commands delegate preparation to the ability registry before action timing begins.
-- Example: abilities.prepare(ctx, player, { ability_id = abilities.HOP, dx = 1 }) preflights Hop.
function abilities.prepare(ctx, player, input)
    local id = input.ability_id
    local definition = registry.get(id)

    -- Purification is source-conf_ok: looking up the selected definition
    -- first lets it cure the same confusion that blocks other powers.
    if confusion.active(ctx, player) and
        (not definition or not definition.confusion_ok) then
        return { message = "You are too confused!" }
    end

    if not definition or
        (not registry.usable_now(ctx, player, definition) and
            not (input.cancelled and definition.owns_cancellation)) then
        return { message = "You do not have that ability." }
    end

    local rejection = definition.prepare(ctx, player, input)

    -- A replayed cancellation gives an ability a chance to clear its saved
    -- prompt. Ordinary confirmations need no cleanup and simply end here.
    if input.cancelled and not definition.owns_cancellation and
        (rejection == nil or
            (type(rejection) == "table" and
                rejection.confirmation)) then
        return { message = "Okay." }
    end

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
            item_id = input.item_id,
            target_id = input.target_id,
            spell_id = input.spell_id,
            forced = input.forced or false,
        },
        cost = 10,
    }
end

return abilities
