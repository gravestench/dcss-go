-- Source: monster.cc:monster::drain and mon-ench.cc:ENCH_DRAINED.
local component = require("constants.component")
local resistance_ids = require("constants.resistance_ids")
local holiness_ids = require("constants.monster_holiness")
local armour_egos = require("constants.armour_egos")
local armour_flags = require("constants.armour_flags")
local item_use = require("constants.monster_item_use")
local item_ids = require("ids.items")
local object_classes = require("ids.object_classes")
local equipment = require("policy.combat.equipment")
local monster_health = require("policy.combat.monster_health")
local catalog = require("policy.catalog")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local senses = require("policy.character.senses")
local monster_profile = require("policy.combat.monster_profile")

local drain = {}

-- Fold intrinsic armour's negative-energy flags into the drain resistance score.
local function armour_resistance(definition)
    local source = definition.armour and definition.armour.flags
    local flags = type(source) == "table" and source or {}
    local value = 0

    for _, flag in ipairs(flags) do
        if flag.id == armour_flags.RES_NEGATIVE_ENERGY then
            value = value + flag.level
        end
    end

    return value
end

-- Only monsters allowed to use gear receive body, shield, jewellery, or
-- staff protection against negative energy.
local function equipped_resistance(ctx, monster, definition)
    if definition.item_use_id ~= item_use.STARTING_EQUIPMENT and
        definition.item_use_id ~= item_use.WEAPONS_ARMOUR then
        return 0
    end

    local value = 0
    local worn = equipment.worn(ctx, monster, {
        body = true,
        shield = true,
        jewellery = true,
        weapon = true,
    })

    for slot, entry in pairs(worn) do
        local item = entry.item
        local kind = entry.definition

        if kind.class == object_classes.OBJ_ARMOUR and
            (slot == "body" or slot == "shield") then
            value = value + armour_resistance(kind)

            if entry.ego == armour_egos.POSITIVE_ENERGY then
                value = value + 1
            end
        elseif slot == "jewellery" and
            kind.jewellery then
            value = value + jewellery_effects.value(item, kind,
                jewellery_capabilities.NEGATIVE_ENERGY_RESISTANCE)
        elseif slot == "weapon" and
            item.kind_id == item_ids.STAFF_DEATH then
            value = value + 1
        end
    end

    return value
end

-- Nonliving holiness is fully immune; living resistance combines intrinsic
-- pips with permitted equipment and caps at three.
function drain.resistance(ctx, monster, definition)
    definition = monster_profile.definition(ctx, monster, definition)

    local types = definition.holiness or {}
    local living = #types == 0

    for _, holiness in ipairs(types) do
        if holiness == holiness_ids.NATURAL or
            holiness == holiness_ids.PLANT then
            living = true
            break
        end
    end

    if not living then
        return 3
    end

    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == resistance_ids.NEGATIVE_ENERGY then
            return math.min(3, entry.level +
                equipped_resistance(ctx, monster, definition))
        end
    end

    return math.min(3, equipped_resistance(ctx, monster, definition))
end

-- Monster drain is stored as a timed component after negative-energy resistance is checked.
function drain.apply(ctx, target, definition, source, stream,
    player_credit)
    local resistance = drain.resistance(ctx, target, definition)
    local random_stream = stream or "mutation"

    if resistance >= 3 then
        return false
    end

    if senses.player_sees_actor(ctx, target) then
        ctx:emit("combat", "The " .. definition.name .. " is drained!")
    end

    local health, dealt = monster_health.damage(ctx, target,
        2 + ctx:random(random_stream, 3), source)

    if dealt > 0 and health.current == 0 then
        if player_credit or
            source and ctx:has(source, component.PLAYER) then
            ctx:signal("player_kill", target)
        end

        return true
    end

    local current = ctx:get(target, component.MONSTER_DRAINED)
    local remaining = current and current.remaining_aut or 0
    -- Repeated drains add a degree but cap remaining time, then partial
    -- negative resistance shortens only the new duration.
    local duration = 200 + ctx:random(random_stream, 100)
    local cap = 300 - remaining - ctx:random(random_stream, 50)

    duration = math.min(duration, cap)

    if resistance > 0 then
        duration = math.floor(duration / (resistance * 2))
    end

    local next_state = current or {
        degree = 0,
        remaining_aut = 0,
    }

    next_state.degree = next_state.degree + 1
    next_state.remaining_aut = math.max(0, remaining + duration)

    if current then
        ctx:set(target, component.MONSTER_DRAINED, next_state)
    else
        ctx:add(target, component.MONSTER_DRAINED, next_state)
    end

    return true
end

-- Example: drain.tick(ctx, monster) with expired drain -> drained state removed
-- Timed drain expires on the monster clock and removes its hit-dice penalty.
function drain.tick(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_DRAINED)

    if not current then
        return
    end

    current.remaining_aut = math.max(0, current.remaining_aut - 10)

    if current.remaining_aut > 0 then
        ctx:set(monster, component.MONSTER_DRAINED, current)

        return
    end

    ctx:remove(monster, component.MONSTER_DRAINED)
    local actor = ctx:get(monster, component.ACTOR)

    if actor then
        local definition = catalog.get("monsters", actor.kind_id)

        if senses.player_sees_actor(ctx, monster) then
            ctx:emit("monster", "The " .. definition.name ..
                " seems less drained.")
        end
    end
end

return drain
