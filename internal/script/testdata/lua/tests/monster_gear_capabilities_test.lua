-- Monster gear capabilities use real equipped ECS items and catalog
-- definitions. Removing an item must change the next derived read.
local artefact_kinds = require("constants.artefact_kinds")
local armour_egos = require("constants.armour_egos")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local equipment = require("policy.combat.equipment")
local flight = require("policy.combat.flight")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local monster_ids = require("ids.monsters")
local monster_senses = require("policy.combat.monster_senses")
local mutant_form = require("policy.monsters.mutant_beast.form")
local properties = require("ids.artefact_properties")
local habitat = require("policy.combat.monster_habitat")
local gazes = require("policy.combat.monster_gazes")
local invisibility = require("policy.potions.invisibility")
local spell_ids = require("ids.spells")
local terrain = require("constants.terrain")

local test = {}

-- A catalog monster plus its ECS identity is enough to read active gear.
local function actor(ctx, kind_id)
    local entity = ctx:create()

    ctx:add(entity, component.ACTOR, {
        kind_id = kind_id,
        speed = 10,
    })

    return entity, catalog.get(categories.MONSTERS, kind_id)
end

-- Active slots belong to the item entity, never the monster catalog row.
local function wear(ctx, holder, kind_id, slot, ego)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = ego or "",
    })
    ctx:add(entity, component.CARRIED_BY, { holder = holder })
    ctx:add(entity, component.EQUIPPED, { slot = slot })

    return entity
end

-- Flight is checked from the live actor for habitat, traps, and movement.
-- Each source of flight must stop working as soon as its item is removed.
local function live_flight(ctx)
    local monster = actor(ctx, monster_ids.MONS_ORC_WIZARD)

    harness.falsy(flight.active(ctx, monster),
        "ordinary monster starts grounded")

    local ring = wear(ctx, monster, item_ids.RING_FLIGHT,
        "jewellery")

    harness.truthy(flight.active(ctx, monster),
        "worn flight ring lifts a monster")

    ctx:set_cell(1, 9, 9, terrain.DNGN_DEEP_WATER)

    harness.truthy(habitat.at(ctx, monster, 1, 9, 9),
        "flight ring allows a land monster over deep water")

    ctx:remove(ring, component.EQUIPPED)

    harness.falsy(habitat.at(ctx, monster, 1, 9, 9),
        "removing flight ring changes habitat immediately")

    local body = wear(ctx, monster, item_ids.ARM_ROBE,
        "body", armour_egos.FLYING)

    harness.truthy(flight.active(ctx, monster),
        "Flying armour ego lifts the wearer")

    ctx:remove(body, component.EQUIPPED)

    harness.falsy(flight.active(ctx, monster),
        "removing Flying armour ends its flight")

    local weapon = wear(ctx, monster, item_ids.WPN_DAGGER,
        "weapon")

    ctx:add(weapon, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.FLY] = 1,
        },
    })

    harness.truthy(flight.active(ctx, monster),
        "active artefact Flight property lifts its wielder")

    ctx:remove(weapon, component.EQUIPPED)

    harness.falsy(flight.active(ctx, monster),
        "removing artefact Flight grounds the monster")

    local draconian = actor(ctx,
        monster_ids.MONS_DRACONIAN_SHIFTER)

    ctx:add(draconian, component.MONSTER_DRACONIAN_BASE, {
        base_id = monster_ids.MONS_BLACK_DRACONIAN,
    })

    harness.truthy(flight.active(ctx, draconian),
        "black-based draconian job inherits flight")

    local beast = actor(ctx, monster_ids.MONS_MUTANT_BEAST)

    ctx:add(beast, component.MONSTER_MUTANT_BEAST,
        mutant_form.parse("mature bat mutant beast"))

    harness.truthy(flight.active(ctx, beast),
        "saved Bat facet grants inherent flight")

    local zombie = actor(ctx, monster_ids.MONS_ZOMBIE)

    ctx:add(zombie, component.VAULT_ACTOR_OVERRIDES, {
        base_id = monster_ids.MONS_FIRE_DRAGON,
    })

    harness.truthy(flight.active(ctx, zombie),
        "zombie inherits its saved flying base species")
end

