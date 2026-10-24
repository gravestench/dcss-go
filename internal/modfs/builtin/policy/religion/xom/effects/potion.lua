-- Xom's good potion action invokes an existing potion effect without an
-- inventory item. The weighted source pool includes rare Experience, which
-- also guarantees the eligibility loop can eventually make a valid choice.
local channels = require("constants.message_channels")
local event_ids = require("ids.xom_events")
local items = require("ids.items")
local potions = require("policy.potions")
local streams = require("constants.rng_streams")

local effect = {}

local choices = {
    {
        id = items.POT_CURING,
        weight = 10,
    },

    {
        id = items.POT_HEAL_WOUNDS,
        weight = 10,
    },

    {
        id = items.POT_MAGIC,
        weight = 10,
    },

    {
        id = items.POT_HASTE,
        weight = 10,
    },

    {
        id = items.POT_MIGHT,
        weight = 10,
    },

    {
        id = items.POT_BRILLIANCE,
        weight = 10,
    },

    {
        id = items.POT_INVISIBILITY,
        weight = 10,
    },

    {
        id = items.POT_BERSERK_RAGE,
        weight = 5,
    },

    {
        id = items.POT_EXPERIENCE,
        weight = 1,
    },
}

-- The source uses one weighted roll, then retries only if that potion's
-- own can-quaff rule rejects the current body. This avoids substituting a
-- different effect when, for example, Stasis forbids Haste.
local function choose(ctx, player, stream)
    local total = 0

    for _, choice in ipairs(choices) do
        total = total + choice.weight
    end

    while true do
        local draw = ctx:random(stream, total)
        local chosen = nil

        for _, choice in ipairs(choices) do
            if draw < choice.weight then
                chosen = choice.id

                break
            end

            draw = draw - choice.weight
        end

        local potion = potions.get(chosen)

        if potion and not potion.can_quaff(ctx, player) then
            return chosen, potion
        end
    end
end

-- Only the potion owner mutates health, magic, durations, and progression.
-- Xom contributes the source weighted choice and the divine message.
function effect.apply(ctx, player, event_id, _severity, request)
    if event_id ~= event_ids.GOOD_POTION then
        error("potion effect received another Xom event")
    end

    local stream = request and request.stream or streams.RELIGION
    local potion_id, potion = choose(ctx, player, stream)

    ctx:emit(channels.RELIGION, "Xom grants you a potion effect!")

    local message = potion.apply(ctx, player, true)

    if message then
        ctx:emit(channels.RELIGION, message)
    end

    return potion_id
end

return effect
