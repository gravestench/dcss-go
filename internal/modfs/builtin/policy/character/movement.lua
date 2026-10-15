local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local mutation_effects = require("policy.mutations.effects.registry")
local flight = require("policy.combat.flight")
local water = require("policy.character.water")
local forms = require("policy.magic.effects.forms.player")

local movement = {}

-- Source: player.cc:player_movement_speed. The status policy applies
-- Swiftness to this base before action speed scales the movement delay.
function movement.base(ctx, player)
    local delay = forms.move_speed(ctx, player)
    local aura = ctx:get(player, component.LIQUEFACTION)

    if water.at(ctx, player) then
        local swimming = mutation_effects.sum(ctx, player,
            capabilities.SWIMMER_LEVEL)

        if swimming >= 2 then
            delay = delay - 4
        elseif water.immersed(ctx, player) and
            not water.can_swim(ctx, player) then
            delay = delay + 6
        end
    end

    if aura and aura.remaining_aut > 0 then
        delay = delay + 3
    end

    delay = delay - mutation_effects.sum(ctx, player,
        capabilities.MOVE_FAST_REDUCTION)

    if flight.tengu_perk(ctx, player) then
        delay = delay - 1
    end

    local slow = mutation_effects.sum(ctx, player,
        capabilities.MOVE_SLOW_LEVEL)

    if slow > 0 then
        delay = math.floor(delay * (10 + slow * 2) / 10)
    end

    return delay
end

-- Source: movement.cc scales movement speed by the current action time.
function movement.scale(ctx, delay, time_taken)
    local numerator = math.max(6, delay) * time_taken
    local result = math.floor(numerator / 10)
    local remainder = numerator % 10

    if remainder > 0 and ctx:random("speed", 10) < remainder then
        result = result + 1
    end

    return result
end

return movement