-- Sight belongs to the observer. Worn items can reveal an invisible
-- player or permit a gaze at an unseen monster without changing their
-- intrinsic catalog flags.
local function live_sight(ctx)
    local observer, definition = actor(ctx,
        monster_ids.MONS_ORC_WIZARD)
    local player = ctx:player()

    ctx:add(player, component.POTION_INVISIBILITY, {
        remaining_aut = 100,
    })

    harness.falsy(monster_senses.see_invisible(ctx,
        observer, definition),
        "ordinary orc wizard cannot see invisible")
    harness.falsy(invisibility.visible_to(ctx, player, observer),
        "invisible player is hidden from ordinary monster")

    local ring = wear(ctx, observer,
        item_ids.RING_SEE_INVISIBLE, "jewellery")

    harness.truthy(invisibility.visible_to(ctx, player, observer),
        "worn sight ring reveals invisible player")

    ctx:remove(ring, component.EQUIPPED)

    harness.falsy(invisibility.visible_to(ctx, player, observer),
        "removing sight ring hides player on next check")

    local body = wear(ctx, observer, item_ids.ARM_ROBE,
        "body", armour_egos.SEE_INVISIBLE)

    harness.truthy(monster_senses.see_invisible(ctx,
        observer, definition),
        "See Invisible armour ego grants monster sight")

    ctx:remove(body, component.EQUIPPED)

    local weapon = wear(ctx, observer,
        item_ids.WPN_DAGGER, "weapon")

    ctx:add(weapon, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.SEE_INVISIBLE] = 1,
        },
    })

    harness.truthy(monster_senses.see_invisible(ctx,
        observer, definition),
        "active artefact sight grants monster sight")

    ctx:remove(weapon, component.EQUIPPED)

    harness.falsy(monster_senses.see_invisible(ctx,
        observer, definition),
        "removing sight artefact restores ordinary sight")

    ctx:add(observer, component.PLAYER_ILLUSION, {
        see_invisible = true,
    })

    harness.truthy(monster_senses.see_invisible(ctx,
        observer, definition),
        "saved player illusion sight overrides ordinary kind")

    ctx:remove(observer, component.PLAYER_ILLUSION)

    local beast, beast_kind = actor(ctx,
        monster_ids.MONS_MUTANT_BEAST)

    ctx:add(beast, component.MONSTER_MUTANT_BEAST,
        mutant_form.parse("mature weird mutant beast"))

    harness.truthy(monster_senses.see_invisible(ctx,
        beast, beast_kind),
        "saved Weird facet grants innate sight")

    local caster = fixture.actor(ctx,
        monster_ids.MONS_ORC_WIZARD, 5, 7, 20)
    local hidden = fixture.actor(ctx,
        monster_ids.MONS_UNSEEN_HORROR, 8, 7, 20)

    harness.falsy(gazes.plan(ctx, caster, hidden,
        spell_ids.SPELL_CONFUSION_GAZE),
        "ordinary caster cannot gaze at an unseen horror")

    wear(ctx, caster, item_ids.RING_SEE_INVISIBLE,
        "jewellery")

    harness.truthy(gazes.plan(ctx, caster, hidden,
        spell_ids.SPELL_CONFUSION_GAZE),
        "sight ring permits a gaze at an unseen horror")
end

-- Only an item-using monster's active, class-correct slots contribute
-- artefact properties; a dual wielder's second weapon is genuinely active.
local function active_artefacts(ctx)
    local wizard, wizard_kind = actor(ctx,
        monster_ids.MONS_ORC_WIZARD)
    local weapon = wear(ctx, wizard, item_ids.WPN_DAGGER, "weapon")

    ctx:add(weapon, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.FLY] = 1,
        },
    })

    harness.equal(equipment.monster_artefact_value(ctx, wizard,
        wizard_kind, properties.FLY), 1,
        "active weapon grants its artefact property")

    local spare = wear(ctx, wizard, item_ids.WPN_DAGGER,
        "alternate_weapon")

    ctx:add(spare, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.FLY] = 1,
        },
    })

    harness.equal(equipment.monster_artefact_value(ctx, wizard,
        wizard_kind, properties.FLY), 1,
        "ordinary spare weapon grants no artefact property")

    ctx:remove(weapon, component.EQUIPPED)

    harness.equal(equipment.monster_artefact_value(ctx, wizard,
        wizard_kind, properties.FLY), 0,
        "removing active weapon removes its property immediately")

    local ogre, ogre_kind = actor(ctx,
        monster_ids.MONS_TWO_HEADED_OGRE)
    local second = wear(ctx, ogre, item_ids.WPN_DAGGER,
        "alternate_weapon")

    ctx:add(second, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.FLY] = 1,
        },
    })

    harness.equal(equipment.monster_artefact_value(ctx, ogre,
        ogre_kind, properties.FLY), 1,
        "dual wielder receives second weapon's artefact property")

    local rat, rat_kind = actor(ctx, monster_ids.MONS_RAT)
    local impossible = wear(ctx, rat, item_ids.WPN_DAGGER,
        "weapon")

    ctx:add(impossible, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        properties = {
            [properties.FLY] = 1,
        },
    })

    harness.equal(equipment.monster_artefact_value(ctx, rat,
        rat_kind, properties.FLY), 0,
        "non item user ignores impossible equipped artefact")
end

-- The complete category test grows with flight and sight, while all
-- assertions keep using production ECS item and monster definitions.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    active_artefacts(game)
    live_flight(game)
    live_sight(game)
end

return test
