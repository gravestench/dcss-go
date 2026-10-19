-- Source: main.cc:_update_golubria_traps. Temporary traps age only while
-- their level is active, with fractional AUT rounded by a trap RNG draw.
local catalog = require("policy.catalog")
local component = require("constants.component")
local streams = require("constants.rng_streams")
local vision = require("policy.character.vision")

local timer = {}

-- Round fractional aut with trap RNG so short actions age temporary traps over time.
local function elapsed_turns(ctx, aut)
    local whole = math.floor(aut / 10)
    local remainder = aut % 10

    if remainder > 0 and ctx:random(streams.TRAPS, 10) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Turn elapsed aut into trap ticks only on the player's level, preserving per-trap timers.
-- Example: timer.tick(ctx, player, 10) advances timed trap effects by one normal turn.
function timer.tick(ctx, player, aut)
    if aut <= 0 then
        return
    end

    local position = ctx:get(player, component.POSITION)
    local elapsed = elapsed_turns(ctx, aut)

    if elapsed == 0 then
        return
    end

    for _, entity in ipairs(ctx:query({ component.WORLD_TRAP })) do
        local state = ctx:get(entity, component.WORLD_TRAP)
        local definition = catalog.get("traps", state.kind_id)

        if definition.lifetime_turns and
            state.level_id == position.level_id then
            state.charges = state.charges - elapsed

            if state.charges <= 0 then
                if ctx:visible(position.level_id, position.x, position.y,
                    vision.radius(ctx, player), state.x, state.y) then
                    ctx:emit("trap", "Your passage of Golubria closes with a snap!")
                else
                    ctx:emit("trap", "You hear a snapping sound.")
                end

                ctx:destroy(entity)
            else
                ctx:set(entity, component.WORLD_TRAP, state)
            end
        end
    end
end

return timer
