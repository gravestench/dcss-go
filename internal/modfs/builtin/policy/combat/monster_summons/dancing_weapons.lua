local catalog = require("policy.catalog")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local gear = require("policy.population.gear")
local random_artefact = require("policy.item_generation.artefacts.random")
local monsters = require("ids.monsters")

local weapons = {}

-- The ordinary monster and the card share the same carried-item and ghost
-- body ownership. Card power scales the derived body, while Sheza's normal
-- dancing weapons pass 100 and retain their existing combat profile.
local function equip(ctx, creature, kind_id, plus, ego, power,
    artefact)
    local definition = catalog.get("items", kind_id)
    local item = ctx:create()

    ctx:add(item, component.ITEM, {
        kind_id = kind_id,
        quantity = 1,
        plus = plus,
        ego = ego,
        charges = 0,
    })
    ctx:add(item, component.CARRIED_BY, { holder = creature })
    ctx:add(item, component.EQUIPPED, { slot = "weapon" })

    if artefact then
        ctx:add(item, component.ITEM_ARTEFACT, artefact)
    end

    local delay = definition.weapon.speed
    local damage = definition.weapon.damage
    local actor = ctx:get(creature, component.ACTOR)
    local strength = math.min(100, power)

    actor.speed = math.max(3,
        math.floor((30 - delay) / 2) *
        (1 + math.floor(strength / 100)))
    ctx:set(creature, component.ACTOR, actor)

    local hp = math.max(5,
        math.floor(delay * 2 * strength / 100))

    ctx:set(creature, component.HEALTH, {
        current = hp,
        max = hp,
    })
    ctx:add(creature, constructs.DANCING_WEAPON, {
        speed = actor.speed,
        ac = math.floor(damage * strength / 100),
        ev = math.max(3, math.floor((25 - math.floor(delay / 2)) *
            strength / 100)),
        damage = math.max(1,
            math.floor(2 * damage * strength / 100)),
    })

    return item
end

-- mon-place.cc creates a normal loadout before ghost.cc derives the
-- dancing body. This remains the non-card entry point used by Sheza.
function weapons.equip(ctx, creature, level_id)
    local loadout = gear.loadout(ctx, monsters.MONS_DANCING_WEAPON, level_id)
    local weapon = loadout.primary

    return equip(ctx, creature, weapon.kind_id,
        weapon.quality.plus, weapon.quality.ego, 100)
end

-- The card chooses its item; the shared owner attaches it and scales the
-- ghost using source card power divided by four. A randart keeps the same
-- carried-item lifetime and is destroyed with the summon at expiry.
function weapons.equip_card(ctx, creature, choice, power)
    local definition = catalog.get("items", choice.kind_id)
    local plus = choice.plus
    local ego = choice.ego
    local artefact

    if choice.randart then
        local result = {
            components = {},
        }

        if random_artefact.apply(ctx, definition, result) then
            plus = result.plus
            ego = result.ego
            artefact = result.components[component.ITEM_ARTEFACT]
        end
    end

    return equip(ctx, creature, choice.kind_id, plus, ego,
        math.floor(power / 4), artefact)
end

return weapons
