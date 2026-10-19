local catalog = require("policy.catalog")
local items = require("policy.inventory.items")
local net = require("policy.combat.net")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local apportation = {}

-- Example: aiming at a visible floor stack pulls its top item unless a wall
-- or terrain unsafe for the player's species blocks the ray.
local function target(ctx, player, dx, dy)
    local origin = ctx:get(player, "core.position")
    local x = origin.x + dx
    local y = origin.y + dy
    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y, x, y, 7)

    if ray.blocked or ray.x ~= x or ray.y ~= y or
        not ctx:visible(origin.level_id, origin.x, origin.y, 7, x, y) then
        return nil, nil, "Something is in the way."
    end

    local destination = {
        level_id = origin.level_id,
        x = x,
        y = y,
    }
    local floor = items.at(ctx, destination)
    local item = floor[#floor]

    if not item then
        return nil, nil, "You don't see anything to apport there."
    end

    local feature = ctx:cell(origin.level_id, x, y)
    local choice = ctx:get(player, "core.player")
    local species = catalog.get("species", choice.species_id)

    if feature == "DNGN_LAVA" or
        (feature == "DNGN_DEEP_WATER" and
            species.habitat ~= "HT_WATER" and
            species.habitat ~= "HT_AMPHIBIOUS") then
        return nil, nil, "You don't see anything to apport there."
    end

    return item, ray, nil
end

-- Reject an invalid item ray before paying for the spell, including blocked or unsafe destinations.
function apportation.prepare(ctx, player, _, dx, dy)
    local item, _, rejection = target(ctx, player, dx, dy)

    if rejection then
        return rejection
    end

    if ctx:has(item, "core.equipped") then
        return "You cannot apport that!"
    end

    return nil
end

-- Randomly round fractional pull distance rather than biasing every cast downward.
local function random_divide(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Stop the pulled stack before terrain that would destroy it or cannot support the item.
local function item_survives(ctx, level_id, x, y, species)
    local feature = ctx:cell(level_id, x, y)

    return feature ~= "DNGN_LAVA" and
        (feature ~= "DNGN_DEEP_WATER" or
            species.habitat == "HT_WATER" or
            species.habitat == "HT_AMPHIBIOUS")
end

-- A thrown net can hold a monster; pulling it must release the held actor.
local function free_net(ctx, item)
    if not ctx:has(item, "projectile.net") then
        return
    end

    for _, monster in ipairs(ctx:query({ "projectile.held" })) do
        local held = ctx:get(monster, "projectile.held")

        if held.net == item then
            net.release(ctx, monster)

            return
        end
    end
end

-- Source: spl-transloc.cc:cast_apportation. Path cells exclude both the
-- player and the source item; movement distance may stop short of the player.
function apportation.resolve(ctx, player, intent, _, power)
    local item, ray = target(ctx, player, intent.dx, intent.dy)
    local origin = ctx:get(player, "core.position")
    local state = ctx:get(item, "core.item")
    local choice = ctx:get(player, "core.player")
    local species = catalog.get("species", choice.species_id)
    local path = ray.path
    path[#path] = nil
    local distance = #path
    local maximum = math.max(1, math.min(7,
        ctx:random("spell", 8) + random_divide(ctx, power, 7)))
    local index = math.max(-1, distance - maximum)

    free_net(ctx, item)

    if not ctx:get(item, "core.item") then
        return
    end

    local x = index < 0 and origin.x or path[index + 1].x
    local y = index < 0 and origin.y or path[index + 1].y

    -- Search back toward the source item when the first landing cell would
    -- destroy it, then merge with an identical floor stack if present.
    while index < distance and
        not item_survives(ctx, origin.level_id, x, y, species) do
        index = index + 1

        if index == distance then
            ctx:emit("spell", "Not with that terrain in the way!")

            return
        end

        x = path[index + 1].x
        y = path[index + 1].y
    end

    local position = {
        level_id = origin.level_id,
        x = x,
        y = y,
    }
    local merge = items.floor_stack(ctx, position, state, item)

    if merge then
        local stack = ctx:get(merge, "core.item")
        stack.quantity = stack.quantity + state.quantity
        ctx:set(merge, "core.item", stack)
        ctx:destroy(item)
    else
        ctx:set(item, "core.position", position)
    end

    local suffix = state.quantity > 1 and "s" or ""
    ctx:emit("spell", "Yoink! You pull the item" .. suffix ..
        " towards yourself.")
end

registry.add("SPELL_APPORTATION", apportation)
