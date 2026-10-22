-- Theory of operation: equipped artefact drawbacks react after the
-- mutation and fog effects of a surviving hit. Each worn property is an
-- independent source trial; the resulting degree changes the existing
-- corrosion or Slow ECS status instead of creating duplicate state.
local channels = require("constants.message_channels")
local causes = require("constants.damage_causes")
local component = require("constants.component")
local order = require("constants.damage_reaction_order")
local property_ids = require("ids.artefact_properties")
local reactions = require("policy.combat.player_damage_reactions")
local streams = require("constants.rng_streams")

local artefact_hit = {}

local PERCENT = 100
local CORRODE_CHANCE = 3
local SLOW_CHANCE = 1

-- A source binomial roll makes exactly one percent trial per equipped
-- contributing property. Values come from the saved item, not its catalog.
local function degree(ctx, player, property_id, chance)
    local properties = require(
        "policy.item_generation.artefacts.properties")
    local sources = properties.sum_worn(ctx, player, property_id)
    local triggered = 0

    for _ = 1, sources do
        if ctx:random(streams.DAMAGE_REACTION,
            PERCENT) < chance then
            triggered = triggered + 1
        end
    end

    return triggered
end

-- Poison is source-excluded. Other positive surviving HP loss can make
-- one corrosion application whose protected degrees share a duration.
function artefact_hit.corrode(ctx, player, _, cause)
    if cause == causes.POISON then
        return
    end

    local count = degree(ctx, player,
        property_ids.CORRODE, CORRODE_CHANCE)

    if count == 0 then
        return
    end

    local corrosion = require("policy.combat.player_corrosion")

    corrosion.corrode_equipment(ctx, player,
        "Your corrosive artefact", streams.DAMAGE_REACTION,
        channels.COMBAT, count)
end

-- Each successful *Slow source applies its own 10–14-turn timer. Repeated
-- applications can extend the same saved status up to the source cap.
function artefact_hit.slow(ctx, player, _, cause)
    if cause == causes.POISON then
        return
    end

    local count = degree(ctx, player,
        property_ids.SLOW, SLOW_CHANCE)

    if count == 0 then
        return
    end

    local slow = require("policy.character.slow")

    for _ = 1, count do
        local current = ctx:get(player, component.PLAYER_SLOW)
        local before = current and current.remaining_aut or 0
        local turns = 10 + ctx:random(streams.DAMAGE_REACTION, 5)

        if slow.apply(ctx, player, turns) then
            local updated = ctx:get(player, component.PLAYER_SLOW)
            local message

            if updated.remaining_aut == before then
                message = "You already are as slow as you could be."
            elseif before == 0 then
                message = "You feel yourself slow down."
            else
                message = "You feel as though you will be slow longer."
            end

            ctx:emit(channels.DURATION, message)
        end
    end
end

-- Keep corrosion before slow, matching the source's final two on-hit
-- calls regardless of mod discovery or registration order.
function artefact_hit.register()
    reactions.add("combat.artefact_corrode",
        order.ARTEFACT_CORRODE, artefact_hit.corrode)
    reactions.add("combat.artefact_slow",
        order.ARTEFACT_SLOW, artefact_hit.slow)
end

return artefact_hit
