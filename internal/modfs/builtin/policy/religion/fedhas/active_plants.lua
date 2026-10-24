-- Theory of operation: Fedhas grows real, finite ECS plant allies. Wall of
-- Briars fills adjacent habitable cells; the two aimed powers use a single
-- selected cell. Overgrow tears down one eligible wall or tree and its
-- visible eligible neighbors before growing a weighted source plant on
-- each new floor. The summon owner keeps lifetime, allegiance, and saves.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local digging = require("policy.world.digging")
local gods = require("constants.gods")
local habitat = require("policy.combat.monster_habitat")
local hit_points = require("policy.population.hit_points")
local monsters = require("ids.monsters")
local power = require("policy.magic.power")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local terrain = require("constants.terrain")

local plants = {}

-- DCSS weights are 4/4/4/1/1. Keep them beside the selection, so an
-- added monster does not silently alter the source odds.
local overgrowth = {
    monsters.MONS_OKLOB_SAPLING,
    monsters.MONS_BURNING_BUSH,
    monsters.MONS_WANDERING_MUSHROOM,
    monsters.MONS_BALLISTOMYCETE,
    monsters.MONS_OKLOB_PLANT,
}

-- Save validation uses this same roster rather than redeclaring the
-- allowed god-sourced creatures in another module.
plants.allowed = {
    [monsters.MONS_BRIAR_PATCH] = true,
}

for _, kind_id in ipairs(overgrowth) do
    plants.allowed[kind_id] = true
end

-- Tree and door variants are explicit because digging alone does not
-- include them. Permanent rock remains outside this set.
local breakable = {
    [terrain.DNGN_STONE_WALL] = true,
    [terrain.DNGN_CLEAR_STONE_WALL] = true,
    [terrain.DNGN_CRYSTAL_WALL] = true,
    [terrain.DNGN_METAL_WALL] = true,
    [terrain.DNGN_TREE] = true,
    [terrain.DNGN_DEMONIC_TREE] = true,
    [terrain.DNGN_MANGROVE] = true,
    [terrain.DNGN_OPEN_DOOR] = true,
    [terrain.DNGN_CLOSED_DOOR] = true,
    [terrain.DNGN_OPEN_CLEAR_DOOR] = true,
    [terrain.DNGN_CLOSED_CLEAR_DOOR] = true,
    [terrain.DNGN_SEALED_DOOR] = true,
    [terrain.DNGN_SEALED_CLEAR_DOOR] = true,
}

-- Summon at exactly the chosen cell: fallback to an adjacent cell would
-- change a targeted invocation into a different action. Source actor::
-- skill_rdiv rounds the 256-scaled skill separately for HD and degree,
-- in that order; flooring first would lose fractional Invocations.
function plants.spawn(ctx, player, kind_id, x, y, base)
    local definition = catalog.get(categories.MONSTERS, kind_id)
    local training = power.training(ctx, player,
        skills.SK_INVOCATIONS, 256)
    local hd_bonus = roll.random_divide(ctx, training,
        256, streams.RELIGION)
    local degree = math.min(6, base + roll.random_divide(ctx,
        training, 5 * 256, streams.RELIGION))
    local live_hd = definition.hd + hd_bonus

    -- Monster placement rolls base HP before mgen.hd triggers its reroll.
    -- Both draws matter to subsequent monster-HP stream outcomes.
    hit_points.roll(ctx, definition.average_hp_10x)

    local scaled_average = hit_points.scaled_average(ctx,
        definition.average_hp_10x, definition.hd, live_hd)
    local live_hp = hit_points.roll(ctx, scaled_average)

    return summons.spawn(ctx, player, gods.FEDHAS, kind_id,
        degree, nil, {
            attitude = attitudes.FRIENDLY,
            source_category = categories.GODS,
            stream = streams.RELIGION,
            silent_failure = true,
            exact = {
                x = x,
                y = y,
            },
            hd = live_hd,
            hp = live_hp,
        })
end

