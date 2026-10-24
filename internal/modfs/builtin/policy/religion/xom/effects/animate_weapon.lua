-- Xom animates a hostile monster's existing melee weapon. The normal
-- dancing-weapon owner derives combat stats from that item after the
-- summon is placed; no duplicate item or transient Xom combat rule exists.
local ammunition = require("ids.ammunition")
local artefact_kinds = require("constants.artefact_kinds")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local confusion = require("policy.religion.xom.confusion")
local dancing = require("policy.combat.monster_summons.dancing_weapons")
local equipment = require("policy.combat.equipment")
local events = require("ids.xom_events")
local gear = require("policy.population.gear")
local gods = require("constants.gods")
local item_use = require("constants.monster_item_use")
local monsters = require("ids.monsters")
local object_classes = require("ids.object_classes")
local slots = require("constants.monster_equipment_slots")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local weapon_brands = require("constants.weapon_brands")

local effect = {}

-- Source mons_itemuse must permit equipment. A nearby hostile is not
-- eligible merely because a vault equipped an otherwise mindless body.
local function uses_equipment(definition)
    return definition.item_use_id == item_use.STARTING_EQUIPMENT or
        definition.item_use_id == item_use.WEAPONS_ARMOUR
end

-- The item has to be the monster's one real melee weapon. Unique items,
-- ranged weapons, distortion, stacked items, and summoned owners are
-- excluded before Xom spends a target draw.
local function animateable(ctx, monster, definition)
    if not uses_equipment(definition) or
        ctx:has(monster, component.SUMMON) then
        return nil
    end

    local worn = equipment.worn(ctx, monster, {
        [slots.WEAPON] = true,
    })
    local entry = worn[slots.WEAPON]

    if not entry or
        entry.definition.class ~= object_classes.OBJ_WEAPONS or
        not entry.definition.weapon or
        entry.definition.weapon.ammo_id ~= ammunition.NONE or
        entry.item.quantity ~= 1 or
        entry.ego == weapon_brands.DISTORTION then
        return nil
    end

    local artefact = ctx:get(entry.entity, component.ITEM_ARTEFACT)

    if artefact and artefact.kind == artefact_kinds.UNIQUE then
        return nil
    end

    return entry
end

-- The selector and action use this same source-shaped target pool. Each
-- eligible result retains its real item entity and owner's position.
function effect.candidates(ctx, player)
    local found = {}

    for _, monster in ipairs(confusion.nearby(ctx, player)) do
        if confusion.hostile(ctx, monster) then
            local actor = ctx:get(monster, component.ACTOR)
            local definition = actor and catalog.get(categories.MONSTERS,
                actor.kind_id)
            local weapon = definition and
                animateable(ctx, monster, definition)

            if weapon then
                found[#found + 1] = {
                    monster = monster,
                    weapon = weapon,
                }
            end
        end
    end

    return found
end

-- Place the ordinary friendly dancer first. Failed placement leaves the
-- monster wielding its weapon; successful placement transfers that exact
-- entity, then derives the construct's combat body from its properties.
function effect.apply(ctx, player, event_id, severity, request)
    if event_id ~= events.GOOD_ANIMATE_MON_WPN then
        error("weapon animation received another Xom event")
    end

    local stream = request and request.stream or streams.RELIGION
    local candidates = effect.candidates(ctx, player)

    if #candidates == 0 then
        return nil
    end

    local chosen = candidates[ctx:random(stream, #candidates) + 1]
    local position = ctx:get(chosen.monster, component.POSITION)
    local duration = math.min(2 + math.floor(ctx:random(stream,
        math.max(1, severity)) / 5), 6)
    local creature = summons.spawn(ctx, player, gods.XOM,
        monsters.MONS_DANCING_WEAPON, duration, nil, {
            anchor = position,
            attitude = attitudes.FRIENDLY,
            source_category = categories.GODS,
            stream = stream,
            silent_failure = true,
        })

    if not creature then
        return nil
    end

    -- DCSS rolls the dancer's temporary starting weapon before replacing
    -- it with the stolen one. Consume that ordinary gear roll here.
    gear.loadout(ctx, monsters.MONS_DANCING_WEAPON,
        ctx:level_depth(position.level_id))
    dancing.attach_existing(ctx, creature, chosen.weapon.entity, 100)
    ctx:emit(channels.RELIGION,
        "Xom makes the " .. chosen.weapon.definition.name ..
        " dance into the air!")

    return creature
end

return effect
