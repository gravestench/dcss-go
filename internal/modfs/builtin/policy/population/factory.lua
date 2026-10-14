local catalog = require("policy.catalog")
local items = require("policy.inventory.items")
local gear = require("policy.population.gear")
local hit_points = require("policy.population.hit_points")
local energy = require("policy.monster_energy")
local roster = require("policy.population.roster")

local factory = {}

local function starting_item(ctx, holder, kind_id, quantity, plus, ego, slot)
    local definition = catalog.get("items", kind_id)

    if (slot == "weapon" or slot == "alternate_weapon") and
        definition.class ~= "OBJ_WEAPONS" then
        error("monster starting item is not a weapon: " .. kind_id)
    end

    if slot == "missile" and definition.class ~= "OBJ_MISSILES" then
        error("monster starting item is not ammunition: " .. kind_id)
    end

    local item = {
        kind_id = kind_id,
        quantity = quantity,
        plus = plus,
        charges = 0,
        ego = ego,
    }

    items.validate(item, definition)

    local entity = ctx:create()
    ctx:add(entity, "core.item", item)
    ctx:add(entity, "core.carried_by", { holder = holder })
    ctx:add(entity, "core.equipped", { slot = slot })

    return entity
end

local function create_loadout(ctx, monster, loadout)
    if not loadout then
        return
    end

    local primary = loadout.primary
    starting_item(ctx, monster, primary.kind_id, 1,
        primary.quality.plus, primary.quality.ego, "weapon")

    if loadout.alternate then
        local alternate = loadout.alternate
        starting_item(ctx, monster, alternate.kind_id, 1,
            alternate.quality.plus, alternate.quality.ego, "alternate_weapon")
    end

    if loadout.ammunition then
        local ammunition = loadout.ammunition
        starting_item(ctx, monster, ammunition.kind_id,
            ammunition.quantity, 0, ammunition.ego, "missile")
    end
end

function factory.spawn(ctx, kind_id, level_id, x, y)
    local profile = roster.profile(kind_id)
    local definition = catalog.get("monsters", kind_id)

    if definition.average_hp_10x ~= profile.average then
        error("unsupported ordinary monster definition " .. kind_id)
    end

    if not ctx:walkable(level_id, x, y) or ctx:actor_at(level_id, x, y) then
        error("cannot place monster " .. kind_id)
    end

    local hp = hit_points.roll(ctx, definition.average_hp_10x)

    if hp < profile.minimum or hp > profile.maximum then
        error("unsupported " .. kind_id .. " HP " .. hp)
    end

    local loadout = gear.loadout(ctx, kind_id, level_id)
    local monster = ctx:create()
    ctx:add(monster, "core.actor", {
        kind_id = kind_id,
        speed = definition.speed,
    })
    ctx:add(monster, "core.monster_energy", { points = energy.initial })
    ctx:add(monster, "core.health", {
        current = hp,
        max = hp,
    })
    ctx:add(monster, "core.combat", { shield_blocks = 0 })
    ctx:add(monster, "core.ai", { behavior = "wander" })
    create_loadout(ctx, monster, loadout)
    ctx:place_actor(monster, level_id, x, y)

    return monster
end

return factory