-- The source preflight needs only one open cell. Scanning a fixed compass
-- order keeps the placement independent of Lua table or ECS query order.
function plants.briar_cells(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local cells = {}

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = origin.x + dx
                local y = origin.y + dy

                local occupant = ctx:actor_at(origin.level_id, x, y)

                if habitat.kind_at(ctx, monsters.MONS_BRIAR_PATCH,
                    origin.level_id, x, y) and
                    (not occupant or
                        not senses.player_sees_actor(ctx, occupant)) then
                    cells[#cells + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    return cells
end

-- Source grows one patch in every eligible neighboring square. An actor
-- collision at commitment can block only that square, not the whole wall.
function plants.wall_of_briars(ctx, player)
    local count = 0

    for _, cell in ipairs(plants.briar_cells(ctx, player)) do
        if plants.spawn(ctx, player, monsters.MONS_BRIAR_PATCH,
            cell.x, cell.y, 2) then
            count = count + 1
            ctx:emit("religion", "A briar patch grows up from the ground.")
        end
    end

    return count
end

-- Aiming, range, and habitat are checked before the action is timed.
-- Occupied cells are rejected here when their actor is visible.
function plants.grow_target(ctx, player, kind_id, dx, dy)
    if dx == 0 and dy == 0 then
        return nil, "Okay, then."
    end

    if math.max(math.abs(dx), math.abs(dy)) > 2 then
        return nil, "That's too far away."
    end

    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + dx
    local y = origin.y + dy

    if not habitat.kind_at(ctx, kind_id, origin.level_id, x, y) then
        return nil, "You can't grow that plant there."
    end

    if not ctx:visible(origin.level_id, origin.x, origin.y,
        2, x, y) then
        return nil, "You cannot see that place."
    end

    local occupant = ctx:actor_at(origin.level_id, x, y)

    if occupant and senses.player_sees_actor(ctx, occupant) then
        return nil, "That space is already occupied."
    end

    return {
        x = x,
        y = y,
    }
end

-- Grow a plant after the ability's failure roll. A blocked cell at this
-- point follows source successful no-effect behavior.
function plants.grow(ctx, player, kind_id, dx, dy)
    local cell = plants.grow_target(ctx, player, kind_id, dx, dy)

    if not cell then
        return false
    end

    local origin = ctx:get(player, component.POSITION)

    -- An invisible occupant is a paid successful no-effect use. Source
    -- checks that collision before rolling HD or summon duration.
    if ctx:actor_at(origin.level_id, cell.x, cell.y) then
        ctx:emit("religion",
            "Something you can't see occupies that space!")

        return false
    end

    return plants.spawn(ctx, player, kind_id, cell.x, cell.y, 3)
end

-- Source targeter_overgrow excludes vault vetoes and permanent walls.
-- A visible occupant blocks an open door before that door can be aimed.
function plants.can_overgrow(ctx, player, x, y)
    local origin = ctx:get(player, component.POSITION)
    local feature = ctx:cell(origin.level_id, x, y)

    if not feature or
        ctx:marker_property(origin.level_id, x, y,
            "veto_destroy") == "veto" then
        return false
    end

    local open_door = feature == terrain.DNGN_OPEN_DOOR or
        feature == terrain.DNGN_OPEN_CLEAR_DOOR
    local occupant = ctx:actor_at(origin.level_id, x, y)

    if open_door and occupant and occupant ~= player and
        senses.player_sees_actor(ctx, occupant) then
        return false
    end

    return digging.can_break(feature) or breakable[feature] == true
end

-- The center may be targeted through ordinary sight only if no opaque
-- feature interrupts the no-transparency sightline.
function plants.overgrow_target(ctx, player, dx, dy, reach)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + dx
    local y = origin.y + dy

    if math.max(math.abs(dx), math.abs(dy)) > reach or
        not ctx:visible_no_trans(origin.level_id,
            origin.x, origin.y, reach, x, y) then
        return nil, "You cannot see that place."
    end

    if not plants.can_overgrow(ctx, player, x, y) then
        return nil, "You cannot grow anything here."
    end

    return {
        x = x,
        y = y,
    }
end

-- Neighbor order is spatial and stable. Each cell gets its own weighted
-- roll, matching source _overgrow_wall rather than one plant for the area.
local function overgrown_kind(ctx)
    local choice = ctx:random(streams.RELIGION, 14)

    if choice < 4 then
        return overgrowth[1]
    elseif choice < 8 then
        return overgrowth[2]
    elseif choice < 12 then
        return overgrowth[3]
    end

    return overgrowth[choice - 8]
end

-- The source destroys terrain before summoning; a failed placement still
-- leaves floor. Mangroves uniquely revert to shallow water in DCSS.
local function overgrow_cell(ctx, player, level_id, x, y)
    local occupant = ctx:actor_at(level_id, x, y)

    -- Source monster_at excludes the player. A door beneath the player
    -- can be destroyed, although the new plant has no free placement.
    if occupant and occupant ~= player then
        ctx:emit("religion", "Something unseen blocks growth there.")

        return false
    end

    local old = ctx:cell(level_id, x, y)
    local replacement = old == terrain.DNGN_MANGROVE and
        terrain.DNGN_SHALLOW_WATER or terrain.DNGN_FLOOR

    -- destroy_wall clears blood from the old solid feature before its
    -- permanent floor edit; the saved grid keeps that cleanup.
    if ctx:cell_blood(level_id, x, y) then
        ctx:set_cell_blood(level_id, x, y, false)
    end

    ctx:set_cell(level_id, x, y, replacement)

    local kind_id = overgrown_kind(ctx)
    local creature = plants.spawn(ctx, player, kind_id, x, y, 3)

    if creature then
        ctx:emit("religion", "A plant grows as the wall is torn apart.")
    else
        ctx:emit("religion", "The wall falls apart, but nothing grows.")
    end

    return creature ~= nil
end

-- Center plus eight immediate neighbors is the source's affected set.
-- Only neighbors in the player's current no-transparency sight are added.
function plants.overgrow(ctx, player, dx, dy, reach)
    local center = plants.overgrow_target(ctx, player, dx, dy, reach)

    if not center then
        return 0
    end

    local origin = ctx:get(player, component.POSITION)
    local count = 0
    local affected = {}

    for y = center.y - 1, center.y + 1 do
        for x = center.x - 1, center.x + 1 do
            if plants.can_overgrow(ctx, player, x, y) and
                ctx:visible_no_trans(origin.level_id,
                    origin.x, origin.y, reach, x, y) then
                affected[#affected + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    for _, cell in ipairs(affected) do
        if overgrow_cell(ctx, player,
            origin.level_id, cell.x, cell.y) then
            count = count + 1
        end
    end

    return count
end

return plants
