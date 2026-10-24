local catalog = require("policy.catalog")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local gear = require("policy.population.gear")
local random_artefact = require("policy.item_generation.artefacts.random")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local weapons = {}

-- The equipped weapon determines the dancer's body, regardless of whether
-- a card generated the item or Xom took it from another monster. Keeping
-- this one derivation path avoids different combat stats for equal items.
local function derive(ctx, creature, definition, power)
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

end

-- The ordinary monster and the card create an item before deriving the
-- body. A borrowed weapon instead keeps its original item entity below.
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

    derive(ctx, creature, definition, power)

    return item
end

-- Xom animates an existing monster weapon. Reassign its carrier and slot
-- on that same ECS entity, retaining artefact identity, enchantment, and
-- later summon death behavior while the normal dancer stats are derived.
function weapons.attach_existing(ctx, creature, item, power)
    local state = ctx:get(item, component.ITEM)

    if not state or
        not ctx:has(item, component.CARRIED_BY) or
        not ctx:has(item, component.EQUIPPED) then
        error("dancing weapon needs an equipped item")
    end

    local definition = catalog.get("items", state.kind_id)

    if not definition.weapon then
        error("dancing weapon item is not a weapon")
    end

    ctx:set(item, component.CARRIED_BY, {
        holder = creature,
    })
    ctx:set(item, component.EQUIPPED, {
        slot = "weapon",
    })
    derive(ctx, creature, definition, power)

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

-- Source monster creation first rolls its ordinary dancing-weapon loadout.
-- Wu Jian then overwrites that same weapon's kind, ego, and plus. Our
-- generic summon owner creates no interim equipment, so consume the normal
-- loadout rolls before the card-stream plus roll and attach only the final
-- item. The ghost receives full level-scaled power, unlike the card's /4.
function weapons.equip_wrath(ctx, creature, choice, power, level_id)
    local ordinary = gear.loadout(ctx, monsters.MONS_DANCING_WEAPON,
        level_id)

    if not ordinary or not ordinary.primary then
        error("dancing weapon has no ordinary loadout")
    end

    local plus = ctx:random(streams.CARDS, 5)

    return equip(ctx, creature, choice.kind_id, plus, choice.ego, power)
end

return weapons
