local spells = require("ids.spells")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local net = require("policy.combat.net")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local golubria = {}

-- Passage endpoints need free walkable floor on the caster's current level.
local function clear(ctx, origin, x, y)
    if ctx:cell(origin.level_id, x, y) ~= terrain_ids.DNGN_FLOOR or
        ctx:actor_at(origin.level_id, x, y) then
        return false
    end

    local distance = math.max(math.abs(x - origin.x),
        math.abs(y - origin.y))
    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y, x, y, distance)

    return not ray.blocked
end

-- Search nearby clear floor cells reachable from the caster before randomizing passage endpoints.
local function candidates(ctx, origin, center)
    local found = {}

    for dy = -2, 2 do
        for dx = -2, 2 do
            local x, y = center.x + dx, center.y + dy

            if clear(ctx, origin, x, y) then
                found[#found + 1] = { x = x, y = y }
            end
        end
    end

    return found
end

-- Save reciprocal trap markers before painting terrain; either endpoint must
-- know its partner when an actor steps onto it later.
local function pair(ctx, player, origin, first, second)
    local left = ctx:create()
    local right = ctx:create()
    ctx:add(left, component.GOLUBRIA_PASSAGE, {
        owner = player,
        pair_id = ctx:id(right),
        level_id = origin.level_id,
        x = first.x,
        y = first.y,
    })
    ctx:add(right, component.GOLUBRIA_PASSAGE, {
        owner = player,
        pair_id = ctx:id(left),
        level_id = origin.level_id,
        x = second.x,
        y = second.y,
    })
    ctx:set_cell(origin.level_id, first.x, first.y,
        terrain_ids.DNGN_PASSAGE_OF_GOLUBRIA)
    ctx:set_cell(origin.level_id, second.x, second.y,
        terrain_ids.DNGN_PASSAGE_OF_GOLUBRIA)
end

-- Example: golubria.trigger(ctx, actor) moves the entrant to the linked end
-- and consumes only the entered marker, leaving the far passage usable.
function golubria.trigger(ctx, actor)
    local position = ctx:get(actor, component.POSITION)

    if not position or ctx:cell(position.level_id, position.x, position.y) ~=
        terrain_ids.DNGN_PASSAGE_OF_GOLUBRIA then
        return
    end

    for _, marker in ipairs(ctx:query({ component.GOLUBRIA_PASSAGE })) do
        local state = ctx:get(marker, component.GOLUBRIA_PASSAGE)

        if state.level_id == position.level_id and state.x == position.x and
            state.y == position.y then
            local other = ctx:entity(state.pair_id)
            local destination = other and
                ctx:get(other, component.GOLUBRIA_PASSAGE)

            if not destination then
                ctx:emit("spell", "This passage doesn't lead anywhere!")
                return
            end

            if ctx:actor_at(position.level_id,
                destination.x, destination.y) then
                ctx:emit("spell", "This passage seems to be blocked by something!")
                return
            end

            net.release(ctx, actor)
            ctx:move_actor(actor, position.level_id,
                destination.x, destination.y)
            ctx:set_cell(position.level_id, position.x, position.y,
                terrain_ids.DNGN_FLOOR)
            ctx:destroy(marker)

            if actor == ctx:player() then
                ctx:emit("spell", "You enter the passage of Golubria.")
            else
                ctx:emit("spell", "A monster enters the passage of Golubria.")
            end

            return
        end
    end
end

-- Source: spl-transloc.cc:cast_golubrias_passage. Both trap markers and their
-- terrain are saved; entering either end consumes only the entered end.
function golubria.prepare(ctx, player, _, dx, dy)
    local origin = ctx:get(player, component.POSITION)
    local aimed = { x = origin.x + dx, y = origin.y + dy }

    if not ctx:walkable(origin.level_id, aimed.x, aimed.y) then
        return "You can't create a passage there!"
    end

    if #candidates(ctx, origin, aimed) == 0 or
        #candidates(ctx, origin, origin) < 2 then
        return "Creating a passage of Golubria requires sufficient empty space."
    end
end

-- Sample a far endpoint near the aim and a near endpoint around the player;
-- failure to find a valid pair does not paint half a passage.
function golubria.resolve(ctx, player, intent)
    local origin = ctx:get(player, component.POSITION)
    local aimed = { x = origin.x + intent.dx, y = origin.y + intent.dy }
    local far = candidates(ctx, origin, aimed)
    local near = candidates(ctx, origin, origin)
    local first = far[ctx:random("spell", #far) + 1]
    local second

    for _ = 1, 100 do
        local candidate = near[ctx:random("spell", #near) + 1]

        if candidate.x ~= first.x or candidate.y ~= first.y then
            second = candidate
            break
        end
    end

    if not second then
        for _, candidate in ipairs(near) do
            if candidate.x ~= first.x or candidate.y ~= first.y then
                second = candidate
                break
            end
        end
    end

    if not second then
        error("Golubria candidates changed after no-time validation")
    end

    pair(ctx, player, origin, first, second)
    ctx:emit("spell", "Two passages of Golubria open in the floor.")
end

registry.add(spells.SPELL_GOLUBRIAS_PASSAGE, {
    prepare = golubria.prepare,

    resolve = golubria.resolve,
})

return golubria
