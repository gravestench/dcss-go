-- Theory of operation: a Jiyva slime examines the item stack under its
-- current cell before choosing any spell, attack, or move. A successful
-- meal consumes the monster action, changes real floor item entities, and
-- heals that same saved actor. No-Jiyva cells stop the entire attempt.
local catalog = require("policy.catalog")
local behaviors = require("constants.ai_behaviors")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local classes = require("ids.object_classes")
local component = require("constants.component")
local identity = require("policy.religion.jiyva.identity")
local growth = require("policy.religion.jiyva.growth")
local items = require("policy.inventory.items")
local edibility = require("policy.religion.jiyva.items")
local cells = require("policy.religion.jiyva.cells")
local senses = require("policy.character.senses")
local silence = require("policy.world.silence")
local splitting = require("policy.religion.jiyva.splitting")
local streams = require("constants.rng_streams")
local flight = require("policy.combat.flight")
local terrain = require("constants.terrain")

local feeding = {}

local MAX_HEAL = 50
local MAX_MONSTER_HP = 10000

-- Gold above 500 is partly digested through two source dice, limiting how
-- quickly one large pile heals a slime while preserving its remainder.
local function gold_portion(ctx, quantity)
    if quantity <= 500 then
        return quantity
    end

    local sides = math.floor((quantity - 500) / 2)

    if sides == 0 then
        return 500
    end

    return 500 + ctx:random(streams.RELIGION, sides) + 1 +
        ctx:random(streams.RELIGION, sides) + 1
end

-- The source announces only the first audible meal, with a different
-- adjective if the player can hear the eater but cannot currently see it.
local function announce(ctx, position)
    local player = ctx:player()
    local player_pos = ctx:get(player, component.POSITION)

    if not player_pos or player_pos.level_id ~= position.level_id or
        silence.at(ctx, position.level_id, position.x, position.y) or
        silence.at(ctx, player_pos.level_id,
            player_pos.x, player_pos.y) then
        return
    end

    local distant = not senses.player_sees_cell(ctx, position)
    local adjective = distant and " distant" or ""

    ctx:emit(channels.SOUND,
        "You hear a" .. adjective .. " slurping noise.")
end

-- Mutate only the eaten quantity. The source destroys an exhausted stack
-- through normal item removal so neither a ghost floor item nor an empty
-- inventory entry survives save/restore.
local function eat_stack(ctx, entity, budget)
    local item = ctx:get(entity, component.ITEM)
    local definition = catalog.get(categories.ITEMS, item.kind_id)
    local quantity = item.quantity
    local eaten = 0
    local healing = 0

    if definition.class == classes.OBJ_GOLD then
        quantity = gold_portion(ctx, quantity)
        eaten = 1
        healing = math.floor(quantity / 10) + 1
    else
        quantity = math.min(quantity, budget)
        eaten = quantity
        healing = quantity * 3
    end

    if quantity >= item.quantity then
        ctx:destroy(entity)
    else
        item.quantity = item.quantity - quantity
        ctx:set(entity, component.ITEM, item)
    end

    return eaten, healing
end

-- Source slime healing may increase current HP beyond its old maximum;
-- maximum HP then catches up. The four-times-average limit is a cap on
-- current HP, not a replacement for the monster's prior maximum.
local function heal(ctx, monster, definition, amount)
    local health = ctx:get(monster, component.HEALTH)
    local average = math.floor(definition.average_hp_10x / 10)
    local cap = math.min(MAX_MONSTER_HP, average * 4)

    health.current = math.min(cap,
        health.current + math.min(MAX_HEAL, math.max(1, amount)))
    health.max = math.max(health.max, health.current)
    ctx:set(monster, component.HEALTH, health)
end

-- Source _handle_pickup calls this before ordinary monster action choice.
-- A cell with only inedible items still spends the initial 1d10 draw but
-- leaves the action available because nothing was eaten.
function feeding.act(ctx, monster)
    local player = ctx:player()
    local position = ctx:get(monster, component.POSITION)
    local player_pos = player and ctx:get(player, component.POSITION)
    local actor = ctx:get(monster, component.ACTOR)
    local health = ctx:get(monster, component.HEALTH)
    local mind = ctx:get(monster, component.AI)

    if not player or not identity.passive(ctx, player) or
        not position or not player_pos or
        position.level_id ~= player_pos.level_id or
        not actor or not health or health.current <= 0 or
        (mind and mind.behavior == behaviors.SLEEP) or
        ctx:has(monster, component.SUMMON) or
        not cells.allowed(ctx, position.level_id,
            position.x, position.y) then
        return false
    end

    -- A flying monster cannot collect a stack below deep water or lava;
    -- ordinary swimming jellies are allowed to feed in either liquid.
    local feature = ctx:cell(position.level_id,
        position.x, position.y)

    if flight.active(ctx, monster) and
        (feature == terrain.DNGN_DEEP_WATER or
            feature == terrain.DNGN_LAVA) then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if not identity.slime(definition) then
        return false
    end

    local floor = items.at(ctx, position)

    if #floor == 0 then
        return false
    end

    local budget = ctx:random(streams.RELIGION, 10) + 1
    local eaten = 0
    local healing = 0
    local announced = false

    for _, entity in ipairs(floor) do
        if eaten >= budget or healing >= MAX_HEAL then
            break
        end

        if edibility.edible(ctx, entity) then
            local units, gain = eat_stack(ctx, entity, budget - eaten)

            eaten = eaten + units
            healing = healing + gain

            if not announced then
                announce(ctx, position)
                announced = true
            end
        end
    end

    if eaten == 0 then
        return false
    end

    growth.start(ctx, monster, health)
    heal(ctx, monster, definition, healing)
    splitting.try(ctx, monster, definition)

    return true
end

return feeding
