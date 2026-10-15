local spells = require("ids.spells")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local common = require("policy.magic.effects.translocation.common")
local habitat = require("policy.combat.monster_habitat")
local net = require("policy.combat.net")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")

local passwall = {}
local passable = {
    [terrain_ids.DNGN_ROCK_WALL] = true,
    [terrain_ids.DNGN_SLIMY_WALL] = true,
    [terrain_ids.DNGN_CLEAR_ROCK_WALL] = true,
}

local safe_destination = {
    [terrain_ids.DNGN_FLOOR] = true,
    [terrain_ids.DNGN_OPEN_DOOR] = true,
    [terrain_ids.DNGN_CLOSED_DOOR] = true,
    [terrain_ids.DNGN_STONE_STAIRS_UP_I] = true,
    [terrain_ids.DNGN_STONE_STAIRS_DOWN_I] = true,
}

local function find_path(ctx, player, spell, dx, dy)
    if dx == 0 and dy == 0 then
        return nil, "Please select a wall."
    end

    local origin = ctx:get(player, component.POSITION)
    local step_x = dx < 0 and -1 or (dx > 0 and 1 or 0)
    local step_y = dy < 0 and -1 or (dy > 0 and 1 or 0)
    local walls = 0
    local max_walls = range.for_spell(ctx, player, spell)

    for distance = 1, max_walls + 1 do
        local x = origin.x + step_x * distance
        local y = origin.y + step_y * distance
        local feature = ctx:cell(origin.level_id, x, y)

        if passable[feature] then
            walls = walls + 1
        else
            if walls == 0 then
                return nil, "There is no adjacent passable wall in that direction."
            end

            if not safe_destination[feature] then
                return nil, "Something is blocking your path through the rock."
            end

            local occupant = ctx:actor_at(origin.level_id, x, y)

            if occupant then
                local actor = ctx:get(occupant, component.ACTOR)
                local definition = actor and
                    require("policy.catalog").get("monsters", actor.kind_id)

                if definition and common.flag(definition, "M_STATIONARY") then
                    return nil, "Something is blocking your path through the rock."
                end
            end

            return {
                level_id = origin.level_id,
                dest_x = x,
                dest_y = y,
                walls = walls,
            }
        end
    end

    return nil, "This rock feels extremely deep."
end

function passwall.cancel(ctx, player)
    if not ctx:has(player, component.PASSWALL_DELAY) then
        return "You are not merging with rock."
    end

    ctx:remove(player, component.PASSWALL_DELAY)
    return "Your meditation is interrupted."
end

local function shift_occupant(ctx, level_id, x, y)
    local occupant = ctx:actor_at(level_id, x, y)

    if not occupant then
        return true
    end

    for radius = 1, 1 do
        for dy = -radius, radius do
            for dx = -radius, radius do
                local nx, ny = x + dx, y + dy

                if (dx ~= 0 or dy ~= 0) and
                    not ctx:actor_at(level_id, nx, ny) and
                    habitat.at(ctx, occupant, level_id, nx, ny) then
                    net.release(ctx, occupant)
                    ctx:move_actor(occupant, level_id, nx, ny)
                    return true
                end
            end
        end
    end

    return false
end

function passwall.tick(ctx, player, aut)
    local state = ctx:get(player, component.PASSWALL_DELAY)

    if not state or aut <= 0 or ctx:aut() <= state.started_aut then
        return
    end

    state.remaining_aut = state.remaining_aut - aut

    if state.remaining_aut > 0 then
        ctx:set(player, component.PASSWALL_DELAY, state)
        return
    end

    ctx:remove(player, component.PASSWALL_DELAY)
    local origin = ctx:get(player, component.POSITION)
    local feature = ctx:cell(state.level_id, state.dest_x, state.dest_y)

    if origin.level_id ~= state.level_id or
        not safe_destination[feature] or
        not shift_occupant(ctx, state.level_id, state.dest_x, state.dest_y) then
        ctx:emit("spell", "You sense your way blocked and quickly turn back.")
        return
    end

    if feature == terrain_ids.DNGN_CLOSED_DOOR then
        ctx:set_cell(state.level_id, state.dest_x, state.dest_y,
            terrain_ids.DNGN_OPEN_DOOR)
    end

    ctx:move_actor(player, state.level_id, state.dest_x, state.dest_y)
    ctx:emit("spell", "You finish merging with the rock.")
end

-- Source: spl-other.cc:cast_passwall. Rejected known paths cost no time;
-- the successful cast stores a saved delay until the destination is reached.
function passwall.prepare(ctx, player, spell, dx, dy)
    local _, reason = find_path(ctx, player, spell, dx, dy)
    return reason
end

function passwall.resolve(ctx, player, intent, spell)
    local path = assert(find_path(ctx, player, spell,
        intent.dx, intent.dy))
    ctx:add(player, component.PASSWALL_DELAY, {
        level_id = path.level_id,
        dest_x = path.dest_x,
        dest_y = path.dest_y,
        started_aut = ctx:aut(),
        remaining_aut = (path.walls + 1) * 10,
    })
    ctx:emit("spell", "You begin merging with the rock.")
end

registry.add(spells.SPELL_PASSWALL, {
    prepare = passwall.prepare,

    resolve = passwall.resolve,
})

return passwall
