local catalog = require("policy.catalog")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local gear = require("policy.population.gear")
local monsters = require("ids.monsters")

local weapons = {}

-- mon-place.cc creates the normal weapon first; ghost.cc then derives the
-- dancing body's combat values from that weapon at power 100.
function weapons.equip(ctx, creature, level_id)
    local loadout = gear.loadout(ctx, monsters.MONS_DANCING_WEAPON, level_id)
    local weapon = loadout.primary
    local definition = catalog.get("items", weapon.kind_id)
    local item = ctx:create()

    ctx:add(item, component.ITEM, {
        kind_id = weapon.kind_id,
        quantity = 1,
        plus = weapon.quality.plus,
        ego = weapon.quality.ego,
        charges = 0,
    })
    ctx:add(item, component.CARRIED_BY, { holder = creature })
    ctx:add(item, component.EQUIPPED, { slot = "weapon" })

    local delay = definition.weapon.speed
    local damage = definition.weapon.damage
    local actor = ctx:get(creature, component.ACTOR)

    actor.speed = math.max(3, math.floor((30 - delay) / 2) * 2)
    ctx:set(creature, component.ACTOR, actor)
    ctx:set(creature, component.HEALTH, {
        current = delay * 2,
        max = delay * 2,
    })
    ctx:add(creature, constructs.DANCING_WEAPON, {
        speed = actor.speed,
        ac = damage,
        ev = math.max(3, 25 - math.floor(delay / 2)),
        damage = 2 * damage,
    })
end

return weapons
