-- Both Xom mutation events use the ordinary god-gift transition. That owner
-- already resolves Zin's protection, conflicts, body restrictions, and saved
-- mutation ranks; Xom only chooses the source pool and attempt count.
local channels = require("constants.message_channels")
local choices = require("constants.mutation_choices")
local classes = require("constants.mutation_classes")
local event_ids = require("ids.xom_events")
local god_gift = require("policy.mutations.god_gift")
local physiology = require("policy.mutations.physiology")
local streams = require("constants.rng_streams")

local effect = {}

-- Source Xom makes one to four independent attempts, even when one is
-- protected or blocked. A good act samples good mutations; a bad act uses
-- Xom's own random pool rather than the generic bad-mutation pool.
function effect.apply(ctx, player, event_id, _severity, request)
    if not physiology.can_safely_mutate(ctx, player) then
        return 0
    end

    local choice

    if event_id == event_ids.GOOD_MUTATION then
        choice = choices.GOOD
    elseif event_id == event_ids.BAD_MUTATION then
        choice = choices.XOM
    else
        error("mutation effect received another Xom event")
    end

    local stream = request and request.stream or streams.RELIGION
    local attempts = 1 + ctx:random(stream, 4)

    ctx:emit(channels.RELIGION,
        "Your body is suffused with distortional energy.")

    local changed = 0

    for _ = 1, attempts do
        local result = god_gift.grant_random(ctx, player, choice,
            classes.ACQUIRED)

        if result.kind == "granted" or
            result.kind == "permanent" or
            result.kind == "removed" then
            changed = changed + 1
        end
    end

    return changed
end

return effect
