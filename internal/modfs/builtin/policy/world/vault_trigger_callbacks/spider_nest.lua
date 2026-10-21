-- Spider Nest's source basket is a one-shot player-move surprise. Its
-- warning marker and spawn marker use the same generic ECS trigger owner.
local component = require("constants.component")
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")

local handler = {}

-- Try the source 3x3 rectangle in row-major order. The player cell and
-- other occupied or impassable cells cannot receive an awake redback.
local function spawn(ctx, state)
    local player = ctx:player()
    local position = ctx:get(player, component.POSITION)
    local count = 0

    for y = state.y - 1, state.y + 1 do
        for x = state.x - 1, state.x + 1 do
            local player_cell = position.level_id == state.level_id and
                position.x == x and position.y == y

            if not player_cell and
                ctx:walkable(state.level_id, x, y) and
                not ctx:actor_at(state.level_id, x, y) then
                factory.spawn(ctx, monsters.MONS_REDBACK,
                    state.level_id, x, y, {
                        generate_awake = true,
                    })
                count = count + 1
            end
        end
    end

    if count > 0 then
        ctx:emit(channels.VAULT, "A basket of spiders falls from above!")
    end
end

-- The other source marker announces the webbed room before the basket.
local function warn(ctx)
    ctx:emit(channels.VAULT,
        "You notice webbing strewn about the room and hear a chittering noise in the background.")
end

handler.spawn = spawn
handler.warn = warn

return handler
