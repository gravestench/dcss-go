-- Monster corruption temporarily replaces open dungeon terrain with Abyss
-- proto-features and calls one to three Abyss servants around the caster.
-- Source: abyss.cc:_corrupt_level_features_monster/lugonu_corrupt_level_monster.
local branches = require("ids.branches")
local component = require("constants.component")
local servants = require("policy.combat.monster_corruption_servants")
local displacement = require("policy.combat.monster_corruption_displacement")
local roll = require("policy.combat.roll")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local summons = require("policy.magic.effects.summons.common")
local temporary = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")

local effect = {}
local RADIUS = 7
local proto = {
    { feature = terrain.DNGN_FLOOR, weight = 3000 },
    { feature = terrain.DNGN_ROCK_WALL, weight = 600 },
    { feature = terrain.DNGN_STONE_WALL, weight = 300 },
    { feature = terrain.DNGN_METAL_WALL, weight = 100 },
    { feature = terrain.DNGN_CLOSED_DOOR, weight = 1 },
}

local function proto_feature(ctx)
    local draw = roll.spell(ctx, 4001)

    for _, entry in ipairs(proto) do
        draw = draw - entry.weight

        if draw < 0 then
            return entry.feature
        end
    end
end

local function incorruptible(feature)
    return feature == terrain.DNGN_PERMAROCK_WALL or
        feature == terrain.DNGN_CLEAR_PERMAROCK_WALL or
        feature == terrain.DNGN_OPEN_SEA or
        feature == terrain.DNGN_LAVA_SEA or
        feature == terrain.DNGN_STONE_STAIRS_UP_I or
        feature == terrain.DNGN_STONE_STAIRS_DOWN_I
end

local function resist_wall(ctx, feature)
    if feature == terrain.DNGN_METAL_WALL or
        feature == terrain.DNGN_CRYSTAL_WALL then
        return roll.spell(ctx, 4) ~= 0
    end

    if feature == terrain.DNGN_STONE_WALL or
        feature == terrain.DNGN_CLEAR_STONE_WALL then
        return roll.spell(ctx, 3) ~= 0
    end

    if feature == terrain.DNGN_ROCK_WALL or
        feature == terrain.DNGN_CLEAR_ROCK_WALL then
        return roll.spell(ctx, 3) == 0
    end

    return false
end

local function solid(feature)
    return feature == terrain.DNGN_ROCK_WALL or
        feature == terrain.DNGN_STONE_WALL or
        feature == terrain.DNGN_METAL_WALL or
        feature == terrain.DNGN_CLOSED_DOOR
end

local function crowded(ctx, level_id, x, y)
    local open = 0

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                if ctx:walkable(level_id, x + dx, y + dy) then
                    open = open + 1
                end
            end
        end
    end

    return open <= 4
end

function effect.plan(ctx, caster)
    local position = ctx:get(caster, component.POSITION)

    if not position or
        ctx:level_branch(position.level_id) == branches.BRANCH_ABYSS then
        return nil
    end

    return self_target.plan(caster)
end

-- The monster variant draws one 0..2999 roll per visible cell. Unlike
-- player corruption, only bare floor may be changed into another feature.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local origin = ctx:get(caster, component.POSITION)

    if not origin or
        ctx:level_branch(origin.level_id) == branches.BRANCH_ABYSS then
        return
    end

    for _, cell in ipairs(ctx:visible_cells(origin.level_id,
        origin.x, origin.y, RADIUS)) do
        local distance = math.max(math.abs(cell.x - origin.x),
            math.abs(cell.y - origin.y))

        if distance <= RADIUS then
            local feature = ctx:cell(origin.level_id, cell.x, cell.y)
            local chance = distance <= 2 and 1000 or
                math.max(0, 1000 - (distance * distance - 4) * 700 / 45)
            local draw = roll.spell(ctx, 3000)
            local player = ctx:get(ctx:player(), component.POSITION)
            local player_cell = player and player.level_id == origin.level_id and
                player.x == cell.x and player.y == cell.y

            if feature and not player_cell and
                not incorruptible(feature) then
                if feature == terrain.DNGN_FLOOR and draw < chance then
                    local changed = proto_feature(ctx)

                    if solid(changed) then
                        if roll.spell(ctx, 2) == 0 then
                            changed = terrain.DNGN_FLOOR
                        elseif crowded(ctx, origin.level_id,
                            cell.x, cell.y) then
                            changed = nil
                        end
                    end

                    -- Source pushes items and actors aside before placing
                    -- a solid temporary feature; failed pushes use floor.
                    if changed and solid(changed) and
                        not displacement.clear(ctx, origin.level_id,
                            cell.x, cell.y) then
                        changed = terrain.DNGN_FLOOR
                    end

                    if changed then
                        local duration = 60 + roll.spell(ctx, 61)

                        temporary.place(ctx, caster,
                            spells.SPELL_CORRUPT_LOCALE,
                            origin.level_id, cell.x, cell.y,
                            changed, duration)
                    end
                elseif draw < (chance + 1000) / 2 and
                    not resist_wall(ctx, feature) then
                    -- Terrain colors are absent from the current view
                    -- contract; tree corruption is the visible flavor case.
                    if feature == terrain.DNGN_TREE then
                        ctx:set_cell(origin.level_id, cell.x, cell.y,
                            terrain.DNGN_DEMONIC_TREE)
                    end
                end
            end
        end
    end

    local count = 1 + roll.spell(ctx, 3)

    for _ = 1, count do
        local kind = servants.pick(ctx)

        summons.spawn(ctx, caster, spells.SPELL_CORRUPT_LOCALE,
            kind, 3, nil)
    end

    ctx:emit("monster_spell", "The dungeon is corrupted around the caster!")
end

return effect
