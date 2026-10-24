-- Xom's three divinations reuse the map-knowledge owner but keep separate
-- source parameters and narration. Detection markers will use their own
-- spatial owner rather than pretending to be terrain.
local channels = require("constants.message_channels")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local events = require("ids.xom_events")
local habitat = require("policy.combat.monster_habitat")
local mapping = require("policy.world.magic_mapping")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local vision = require("policy.character.vision")

local effect = {}

-- Source stepdown_value(severity, 10, 10, 40, 45) grows slowly and caps
-- mapping power, so very severe acts do not trivially map the whole floor.
local function mapping_power(severity)
    if severity < 10 then
        return severity
    end

    local stepped = math.floor(10 * math.log(1 + severity / 10) /
        math.log(2))

    return math.min(45, stepped)
end

-- random2avg(power * 2, 2) averages two source draws for map proportion.
-- MapCell owns remembered terrain and leaves actual sight unchanged.
local function magic_mapping(ctx, player, severity, stream)
    local power = mapping_power(severity)
    local first = ctx:random(stream, math.max(1, power * 2))
    local second = ctx:random(stream, math.max(1, power * 2 + 1))
    local proportion = 50 + math.floor((first + second) / 2)
    local count = mapping.reveal(ctx, player, 5 + power,
        proportion, stream)

    if count > 0 then
        ctx:emit(channels.RELIGION,
            "Xom reveals part of your surroundings!")
    else
        ctx:emit(channels.RELIGION,
            "Xom leaves you momentarily disoriented.")
    end

    return count
end

-- The source item detector reaches seven to thirteen cells beyond its
-- supplied power. Only placed floor items create map markers; multiple
-- stacks at one coordinate are one map fact, not multiple detections.
local function detect_items(ctx, player, severity, stream)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        return 0
    end

    local radius = 7 + ctx:random(stream, 7) + severity
    local counted = {}
    local found = 0

    for _, item in ipairs(ctx:query({
        component.ITEM,
        component.POSITION,
    })) do
        local position = ctx:get(item, component.POSITION)
        local distance = math.max(math.abs(position.x - origin.x),
            math.abs(position.y - origin.y))
        local key = position.x .. ":" .. position.y

        if position.level_id == origin.level_id and
            distance <= radius and not counted[key] and
            not ctx:visible(origin.level_id, origin.x, origin.y,
                7, position.x, position.y) then
            counted[key] = true

            if ctx:detect_item(origin.level_id,
                position.x, position.y) then
                found = found + 1
            end
        end
    end

    ctx:emit(channels.RELIGION,
        found > 0 and "Xom reveals hidden items!" or
        "Xom detects nothing new.")

    return found
end

-- Detection deliberately gives only an approximate map location. A
-- strong effect fuzzes within one cell, while weak effects may fuzz two;
-- an invalid or already used candidate leaves the actual site in place.
local function sensed_location(ctx, player, monster, position, severity,
    stream, marked)
    local power = math.max(1, severity)
    local radius = power >= 50 and 1 or 2
    local chance = math.max(10,
        100 - math.floor(90 * (power - 1) / 59))
    local x, y = position.x, position.y
    local origin = ctx:get(player, component.POSITION)
    local sight = vision.radius(ctx, player)

    if ctx:random(stream, 100) >= chance then
        return x, y
    end

    local diameter = radius * 2 + 1

    for _ = 1, 5 do
        local candidate_x = position.x + ctx:random(stream, diameter) -
            radius
        local candidate_y = position.y + ctx:random(stream, diameter) -
            radius
        local key = candidate_x .. ":" .. candidate_y

        if not marked[key] and
            ctx:remembered(position.level_id,
                candidate_x, candidate_y) and
            habitat.at(ctx, monster, position.level_id,
                candidate_x, candidate_y) and
            not ctx:visible(position.level_id, origin.x, origin.y,
                sight, candidate_x, candidate_y) then
            x, y = candidate_x, candidate_y
        end
    end

    return x, y
end

-- Clear prior sensed positions before scanning live hidden monsters.
-- The saved level owns glyph locations, while ECS remains the source of
-- monster existence, health, habitat, and actual position.
local function detect_creatures(ctx, player, severity, stream)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        return 0
    end

    local radius = 9 + ctx:random(stream, 7) + severity
    local marked = {}
    local found = 0

    ctx:clear_detected_creatures(origin.level_id)

    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local health = ctx:get(monster, component.HEALTH)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and
                position.level_id == origin.level_id and
                distance <= radius and
                not senses.player_sees_actor(ctx, monster) then
                found = found + 1

                local x, y = sensed_location(ctx, player, monster, position,
                    severity, stream, marked)
                local key = x .. ":" .. y
                local actor = ctx:get(monster, component.ACTOR)
                local definition = catalog.get(categories.MONSTERS,
                    actor.kind_id)
                local kind_id = definition.genus_id or actor.kind_id

                if not marked[key] and
                    ctx:detect_creature(origin.level_id,
                        x, y, kind_id) then
                    marked[key] = true
                end
            end
        end
    end

    ctx:emit(channels.RELIGION,
        found > 0 and "Xom reveals nearby creatures!" or
        "Xom detects nothing new.")

    return found
end

-- Unknown divinations fail until their own live map-marker behavior is
-- implemented; a source event must never succeed as narration alone.
function effect.apply(ctx, player, event_id, severity, request)
    local stream = request and request.stream or streams.RELIGION

    if event_id == events.GOOD_MAGIC_MAPPING then
        return magic_mapping(ctx, player, severity, stream)
    end

    if event_id == events.GOOD_DETECT_ITEMS then
        return detect_items(ctx, player, severity, stream)
    end

    if event_id == events.GOOD_DETECT_CREATURES then
        return detect_creatures(ctx, player, severity, stream)
    end

    error("divination effect received another Xom event")
end

return effect
