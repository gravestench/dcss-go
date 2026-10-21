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

-- Source gate direction is checked before the action costs time. A revisit
-- uses the saved Vestibule entry; the first visit asks Go to stage the map.
function travel.prepare(ctx, position, downstairs, state)
    local feature = ctx:cell(position.level_id, position.x, position.y)
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
    end

    return { message = "You return from Hell." }
end

register.policy({
    id = "world.hell.commit_travel",
    run = travel.commit,
})

return travel
