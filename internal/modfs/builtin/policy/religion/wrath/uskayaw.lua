-- Uskayaw chooses one visible hostile monster before a five-way divine
-- dance. The chosen actor may berserk; otherwise the player loses a solo
-- to paralysis or the floor hears a thirty-five-volume announcement.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local attitudes = require("constants.attitude")
local component = require("constants.component")
local gods = require("constants.gods")
local nearby = require("policy.religion.cards.effects.nearby")
local noise = require("policy.world.noise")
local paralysis = require("policy.character.paralysis")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local uskayaw = {}

-- Source choose_random_nearby_monster gives each hostile visible actor one
-- reservoir chance. Sort order comes from nearby.monsters, not Lua load order.
local function hostile_candidate(ctx, player)
    local chosen
    local seen = 0

    for _, candidate in ipairs(nearby.monsters(ctx, player)) do
        if targets.attitude(ctx, candidate.entity) ==
            attitudes.HOSTILE then
            seen = seen + 1

            if seen == 1 or
                ctx:random(streams.CARDS, seen) == 0 then
                chosen = candidate.entity
            end
        end
    end

    return chosen
end

-- Solo paralysis also pays one additional point of this god's penance;
-- divine_retribution will pay its normal 1..3 reduction afterward.
local function solo(ctx, player)
    ctx:emit("religion",
        'Uskayaw booms out, "Time for someone else to take a solo"')
    paralysis.divine(ctx, player, streams.CARDS)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.penance[gods.USKAYAW] = math.max(0,
        (worship.penance[gods.USKAYAW] or 0) - 1)
    ctx:set(player, component.RELIGION_WORSHIP, worship)
end

-- A failed Berserk branch intentionally falls into Solo when a candidate
-- exists. With no candidate, every branch falls into the loud call.
function uskayaw.apply(ctx, player)
    local monster = hostile_candidate(ctx, player)
    local choice = ctx:random(streams.CARDS, 5)

    if choice <= 1 and monster and
        allegiance.can_berserk(ctx, monster) then
        ctx:emit("religion", "Uskayaw drives a foe into a dance frenzy!")
        allegiance.start_berserk(ctx, monster, streams.CARDS)

        return true
    end

    if choice <= 3 and monster then
        solo(ctx, player)

        return false
    end

    ctx:emit("religion",
        'Uskayaw booms out: "Revellers, it\'s time to dance!"')
    noise.emit(ctx, ctx:get(player, component.POSITION), 35, player)

    return true
end

return uskayaw
