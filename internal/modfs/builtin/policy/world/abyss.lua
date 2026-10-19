local relocation = require("policy.world.monster_relocation")
local component = require("constants.component")

local abyss = {}

-- Keep branch levels outside the Dungeon depth IDs.
abyss.level_id = 1000

-- Pick a walkable Abyss cell before saving a return point or moving an actor.
local function landing(ctx)
    for _ = 1, 200 do
        local x = ctx:random("abyss-placement", 78) + 1
        local y = ctx:random("abyss-placement", 68) + 1

        if ctx:walkable(abyss.level_id, x, y) and
            not ctx:actor_at(abyss.level_id, x, y) then
            return x, y
        end
    end

    error("the Abyss has no open landing cell")
end

-- Save the departure cell before moving to the Abyss so the return path can restore the player.
-- Example: abyss.banish(ctx, player) records the return location before moving the player.
function abyss.banish(ctx, player)
    local position = ctx:get(player, "core.position")

    if not position or position.level_id == abyss.level_id then
        return
    end

    local x, y = landing(ctx)
    ctx:add(player, component.BANISHMENT, {
        origin_level_id = position.level_id,
        origin_x = position.x,
        origin_y = position.y,
    })
    ctx:move_actor(player, abyss.level_id, x, y)
    ctx:emit("banishment", "You are cast into the Abyss!")
end

-- Distortion moves a monster to the existing Abyss level without a kill.
-- Its origin is saved so future Abyss and branch rules can find the actor.
function abyss.banish_monster(ctx, monster, definition)
    local position = ctx:get(monster, "core.position")

    if not position or position.level_id == abyss.level_id then
        return false
    end

    local x, y = landing(ctx)

    ctx:add(monster, component.BANISHMENT, {
        origin_level_id = position.level_id,
        origin_x = position.x,
        origin_y = position.y,
    })
    relocation.move(ctx, monster, abyss.level_id, x, y)
    ctx:emit("banishment", "The " .. definition.name ..
        " is cast into the Abyss!")

    return true
end

-- Use the saved banishment origin when returning; the Abyss level is not the source floor.
function abyss.escape(ctx, player)
    local return_to = ctx:get(player, component.BANISHMENT)

    if not return_to then
        error("Abyss escape has no banishment origin")
    end

    local level_id = return_to.origin_level_id
    local x = return_to.origin_x
    local y = return_to.origin_y

    if not ctx:walkable(level_id, x, y) or ctx:actor_at(level_id, x, y) then
        local found = false

        for radius = 1, 12 do
            for offset_y = -radius, radius do
                for offset_x = -radius, radius do
                    local candidate_x = x + offset_x
                    local candidate_y = y + offset_y

                    if ctx:walkable(level_id, candidate_x, candidate_y) and
                        not ctx:actor_at(level_id, candidate_x, candidate_y) then
                        x = candidate_x
                        y = candidate_y
                        found = true
                        break
                    end
                end

                if found then
                    break
                end
            end

            if found then
                break
            end
        end

        if not found then
            error("Abyss escape has no safe return cell")
        end
    end

    ctx:move_actor(player, level_id, x, y)
    ctx:remove(player, component.BANISHMENT)
    ctx:emit("stairs", "You escape the Abyss!")
end

return abyss
