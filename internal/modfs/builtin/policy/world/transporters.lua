-- Named DES markers resolve to saved one-way links. The level grid owns the
-- two features; this policy owns player passage and nearby monster transit.
local barbs = require("policy.combat.barbs")
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local modes = require("constants.follower_travel")
local habitat = require("policy.combat.monster_habitat")
local follower_wave = require("policy.world.follower_wave")
local relocation = require("policy.world.monster_relocation")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local ids = require("constants.transporter")

local transporters = {}

-- A replaced level invalidates learned portal coordinates. Abyss shifts
-- supply remaps for pairs retained with the moving window; a fresh Abyss
-- region supplies none. Knowledge on other levels stays untouched.
function transporters.remap_knowledge(ctx, player, level_id, remaps)
    local knowledge = ctx:get(player,
        component.TRANSPORTER_KNOWLEDGE)

    if not knowledge then
        return
    end

    local prefix = level_id .. ":"
    local links = {}

    for key, destination in pairs(knowledge.links) do
        if key:sub(1, #prefix) ~= prefix then
            links[key] = destination
        else
            local remap = remaps and remaps[key]

            if remap then
                links[remap.key] = remap.destination
            end
        end
    end

    knowledge.links = links
    ctx:set(player, component.TRANSPORTER_KNOWLEDGE,
        knowledge)
end

-- Search outward from the landing for a free cell suited to this monster.
-- The same deterministic choice is used by command preparation and travel.
local function nearby_home(ctx, monster, level_id, x, y)
    for radius = 1, 5 do
        for offset_y = -radius, radius do
            for offset_x = -radius, radius do
                if math.max(math.abs(offset_x), math.abs(offset_y)) ==
                    radius then
                    local candidate_x = x + offset_x
                    local candidate_y = y + offset_y

                    if habitat.at(ctx, monster, level_id,
                        candidate_x, candidate_y) and
                        not ctx:actor_at(level_id,
                            candidate_x, candidate_y) then
                        return candidate_x, candidate_y
                    end
                end
            end
        end
    end
end

-- Decode only the link painted on this source feature. The generic marker
-- property API reads the same saved record after restoring a game.
local function link(ctx, position)
    local level_id = position.level_id
    local x = position.x
    local y = position.y
    local target_x = ctx:marker_property(level_id, x, y,
        ids.DESTINATION_X)
    local target_y = ctx:marker_property(level_id, x, y,
        ids.DESTINATION_Y)

    if not target_x or not target_y then
        return nil, "The transporter doesn't lead anywhere."
    end

    local destination_x = tonumber(target_x)
    local destination_y = tonumber(target_y)

    if not destination_x or not destination_y then
        error("transporter link has nonnumeric destination")
    end

    return destination_x, destination_y
end

-- Refuse an unsafe destination before a command can charge action time.
-- An occupant may be pushed to nearby habitat instead of blocking passage.
function transporters.prepare(ctx, position)
    if ctx:cell(position.level_id, position.x, position.y) ~=
        terrain.DNGN_TRANSPORTER then
        return nil, "There is no transporter here."
    end

    local x, y = link(ctx, position)

    if not x then
        return nil, y
    end

    if not ctx:walkable(position.level_id, x, y) then
        return nil, "The transporter is blocked on the other side!"
    end

    local occupant = ctx:actor_at(position.level_id, x, y)
    local home_x
    local home_y

    if occupant then
        home_x, home_y = nearby_home(ctx, occupant,
            position.level_id, x, y)

        if not home_x then
            return nil,
                "The transporter is blocked by a creature on the other side!"
        end
    end

    return {
        x = x,
        y = y,
        occupant = occupant,
        home_x = home_x,
        home_y = home_y,
    }
end

-- The player learns the actual destination only after passing through the
-- source; this durable map can later distinguish unknown portals in the UI.
local function remember(ctx, player, origin, destination)
    local current = ctx:get(player, component.TRANSPORTER_KNOWLEDGE)
    local knowledge = current or { links = {} }
    local key = table.concat({
        origin.level_id,
        origin.x,
        origin.y,
    }, ":")

    knowledge.links[key] = destination.x .. ":" .. destination.y

    if current then
        ctx:set(player, component.TRANSPORTER_KNOWLEDGE, knowledge)
    else
        ctx:add(player, component.TRANSPORTER_KNOWLEDGE, knowledge)
    end
end

-- Transport eligible nearby monsters to free landing cells after the player
-- arrives, keeping the source actor's identity and ECS state intact. An
-- unplaced actor can still connect another follower in the source wave;
-- only successful movements consume one of the source's 18 slots.
local function followers(ctx, origin, destination)
    local moved = 0
    local selected = follower_wave.select(ctx, ctx:player(),
        origin, modes.TRANSPORTER)

    for _, entity in ipairs(selected) do
        if moved >= 18 then
            break
        end

        local x, y = nearby_home(ctx, entity,
            origin.level_id, destination.x, destination.y)

        if x then
            relocation.move(ctx, entity, origin.level_id, x, y)
            moved = moved + 1
        end
    end
end

-- Move the landing occupant first, then the player; a short source cloud,
-- follower transit, and durable discovery happen only after passage.
function transporters.take(ctx, player, elapsed_aut)
    local origin = ctx:get(player, component.POSITION)
    local destination, refusal = transporters.prepare(ctx, origin)

    if not destination then
        ctx:emit("stairs", refusal)
        return false
    end

    barbs.moved(ctx, player, elapsed_aut)

    if ctx:get(player, component.HEALTH).current <= 0 then
        return false
    end

    if destination.occupant then
        relocation.move(ctx, destination.occupant, origin.level_id,
            destination.home_x, destination.home_y)
    end

    ctx:move_actor(player, origin.level_id,
        destination.x, destination.y)
    cloud.place(ctx, cloud_ids.CLOUD_TLOC_ENERGY, player,
        origin.level_id, origin.x, origin.y,
        (1 + ctx:random(streams.CLOUDS, 3)) * 10)
    followers(ctx, origin, destination)
    remember(ctx, player, origin, destination)
    ctx:emit("stairs",
        "You enter the transporter and appear at another place.")

    return true
end

return transporters
