local abilities = require("ids.abilities")
local barbs = require("policy.combat.barbs")
local component = require("constants.component")
local flight = require("policy.combat.flight")
local movement = require("policy.abilities.movement")
local mutations = require("ids.mutations")
local registry = require("policy.abilities.registry")
local levels = require("policy.mutations.levels")
local terrain = require("constants.terrain")
local water = require("policy.character.water")

local hop = {}

-- Keep the landing choice in the ability policy so preview and resolution agree on range and passability.
-- Example: hop.range(2) allows a six-cell hop before visibility and landing checks.
function hop.range(level)
    return 2 + level * 2
end

-- Preflight rejects a held or cooling-down hop before mutation RNG or movement can occur.
function hop.prepare(ctx, player, input)
    local cooldown = ctx:get(player, component.ABILITY_COOLDOWNS)

    if cooldown and cooldown.hop_aut > 0 then
        return "Your legs are too worn out to hop."
    end

    if ctx:has(player, component.WATER_HOLD) then
        return "You cannot hop while held."
    end

    local position = ctx:get(player, component.POSITION)
    local dx = input.dx or 0
    local dy = input.dy or 0
    local level = levels.effective(ctx,
        player, mutations.MUT_HOP)

    if dx == 0 and dy == 0 then
        return "Okay, then."
    end

    if math.max(math.abs(dx), math.abs(dy)) > hop.range(level) then
        return "That's out of range!"
    end

    if not ctx:visible(position.level_id, position.x, position.y,
        hop.range(level), position.x + dx, position.y + dy) then
        return "You cannot hop there."
    end

    return nil
end

-- Destination selection uses the same visible, walkable cells that resolution can reach.
local function destination(ctx, player, position, target_x, target_y, range)
    local chosen_x
    local chosen_y
    local seen = 0
    local airborne = flight.permanent(ctx, player)
    local swimmer = water.can_swim(ctx, player)

    for y = target_y - 2, target_y + 2 do
        for x = target_x - 2, target_x + 2 do
            local distance = math.max(math.abs(x - position.x),
                math.abs(y - position.y))
            local feature = ctx:cell(position.level_id, x, y)
            local safe = airborne or
                (feature ~= terrain.DNGN_LAVA and
                    (feature ~= terrain.DNGN_DEEP_WATER or swimmer))

            if distance > 0 and distance <= range and safe and
                ctx:walkable(position.level_id, x, y) and
                not ctx:actor_at(position.level_id, x, y) and
                ctx:visible(position.level_id, position.x,
                    position.y, range, x, y) then
                seen = seen + 1

                if ctx:random("mutation", seen) == 0 then
                    chosen_x = x
                    chosen_y = y
                end
            end
        end
    end

    return chosen_x, chosen_y
end

-- A failed landing still follows the grasp escape check; a successful move writes a random cooldown.
function hop.resolve(ctx, player, intent, elapsed_aut)
    local position = ctx:get(player, component.POSITION)
    local level = levels.effective(ctx, player, mutations.MUT_HOP)
    local x, y = destination(ctx, player, position, position.x + intent.dx,
        position.y + intent.dy, hop.range(level))

    if not movement.escape_grasp(ctx, player, 2) then
        return
    end

    if not x then
        ctx:emit("mutation", "You tried to hop, but there was no room to land!")
        return
    end

    ctx:move_actor(player, position.level_id, x, y)
    ctx:emit("mutation", "Boing!")

    local cooldown = ctx:get(player, component.ABILITY_COOLDOWNS) or {
        hop_aut = 0,
        word_of_chaos_aut = 0,
    }

    cooldown.hop_aut = (12 + ctx:random("mutation", 13)) * 10

    if ctx:has(player, component.ABILITY_COOLDOWNS) then
        ctx:set(player, component.ABILITY_COOLDOWNS, cooldown)
    else
        ctx:add(player, component.ABILITY_COOLDOWNS, cooldown)
    end

    -- Source Hop moves the player through ordinary space and pays barbs
    -- damage after the landing and cooldown have been committed.
    barbs.moved(ctx, player, elapsed_aut)
end

registry.add(abilities.HOP, {
    mutation_id = mutations.MUT_HOP,
    name = "Hop",
    range = hop.range,
    prepare = hop.prepare,
    resolve = hop.resolve,
})

return hop
