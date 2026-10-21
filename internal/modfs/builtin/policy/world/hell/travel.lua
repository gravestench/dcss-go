-- Theory of operation: an outside Hell arch remembers its exact source
-- cell, then opens the one persistent Vestibule. A later outside arch
-- updates that return site without redrawing the Vestibule. The exit arch
-- returns to the latest site, using the shared safe-landing policy if its
-- original cell is occupied. Go stages and commits the level transaction.
local component = require("constants.component")
local domains = require("constants.portal_domains")
local operations = require("constants.hell_travel")
local terrain = require("constants.terrain")
local landing = require("policy.world.stair_landing")
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local branch_levels = require("policy.generation.branch_levels")

local travel = {}

-- A copy of the current cell becomes the newest outside return gate. It is
-- part of the prepared plan and does not mutate a previous save record.
local function origin(position)
    return {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    }
end

-- The branch catalog owns gate identity. Iterating its registered IDs
-- keeps new Hell children out of a second hand-maintained dispatch table.
local function child_for_gate(feature)
    for _, branch in ipairs(catalog.all(categories.BRANCHES)) do

        if branch.parent_id == branches.BRANCH_VESTIBULE and
            branch.entry_feature == feature then
            return branch
        end
    end

    return nil
end

-- A saved entry is the stable landing for a revisited floor. Monsters may
-- later occupy that cell, so the shared landing policy chooses nearby space.
local function saved_floor(state, branch_id, depth)
    for _, floor in ipairs(state.floors or {}) do
        if floor.branch_id == branch_id and floor.local_depth == depth then
            return floor
        end
    end

    return nil
end

-- Every branch exit returns beside its own Vestibule gate. The gate is
-- authoritative terrain, so a modded Vestibule still determines the site.
local function vestibule_gate(ctx, state, branch)
    local level_id = state.vestibule_level_id
    local width, height = ctx:level_size(level_id)

    if not width then
        error("Hell return has no Vestibule")
    end

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if ctx:cell(level_id, x, y) == branch.entry_feature then
                local landing_x, landing_y = landing.find(ctx, level_id, x, y)

                return {
                    level_id = level_id,
                    x = landing_x,
                    y = landing_y,
                }
            end
        end
    end

    error("Hell return has no " .. branch.id .. " gate")
end

-- One plan covers both first generation and revisit. Go decides whether a
-- new level must be staged, while Lua determines branch and depth.
local function branch_floor(ctx, state, branch, depth)
    local level_id = branch_levels.id(branch.id, depth)
    local floor = saved_floor(state, branch.id, depth)
    local portal = {
        domain = domains.HELL,
        operation = operations.BRANCH_FLOOR,
        branch_id = branch.id,
        local_depth = depth,
        level_id = level_id,
    }

    if floor then
        local x, y = landing.find(ctx, level_id, floor.entry_x,
            floor.entry_y)

        portal.destination = {
            level_id = level_id,
            x = x,
            y = y,
        }
    end

    return {
        portal = portal,
        cost = 10,
    }
end

-- Source gate direction is checked before the action costs time. A revisit
-- uses the saved Vestibule entry; the first visit asks Go to stage the map.
function travel.prepare(ctx, position, downstairs, state)
    local feature = ctx:cell(position.level_id, position.x, position.y)
    local current_branch = ctx:level_branch(position.level_id)
    local portal

    if feature == terrain.DNGN_ENTER_HELL then
        if not downstairs then
            return { message = "There are no stairs up here." }
        end

        portal = {
            domain = domains.HELL,
            operation = operations.ENTER,
            return_site = origin(position),
        }

        -- The Go-to-Lua boundary represents an absent optional save as a
        -- null value, so test the durable field rather than table truthiness.
        if state and state.vestibule_level_id then
            local x, y = landing.find(ctx, state.vestibule_level_id,
                state.entry_x, state.entry_y)

            portal.destination = {
                level_id = state.vestibule_level_id,
                x = x,
                y = y,
            }
        end
    elseif feature == terrain.DNGN_EXIT_HELL then
        if downstairs then
            return { message = "There are no stairs down here." }
        end

        if not state or not state.return_site then
            error("Hell exit has no saved outside gate")
        end

        local site = state.return_site
        local x, y = landing.find(ctx, site.level_id, site.x, site.y)

        portal = {
            domain = domains.HELL,
            operation = operations.RETURN,
            destination = {
                level_id = site.level_id,
                x = x,
                y = y,
            },
        }
    elseif current_branch == branches.BRANCH_VESTIBULE then
        local branch = child_for_gate(feature)

        if branch then
            if not downstairs then
                return { message = "There are no stairs up here." }
            end

            if not state or not state.vestibule_level_id then
                error("Hell branch gate has no saved Vestibule")
            end

            return branch_floor(ctx, state, branch, 1)
        end
    else
        local branch = catalog.get(categories.BRANCHES, current_branch)

        if branch.parent_id == branches.BRANCH_VESTIBULE then
            if feature == branch.escape_feature then
                if downstairs then
                    return { message = "There are no stairs down here." }
                end

                portal = {
                    domain = domains.HELL,
                    operation = operations.BRANCH_RETURN,
                    branch_id = branch.id,
                    destination = vestibule_gate(ctx, state, branch),
                }
            elseif feature == terrain.DNGN_STONE_STAIRS_DOWN_I then
                if not downstairs then
                    return { message = "There are no stairs up here." }
                end

                local depth = ctx:level_depth(position.level_id) + 1

                if depth <= branch.depth then
                    return branch_floor(ctx, state, branch, depth)
                end
            end
        end
    end

    if not portal then
        return nil
    end

    return {
        portal = portal,
        cost = 10,
    }
end

-- The transport kernel has already checked the landing and action clock.
-- Lua moves the ECS player and chooses the source branch entry message.
function travel.commit(ctx, input)
    local destination = input.destination
    local player = ctx:player()
    local position = ctx:get(player, component.POSITION)

    if not position or not destination or
        not ctx:walkable(destination.level_id, destination.x,
            destination.y) or
        ctx:actor_at(destination.level_id, destination.x,
            destination.y) then
        error("Hell portal destination is unavailable")
    end

    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)

    if input.operation == operations.ENTER then
        local branch = catalog.get(categories.BRANCHES,
            branches.BRANCH_VESTIBULE)

        return { message = branch.entry_message }
    elseif input.operation == operations.BRANCH_FLOOR then
        local branch = catalog.get(categories.BRANCHES, input.branch_id)

        return { message = branch.entry_message }
    elseif input.operation == operations.BRANCH_RETURN then
        return { message = "You return to the Vestibule of Hell." }
    end

    return { message = "You return from Hell." }
end

register.policy({
    id = "world.hell.commit_travel",
    run = travel.commit,
})

return travel
