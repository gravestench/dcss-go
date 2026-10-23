-- The Tomb card raises temporary rock walls around the player. The world
-- terrain owner saves each original feature and restores it on expiry.
local cards = require("ids.cards")
local component = require("constants.component")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local temporary = require("policy.world.temporary_terrain")

local tomb = {}

local doors = {
    [terrain.DNGN_CLOSED_DOOR] = true,
    [terrain.DNGN_CLOSED_CLEAR_DOOR] = true,
    [terrain.DNGN_OPEN_DOOR] = true,
    [terrain.DNGN_OPEN_CLEAR_DOOR] = true,
    [terrain.DNGN_SEALED_DOOR] = true,
    [terrain.DNGN_SEALED_CLEAR_DOOR] = true,
}

-- adjacent_iterator consumes Compass in reverse order, which determines
-- which wall the source's per-cell skip roll applies to.
local adjacent = {
    { x = -1, y = -1 },
    { x = -1, y = 0 },
    { x = -1, y = 1 },
    { x = 0, y = 1 },
    { x = 1, y = 1 },
    { x = 1, y = 0 },
    { x = 1, y = -1 },
    { x = 0, y = -1 },
}

-- The source's one_chance_in roll occurs before checking the cell. A
-- positive power below three has no skip chance, as random2(0) is zero.
local function skipped(ctx, power)
    local bound = math.floor(power / 3)

    return bound > 1 and ctx:random(streams.CARDS, bound) == 0
end

-- decks.cc passes this exact power to cast_tomb, which uses it again as the
-- wall lifetime in turns. Occupied cells and solid nondoors remain untouched.
function tomb.apply(ctx, player, request)
    local power = request.power

    if type(power) ~= "number" or power < 0 then
        error("Tomb requires nonnegative card power")
    end

    local quarter = math.floor(power / 4)
    local variance = quarter > 1 and
        ctx:random(streams.CARDS, quarter) or 0
    local tomb_power = 10 + math.floor(power / 20) + variance
    local origin = ctx:get(player, component.POSITION)
    local built = 0
    local wall_markers = {}

    for _, offset in ipairs(adjacent) do
        local x = origin.x + offset.x
        local y = origin.y + offset.y

        if not skipped(ctx, tomb_power) then
            local feature = ctx:cell(origin.level_id, x, y)

            if feature and
                (ctx:walkable(origin.level_id, x, y) or
                    doors[feature]) and
                not ctx:actor_at(origin.level_id, x, y) then
                local placed, marker = temporary.place(ctx,
                    player, cards.TOMB, origin.level_id, x, y,
                    terrain.DNGN_ROCK_WALL, tomb_power * 10)

                if placed then
                    built = built + 1
                    wall_markers[#wall_markers + 1] = marker
                end
            end
        end
    end

    if built > 0 then
        local group = ctx:create()

        ctx:add(group, component.RELIGION_CARD_TOMB, {
            owner = player,
            level_id = origin.level_id,
            x = origin.x,
            y = origin.y,
            expires_aut = ctx:aut() + tomb_power * 10,
            wall_markers = wall_markers,
        })

        ctx:emit("religion", "Walls emerge from the floor!")
    else
        ctx:emit("religion", "Nothing happens.")
    end
end

return tomb
