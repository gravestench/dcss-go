-- Theory of operation: action owners report a named conduct at the moment
-- its facts are still live. This owner validates it and asks the current
-- god's module for a response. Godless actions use no religion RNG.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local channels = require("constants.message_channels")
local gods = require("constants.gods")
local kinds = require("constants.religion_conduct")
local piety = require("policy.religion.piety")

local conduct = {}
local known = {}

for _, id in pairs(kinds) do
    known[id] = true
end

-- Prefix source-style god speech only when the response actually has text.
-- This keeps the response metadata usable for both play and descriptions.
local function speak(ctx, definition, message)
    if message then
        ctx:emit(channels.RELIGION, definition.name .. message)
    end
end

-- Source peeves multiply the event's severity independently for piety and
-- penance. An unknown act with a forgiveness message ends before either
-- consequence, which also avoids consuming Faith's rounding RNG.
local function dislike(ctx, player, definition, event, rule)
    if rule.filter and not rule.filter(ctx, player, event) then
        return false
    end

    if not event.known and rule.forgiveness then
        speak(ctx, definition, rule.forgiveness)

        return true
    end

    speak(ctx, definition, rule.message)

    local loss = math.max(0, rule.loss_factor * event.level)
    local penance = math.max(0,
        rule.penance_factor * event.level + (rule.penance_offset or 0))

    piety.offend(ctx, player, loss, penance)

    return true
end

-- The odd source gain curve is shared across gods: denominator grows with
-- monster severity and often shrinks with player XL. A god-specific method
-- can adjust both values without adding a central god switch.
local function like(ctx, player, definition, event, rule)
    if event.credit == false or
        (rule.filter and not rule.filter(ctx, player, event)) then
        return false
    end

    local denominator = rule.denom_bonus + event.level

    if rule.xl_denom and rule.xl_denom > 0 then
        local progress = ctx:get(player, component.PROGRESSION)

        if not progress then
            error("kill conduct requires player progression")
        end

        denominator = denominator -
            math.floor(progress.level / rule.xl_denom)
    end

    local numerator = denominator + rule.bonus
    local message = rule.message

    if rule.special then
        local special_message

        numerator, denominator, special_message = rule.special(ctx, player, event,
            numerator, denominator)

        if special_message ~= nil then
            message = special_message
        end
    end

    speak(ctx, definition, message)

    piety.gain(ctx, player, math.max(0, numerator),
        math.max(1, denominator), true)

    return true
end

-- Resolve synchronously: a victim entity may be destroyed by the same turn
-- after death processing. A saved queue would retain a dangling entity ID.
function conduct.record(ctx, event)
    if type(event) ~= "table" or not known[event.id] then
        error("unknown religion conduct " .. tostring(event and event.id))
    end

    if type(event.level) ~= "number" or event.level % 1 ~= 0 or
        event.level < 0 or type(event.known) ~= "boolean" then
        error("religion conduct requires nonnegative level and known flag")
    end

    local player = ctx:player()
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state then
        error("religion conduct requires player worship state")
    end

    if state.god_id == gods.NO_GOD then
        return false
    end

    local definition = catalog.get(categories.GODS, state.god_id)

    if not definition.conduct_module then
        return false
    end

    local handler = require(definition.conduct_module)

    if handler.before and handler.before(ctx, player, event) == false then
        return false
    end

    local applied = false
    local peeve = handler.dislikes and handler.dislikes[event.id]

    if peeve then
        applied = dislike(ctx, player, definition, event, peeve)
    end

    local reward = handler.likes and handler.likes[event.id]

    if reward then
        applied = like(ctx, player, definition, event, reward) or applied
    end

    if handler.after then
        handler.after(ctx, player, event)
    end

    return applied
end

return conduct
