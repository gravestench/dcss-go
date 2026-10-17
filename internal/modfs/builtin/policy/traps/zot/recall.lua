-- Source: mon-cast.cc:mons_word_of_recall(nullptr, 2 + random2(3)).
local component = require("constants.component")
local habitat = require("policy.combat.monster_habitat")
local relocation = require("policy.world.monster_relocation")
local streams = require("constants.rng_streams")
local vision = require("policy.character.vision")

local effect = {}

local function landing(ctx, monster, player_position)
    for distance = 1, 3 do
        for dy = -distance, distance do
            for dx = -distance, distance do
                if math.max(math.abs(dx), math.abs(dy)) == distance then
                    local x = player_position.x + dx
                    local y = player_position.y + dy

                    if not ctx:actor_at(player_position.level_id, x, y) and
                        habitat.at(ctx, monster, player_position.level_id,
                            x, y) then
                        return x, y
                    end
                end
            end
        end
    end

    return nil, nil
end

function effect.apply(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local candidates = {}
    local radius = vision.radius(ctx, player)

    for _, monster in ipairs(ctx:query({ component.ACTOR, component.AI })) do
        local position = ctx:get(monster, component.POSITION)

        if position and position.level_id == origin.level_id and
            not ctx:visible(origin.level_id, origin.x, origin.y,
                radius, position.x, position.y) then
            candidates[#candidates + 1] = monster
        end
    end

    local count = 2 + ctx:random(streams.TRAPS, 3)

    for _ = 1, math.min(count, #candidates) do
        local index = ctx:random(streams.TRAPS, #candidates) + 1
        local monster = table.remove(candidates, index)
        local x, y = landing(ctx, monster, origin)

        if x then
            relocation.move(ctx, monster, origin.level_id, x, y)
            ctx:emit("trap", "A monster is recalled.")
        end
    end
end

return effect
