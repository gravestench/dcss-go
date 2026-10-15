local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")
local terrain = require("policy.magic.effects.summons.terrain")

local spell_id = spells.SPELL_SUMMON_FOREST
local forest_walls = {
    [terrain_ids.DNGN_ROCK_WALL] = true,
    [terrain_ids.DNGN_STONE_WALL] = true,
    [terrain_ids.DNGN_METAL_WALL] = true,
    [terrain_ids.DNGN_CRYSTAL_WALL] = true,
    [terrain_ids.DNGN_CLEAR_ROCK_WALL] = true,
    [terrain_ids.DNGN_CLEAR_STONE_WALL] = true,
    [terrain_ids.DNGN_SLIMY_WALL] = true,
}

local function open_area(ctx, position)
    for dy = -1, 1 do
        for dx = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and
                not terrain.adjacent_solid(ctx, position.level_id,
                    position.x + dx, position.y + dy) then
                return true
            end
        end
    end

    return false
end

local function connected_after_tree(ctx, level_id, x, y)
    local adjacent = {}

    for _, delta in ipairs({
        { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
    }) do
        local nx, ny = x + delta[1], y + delta[2]

        if ctx:walkable(level_id, nx, ny) then
            adjacent[#adjacent + 1] = { x = nx, y = ny }
        end
    end

    if #adjacent <= 1 then
        return true
    end

    local queue = { adjacent[1] }
    local seen = { [adjacent[1].x .. ":" .. adjacent[1].y] = true }
    local head = 1

    while head <= #queue do
        local current = queue[head]
        head = head + 1

        for _, delta in ipairs({
            { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        }) do
            local nx, ny = current.x + delta[1], current.y + delta[2]
            local key = nx .. ":" .. ny

            if not seen[key] and (nx ~= x or ny ~= y) and
                math.abs(nx - x) <= 8 and math.abs(ny - y) <= 8 and
                ctx:walkable(level_id, nx, ny) then
                seen[key] = true
                queue[#queue + 1] = { x = nx, y = ny }
            end
        end
    end

    for _, cell in ipairs(adjacent) do
        if not seen[cell.x .. ":" .. cell.y] then
            return false
        end
    end

    return true
end

local function watery_adjacent(ctx, level_id, x, y)
    for _, delta in ipairs({
        { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
    }) do
        local feature = ctx:cell(level_id, x + delta[1], y + delta[2])

        if feature == terrain_ids.DNGN_SHALLOW_WATER or feature == terrain_ids.DNGN_DEEP_WATER then
            return true
        end
    end

    return false
end

local function pond(ctx, player, position, expires_aut)
    local points = terrain.gateway_points(ctx, position)

    if #points == 0 then
        return
    end

    local center = points[summons.roll(ctx, #points) + 1]
    local remaining = 10 + summons.roll(ctx, 13)
    local deep = 0

    if summons.roll(ctx, 3) ~= 0 then
        deep = summons.divide(ctx, remaining, 3)
    end

    for radius = 0, 4 do
        for dy = -radius, radius do
            for dx = -radius, radius do
                if remaining <= 0 then
                    return
                end

                if math.max(math.abs(dx), math.abs(dy)) == radius then
                    local x, y = center.x + dx, center.y + dy
                    local feature = ctx:cell(position.level_id, x, y)

                    if feature == terrain_ids.DNGN_FLOOR and
                        (radius == 0 or watery_adjacent(ctx, position.level_id, x, y)) and
                        summons.roll(ctx, radius + 3) < 4 then
                        remaining = remaining - 1
                        deep = deep - 1

                        local next_feature = terrain_ids.DNGN_SHALLOW_WATER

                        if deep > 0 and (x ~= position.x or y ~= position.y) and
                            not ctx:actor_at(position.level_id, x, y) then
                            next_feature = terrain_ids.DNGN_DEEP_WATER
                        end

                        terrain.temporary(ctx, player, spell_id, position.level_id,
                            x, y, next_feature, expires_aut)
                    end
                end
            end
        end
    end
end

-- Source: spl-summoning.cc:cast_summon_forest. Terrain markers are saved and
-- expire independently of the dryad, matching TERRAIN_CHANGE_FORESTED.
local spell_effects = {}

function spell_effects.prepare(ctx, player)
    if not open_area(ctx, ctx:get(player, component.POSITION)) then
        return "There is not enough open space to summon a forest."
    end
end

function spell_effects.resolve(ctx, player, _, _, power)
    local position = ctx:get(player, component.POSITION)
    local duration = 120 + power +
        summons.roll(ctx, 81 + math.floor(power / 2))
    local expires_aut = ctx:aut() + duration

    for dy = -7, 7 do
        for dx = -7, 7 do
            if dx ~= 0 or dy ~= 0 then
                local x, y = position.x + dx, position.y + dy
                local feature = ctx:cell(position.level_id, x, y)

                if forest_walls[feature] and
                    summons.roll(ctx, 150) < power then
                    terrain.temporary(ctx, player, spell_id, position.level_id,
                        x, y, terrain_ids.DNGN_TREE, expires_aut)
                elseif feature == terrain_ids.DNGN_FLOOR and
                    summons.roll(ctx, 1250) < power and
                    not ctx:actor_at(position.level_id, x, y) and
                    connected_after_tree(ctx, position.level_id, x, y) then
                    terrain.temporary(ctx, player, spell_id, position.level_id,
                        x, y, terrain_ids.DNGN_TREE, expires_aut)
                end
            end
        end
    end

    if summons.roll(ctx, 2) == 0 then
        pond(ctx, player, position, expires_aut)
    end

    local dryad = summons.spawn(ctx, player, spell_id, monsters.MONS_DRYAD, 1, 1, {
        hd = 5 + summons.divide(ctx, power, 18),
        expires_aut = expires_aut - 10,
    })

    if dryad then
        ctx:emit("spell", "A dryad steps from the new forest.")
    end

    ctx:emit("spell", "A forested plane collides here with a resounding crunch!")
end

registry.add(spell_id, {
    prepare = spell_effects.prepare,

    resolve = spell_effects.resolve,
})

return spell_effects
