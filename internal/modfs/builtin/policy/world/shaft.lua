-- Magical shafts use branch and terrain facts to decide whether the player
-- can fall. A saved request lets the Go session stage a destination that
-- may not exist when Lua evaluates the wrath or trap effect.
local catalog = require("policy.catalog")
local branch_flags = require("constants.branch_flags")
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local component = require("constants.component")
local dislodge = require("policy.combat.dislodge")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local targets = require("policy.ai.targets")

local shaft = {}
local LANDING_ATTEMPTS = 1000
local SIGHT_RADIUS = 7

-- Source is_connected_branch checks cross-level travel, not the islanded
-- layout flag. A no-shafts branch can still have ordinary downward stairs.
local function blocked_branch(branch)
    for _, flag in ipairs(branch.flags or {}) do
        if flag == branch_flags.NO_X_LEVEL_TRAVEL or
            flag == branch_flags.NO_SHAFTS then
            return true
        end
    end

    return false
end

-- Source feat_is_shaftable requires dry, solid floor and excludes stairs
-- and portals. Existing grid walkability rejects solid walls and trees;
-- the named water and travel features close the remaining source gaps.
local function shaftable_cell(ctx, position)
    local feature = ctx:cell(position.level_id,
        position.x, position.y)

    if not feature or not ctx:walkable(position.level_id,
        position.x, position.y) or
        feature == terrain.DNGN_SHALLOW_WATER or
        feature == terrain.DNGN_DEEP_WATER or
        feature == terrain.DNGN_OPEN_SEA or
        feature == terrain.DNGN_LAVA or
        feature == terrain.DNGN_TOXIC_BOG then
        return false
    end

    return not feature:find("STAIRS", 1, true) and
        not feature:find("ENTER", 1, true) and
        not feature:find("EXIT", 1, true) and
        feature ~= terrain.DNGN_PASSAGE_OF_GOLUBRIA and
        feature ~= terrain.DNGN_TRANSPORTER and
        feature ~= terrain.DNGN_TRANSPORTER_LANDING
end

-- Choose the same one-to-three-floor fall as generic_shaft_dest. The
-- branch bottom bounds the fall, and dangerous ends cannot be entered
-- from more than one floor above in a single shaft.
function shaft.destination(ctx, player, stream)
    local position = ctx:get(player, component.POSITION)
    local branch_id = ctx:level_branch(position.level_id)
    local branch = catalog.get(categories.BRANCHES, branch_id)
    local depth = ctx:level_depth(position.level_id)

    if blocked_branch(branch) or depth >= branch.depth or
        not shaftable_cell(ctx, position) then
        return nil
    end

    local distance = 1 + ctx:random(stream,
        math.min(depth, 3))
    local destination = math.min(branch.depth, depth + distance)

    for _, flag in ipairs(branch.flags or {}) do
        if flag == branch_flags.DANGEROUS_END and
            destination == branch.depth and
            branch.depth - depth > 1 then
            destination = destination - 1

            break
        end
    end

    return {
        origin_level_id = position.level_id,
        branch_id = branch_id,
        local_depth = destination,
    }
end

-- The message precedes Mountain Boots resistance in the source. Boots
-- still consume Ignis's shaft branch, without writing a travel request.
function shaft.ignis(ctx, player, stream)
    local destination = shaft.destination(ctx, player, stream)

    if not destination then
        return false
    end

    ctx:emit("religion",
        "Ignis burns the ground from beneath your feet!")

    if dislodge.resists(ctx, player) then
        ctx:emit("warning",
            "Your boots keep you from falling into an unexpected shaft.")

        return true
    end

    ctx:add(player, component.PENDING_SHAFT, destination)

    return true
end

-- Terrain hazards, clouds, a teleport mask, or an adjacent slime wall
-- disqualify a landing even when the cell itself is mechanically walkable.
local function landing_ground(ctx, level_id, x, y, environment)
    local feature = ctx:cell(level_id, x, y)

    return ctx:walkable(level_id, x, y) and
        feature ~= terrain.DNGN_DEEP_WATER and
        feature ~= terrain.DNGN_LAVA and
        feature ~= terrain.DNGN_TOXIC_BOG and
        not ctx:actor_at(level_id, x, y) and
        not environment.clouds.at(ctx, level_id, x, y) and
        environment.teleport_landings.allowed(ctx,
            level_id, x, y) and
        environment.slime_walls.adjacent(ctx,
            level_id, x, y) == 0
end

-- A safe source landing also has no hostile monster in ordinary sight.
-- A hostile behind a wall cannot see the player on arrival.
local function safe_landing(ctx, level_id, x, y, nearby,
    environment)
    if not landing_ground(ctx, level_id, x, y,
        environment) then
        return false
    end

    for _, position in ipairs(nearby) do
        local distance = math.max(math.abs(position.x - x),
            math.abs(position.y - y))

        if distance <= SIGHT_RADIUS and
            ctx:visible(level_id, x, y, SIGHT_RADIUS,
                position.x, position.y) then
            return false
        end
    end

    return true
end

-- Build the threat list once for the thousand source placement attempts.
-- An unseen hostile still makes the candidate unsafe if the landing cell
-- itself would see it; friendly monsters do not block nearby cells.
local function hostile_positions(ctx, level_id)
    local found = {}

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if entity ~= ctx:player() then
            local position = ctx:get(entity, component.POSITION)
            local health = ctx:get(entity, component.HEALTH)

            if position.level_id == level_id and
                health.current > 0 and
                targets.attitude(ctx, entity) ~= attitudes.FRIENDLY then
                found[#found + 1] = position
            end
        end
    end

    return found
end

-- Match _shaft_safely's independent x/y draws before a bounded fallback.
-- If a crowded floor has no fully safe candidate, the fallback still
-- requires nonlethal, open ground so travel never creates instant death.
function shaft.landing(ctx, input)
    local level_id = input.level_id
    local width, height = ctx:level_size(level_id)
    local nearby = hostile_positions(ctx, level_id)

    -- These owners are needed only when a fall lands. Loading them during
    -- the ruleset bootstrap would expand every startup's module graph.
    local environment = {
        clouds = require("policy.clouds.placement"),
        teleport_landings = require("policy.world.teleport_landings"),
        slime_walls = require("policy.world.slime_walls"),
    }

    if not width or not height or width <= 0 or height <= 0 then
        error("shaft destination level is missing")
    end

    for _ = 1, LANDING_ATTEMPTS do
        local x = ctx:random(streams.TRAPS, width)
        local y = ctx:random(streams.TRAPS, height)

        if safe_landing(ctx, level_id, x, y, nearby,
            environment) then
            return { x = x, y = y }
        end
    end

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if landing_ground(ctx, level_id, x, y,
                environment) then
                return { x = x, y = y }
            end
        end
    end

    error("shaft destination has no legal landing")
end

register.policy({
    id = "world.shaft_landing",
    run = shaft.landing,
})

return shaft
