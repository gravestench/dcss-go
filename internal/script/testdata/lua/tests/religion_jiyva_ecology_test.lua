-- Jiyva's live slime rules read the same saved vault properties and item
-- entities as ordinary generation, movement, and pickup. These cases use
-- production component schemas; only the host's level-record lookup is
-- reduced to the few cells the case needs.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local names = require("constants.slime_pit")
local properties = require("constants.vault_properties")
local cells = require("policy.religion.jiyva.cells")
local edibility = require("policy.religion.jiyva.items")
local feeding = require("policy.religion.jiyva.feeding")
local growth = require("policy.religion.jiyva.growth")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local roster = require("policy.population.roster")
local pursuit = require("policy.religion.jiyva.targets")
local attitudes = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local periodic = require("policy.religion.jiyva.periodic")
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local terrain = require("constants.terrain")

local test = {}

-- One record table stands in for the grid's saved record index; the policy
-- still receives the production record fields and effective source IDs.
local function world(ctx)
    local game = fixture.observed_context(ctx)

    game.properties = {}

    function game:records_at(level_id, x, y)
        return self.properties[level_id .. ":" .. x .. ":" .. y] or {}
    end

    return game
end

-- A KPROP attaches to a transformed cell. Unrelated records and overridden
-- properties must not turn an ordinary floor cell into a protected one.
local function property_cells(ctx)
    local game = world(ctx)

    game.properties["1:12:10"] = {
        {
            kind = effects.PROPERTY,
            source_id = "aquarium",
            identity = properties.NO_JIYVA,
            overridden = false,
        },
    }
    game.properties["1:13:10"] = {
        {
            kind = effects.PROPERTY,
            source_id = "aquarium",
            identity = properties.NO_JIYVA,
            overridden = true,
        },
    }

    harness.falsy(cells.allowed(game, 1, 12, 10),
        "Aquarium no-Jiyva property must block slime activity")
    harness.truthy(cells.allowed(game, 1, 13, 10),
        "overridden property must not block slime activity")
    harness.truthy(cells.allowed(game, 1, 14, 10),
        "ordinary floor remains available")

    game.properties["1:15:10"] = {
        {
            kind = effects.PROPERTY,
            source_id = names.MAP_ID,
            identity = properties.NO_JIYVA,
            overridden = false,
        },
    }

    local seal = ctx:create()

    ctx:add(seal, component.SLIME_SEAL, {
        level_id = 1,
        x = 15,
        y = 10,
        record_index = 1,
        released = false,
    })

    harness.falsy(cells.allowed(game, 1, 15, 10),
        "sealed Slime:5 inner floor blocks Jiyva")

    local state = ctx:get(seal, component.SLIME_SEAL)

    state.released = true
    ctx:set(seal, component.SLIME_SEAL, state)

    harness.truthy(cells.allowed(game, 1, 15, 10),
        "the saved Slime fixup lifts its own no-Jiyva property")
    harness.falsy(cells.allowed(game, 1, 12, 10),
        "the Slime fixup must not clear Aquarium protection")
end

-- Item identity and components, rather than display names, decide whether
-- a slime can chase or consume it. Ordinary gold and potions are eligible.
local function item(ctx, kind_id)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })

    return entity
end

-- Source item_is_jelly_edible excludes irreplaceable progress and held nets
-- even though each remains a normal item entity for pickup and saves.
local function item_exclusions(ctx)
    harness.truthy(edibility.edible(ctx, item(ctx, item_ids.OBJ_GOLD)))
    harness.truthy(edibility.edible(ctx, item(ctx, item_ids.POT_CURING)))
    harness.falsy(edibility.edible(ctx, item(ctx, item_ids.RUNE_SLIME)))
    harness.falsy(edibility.edible(ctx, item(ctx, item_ids.ORB_ZOT)))
    harness.falsy(edibility.edible(ctx,
        item(ctx, item_ids.MISC_HORN_OF_GERYON)))
    harness.falsy(edibility.edible(ctx,
        item(ctx, item_ids.MISC_ZIGGURAT)))

    local artefact = item(ctx, item_ids.WPN_DAGGER)

    ctx:add(artefact, component.ITEM_ARTEFACT, {})
    harness.falsy(edibility.edible(ctx, artefact))

    local mimic = item(ctx, item_ids.POT_CURING)

    ctx:add(mimic, component.VAULT_ITEM_MIMIC, {})
    harness.falsy(edibility.edible(ctx, mimic))

    local net = item(ctx, item_ids.MI_THROWING_NET)

    ctx:add(net, component.PROJECTILE_NET, {
        durability = 0,
    })
    harness.falsy(edibility.edible(ctx, net))
end

-- The same action budget applies to item stacks on a live floor. This
-- deterministic host draw tests the source arithmetic without copying the
-- production feeding rule into the fixture.
local function feeding_world(ctx, kind_id, x)
    local game = world(ctx)
    local player = game:player()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.JIYVA,
        piety = 0,
    })

    game.messages = {}

    function game:random(_, bound)
        if bound == 10 then
            return 3
        end

        return 0
    end

    function game:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    local monster = fixture.actor(ctx, kind_id, x, 10, 10)

    return game, monster
end

-- Eating occurs before a normal monster decision and destroys only the
-- portion selected by the 1d10 budget. Healing can raise maximum HP, but
-- this three-item case remains below the jelly's split threshold.
local function active_feeding(ctx)
    local game, monster = feeding_world(ctx, monsters.MONS_JELLY, 20)
    local floor_item = item(ctx, item_ids.POT_CURING)
    local stack = game:get(floor_item, component.ITEM)

    stack.quantity = 3
    game:set(floor_item, component.ITEM, stack)
    game:add(floor_item, component.POSITION, {
        level_id = 1,
        x = 20,
        y = 10,
    })

    harness.truthy(feeding.act(game, monster),
        "edible floor stack should consume the slime action")
    harness.falsy(game:get(floor_item, component.ITEM),
        "the eaten stack should be destroyed")

    local health = game:get(monster, component.HEALTH)

    harness.equal(health.current, 19)
    harness.equal(health.max, 100)

    game.properties["1:20:10"] = {
        {
            kind = effects.PROPERTY,
            source_id = "aquarium",
            identity = properties.NO_JIYVA,
            overridden = false,
        },
    }

    local protected_item = item(ctx, item_ids.POT_CURING)

    game:add(protected_item, component.POSITION, {
        level_id = 1,
        x = 20,
        y = 10,
    })

    harness.falsy(feeding.act(game, monster),
        "no-Jiyva property should prevent eating")
    harness.truthy(game:get(protected_item, component.ITEM),
        "protected item should remain on the floor")
end

-- Gold counts as one item-budget unit even when its amount is large. The
-- source reduces piles above 500 before healing and preserves the rest.
local function gold_feeding(ctx)
    local game, monster = feeding_world(ctx,
        monsters.MONS_FLOATING_EYE, 21)
    local gold = item(ctx, item_ids.OBJ_GOLD)
    local stack = game:get(gold, component.ITEM)

    stack.quantity = 600
    game:set(gold, component.ITEM, stack)
    game:add(gold, component.POSITION, {
        level_id = 1,
        x = 21,
        y = 10,
    })

    harness.truthy(feeding.act(game, monster))
    harness.equal(game:get(gold, component.ITEM).quantity, 98)

    local health = game:get(monster, component.HEALTH)

    harness.equal(health.current, 60)
    harness.equal(health.max, 100)
end

-- A meal can stop at its 1d10 budget and leave a real partial stack. A
-- sleeping or summoned slime cannot take that stack on its own action.
local function partial_and_incapacitated(ctx)
    local game, monster = feeding_world(ctx, monsters.MONS_JELLY, 23)
    local floor_item = item(ctx, item_ids.POT_CURING)
    local stack = game:get(floor_item, component.ITEM)

    stack.quantity = 20
    game:set(floor_item, component.ITEM, stack)
    game:add(floor_item, component.POSITION, {
        level_id = 1,
        x = 23,
        y = 10,
    })
    game:add(monster, component.AI, {
        behavior = behaviors.SLEEP,
    })

    harness.falsy(feeding.act(game, monster))
    harness.equal(game:get(floor_item, component.ITEM).quantity, 20)

    local mind = game:get(monster, component.AI)

    mind.behavior = behaviors.WANDER
    game:set(monster, component.AI, mind)
    game:add(monster, component.SUMMON, {
        owner = game:player(),
    })

    harness.falsy(feeding.act(game, monster))
    harness.equal(game:get(floor_item, component.ITEM).quantity, 20)

    game:remove(monster, component.SUMMON)
    harness.truthy(feeding.act(game, monster))
    harness.equal(game:get(floor_item, component.ITEM).quantity, 16)
end

-- A splitting jelly copies its live body into one adjacent cell only after
-- the meal has raised HP to the source threshold. Both actors must remain
-- independent saved entities rather than aliases of one health record.
local function jelly_split(ctx)
    local game, monster = feeding_world(ctx, monsters.MONS_JELLY, 25)
    local health = game:get(monster, component.HEALTH)

    health.current = 48
    health.max = 48
    game:set(monster, component.HEALTH, health)
    game:add(monster, component.MONSTER_ENERGY, {
        points = 80,
    })

    local floor_item = item(ctx, item_ids.POT_CURING)

    game:add(floor_item, component.POSITION, {
        level_id = 1,
        x = 25,
        y = 10,
    })

    harness.truthy(feeding.act(game, monster))

    local children = {}

    for _, entity in ipairs(game:query({
        component.ACTOR,
        component.POSITION,
    })) do
        if entity ~= monster then
            local actor = game:get(entity, component.ACTOR)
            local position = game:get(entity, component.POSITION)

            if actor.kind_id == monsters.MONS_JELLY and
                math.max(math.abs(position.x - 25),
                    math.abs(position.y - 10)) == 1 then
                children[#children + 1] = entity
            end
        end
    end

    harness.equal(#children, 1, "one adjacent child should split off")

    local parent_hp = game:get(monster, component.HEALTH)
    local child_hp = game:get(children[1], component.HEALTH)

    harness.equal(parent_hp.max, 25)
    harness.equal(parent_hp.current, 25)
    harness.equal(child_hp.max, 25)
    harness.equal(child_hp.current, 25)
    harness.truthy(game:has(children[1], component.MONSTER_ENERGY),
        "split child needs an independent action clock")
end

-- Authored merged slime creatures roll one body and multiply that HP by
-- their saved blob size. Their first meal must not make that birth roll
-- look forged, and split history has no arbitrary lifetime ceiling.
local function merged_growth(ctx)
    local game, monster = feeding_world(ctx,
        monsters.MONS_SLIME_CREATURE, 27)
    local profile = roster.profile(monsters.MONS_SLIME_CREATURE)
    local birth_max = profile.minimum * 3
    local health = game:get(monster, component.HEALTH)

    health.current = birth_max
    health.max = birth_max
    game:set(monster, component.HEALTH, health)
    game:add(monster, component.SLIME_BLOB, { size = 3 })
    growth.start(game, monster, health)

    harness.truthy(growth.validate(game, monster, health, {
        minimum = profile.minimum * 3,
        maximum = profile.maximum * 3,
    }, 0))

    local lineage = game:get(monster, component.JIYVA_GROWTH)

    lineage.split_count = 101
    game:set(monster, component.JIYVA_GROWTH, lineage)

    harness.truthy(growth.validate(game, monster, health, {
        minimum = profile.minimum * 3,
        maximum = profile.maximum * 3,
    }, 0))
end

-- Polymorph rolls a replacement body. Feeding lineage ends with the old
-- body, and a new slime records its own live HP as its first meal baseline.
local function polymorphed_growth(ctx)
    local game, monster = feeding_world(ctx, monsters.MONS_JELLY, 28)
    local health = game:get(monster, component.HEALTH)

    growth.start(game, monster, health)

    polymorph.fixed(game, monster,
        catalog.get(categories.MONSTERS, monsters.MONS_RAT))

    harness.falsy(game:get(monster, component.JIYVA_GROWTH),
        "replacement non-slime body cannot inherit slime growth")

    polymorph.fixed(game, monster,
        catalog.get(categories.MONSTERS, monsters.MONS_JELLY))

    local new_health = game:get(monster, component.HEALTH)

    growth.start(game, monster, new_health)

    harness.truthy(growth.validate(game, monster, new_health,
        roster.profile(monsters.MONS_JELLY), 0))
end

-- A converted good-neutral slime prefers the nearest visible edible item.
-- Protection, line of sight, and the current cell all exclude targets;
-- creation order does not influence equal-distance choices.
local function item_pursuit(ctx)
    local game, monster = feeding_world(ctx, monsters.MONS_JELLY, 50)

    game:add(monster, component.JIYVA_SLIME, {
        attitude = attitudes.GOOD_NEUTRAL,
        attempted = true,
    })

    local near = item(ctx, item_ids.POT_CURING)
    local far = item(ctx, item_ids.POT_CURING)
    local protected = item(ctx, item_ids.POT_CURING)

    game:add(near, component.POSITION, {
        level_id = 1,
        x = 51,
        y = 10,
    })
    game:add(far, component.POSITION, {
        level_id = 1,
        x = 53,
        y = 10,
    })
    game:add(protected, component.POSITION, {
        level_id = 1,
        x = 49,
        y = 10,
    })
    game.properties["1:49:10"] = {
        {
            kind = effects.PROPERTY,
            source_id = "aquarium",
            identity = properties.NO_JIYVA,
            overridden = false,
        },
    }

    local position = game:get(monster, component.POSITION)
    local chosen = pursuit.item(game, monster, position)

    harness.equal(chosen.x, 51)
    harness.equal(chosen.y, 10)

    function game:visible(_, _, _, _, x)
        return x ~= 51
    end

    chosen = pursuit.item(game, monster, position)
    harness.equal(chosen.x, 53,
        "an occluded item must not hold the pursuit target")

    game:destroy(far)
    harness.falsy(pursuit.item(game, monster, position),
        "without an eligible visible item, ordinary wandering resumes")
end

-- A source timer is stored on the player. A second scheduler visit over
-- the same aut interval must not create another jelly or reroll its clock.
local function periodic_spawn(ctx)
    local game = feeding_world(ctx, monsters.MONS_JELLY, 40)
    local player = game:player()
    local blocker = fixture.actor(ctx, monsters.MONS_RAT, 2, 1, 10)
    local cloud = ctx:create()

    game.cells["2:2"] = terrain.DNGN_SHALLOW_WATER

    game.properties["1:1:1"] = {
        {
            kind = effects.PROPERTY,
            source_id = "aquarium",
            identity = properties.NO_JIYVA,
            overridden = false,
        },
    }
    game:add(cloud, component.WORLD_CLOUD, {
        level_id = 1,
        x = 1,
        y = 2,
    })

    function game:level_size()
        return 4, 4
    end

    function game:random(_, bound)
        if bound == 25 then
            return 1
        end

        return 0
    end

    periodic.tick(game, player, 100)

    local timer = game:get(player, component.JIYVA_ECOLOGY)

    harness.equal(timer.next_due_aut, 200)
    harness.equal(#game:query({ component.JIYVA_SPAWN }), 1)

    local spawned = game:query({ component.JIYVA_SPAWN })[1]
    local position = game:get(spawned, component.POSITION)

    harness.equal(position.x, 2)
    harness.equal(position.y, 2,
        "shallow water is legal when protected, occupied, and clouded cells are not")
    harness.truthy(game:get(blocker, component.ACTOR))

    periodic.tick(game, player, 100)
    harness.equal(#game:query({ component.JIYVA_SPAWN }), 1,
        "the saved next due aut prevents replay")

    periodic.tick(game, player, 500)
    harness.equal(game:get(player,
        component.JIYVA_ECOLOGY).next_due_aut, 600,
        "a long action must process every crossed random timer")
end

-- Off-floor feeding must visit an already loaded level and remove its
-- actual ECS stack. The branch/depth draw is explicit here so the test
-- catches accidental active-floor consumption or a replacement level.
local function off_floor_feeding(ctx)
    local game = feeding_world(ctx, monsters.MONS_JELLY, 44)
    local player = game:player()
    local floor_item = item(ctx, item_ids.POT_CURING)
    local rune = item(ctx, item_ids.RUNE_SLIME)
    local all_branches = catalog.all(categories.BRANCHES)
    local dungeon_index

    for index, definition in ipairs(all_branches) do
        if definition.id == branches.BRANCH_DUNGEON then
            dungeon_index = index
        end
    end

    harness.truthy(dungeon_index)

    game:add(floor_item, component.POSITION, {
        level_id = 2,
        x = 1,
        y = 1,
    })
    game:add(rune, component.POSITION, {
        level_id = 2,
        x = 1,
        y = 1,
    })

    function game:level_ids()
        return { 1, 2 }
    end

    function game:level_depth(level_id)
        return level_id
    end

    function game:level_size()
        return 4, 4
    end

    local bail_checks = 0

    function game:random(_, bound)
        if bound == 10 then
            return 1
        elseif bound == 25 then
            return 0
        elseif bound == #all_branches then
            return dungeon_index - 1
        elseif bound == 27 then
            return 1
        elseif bound == 200 then
            bail_checks = bail_checks + 1

            if bail_checks >= 5 then
                return 0
            end

            return 1
        elseif bound == 4 then
            return 1
        end

        return 0
    end

    periodic.tick(game, player, 100)

    harness.falsy(game:get(floor_item, component.ITEM),
        "off-floor meal removes the saved stack entity")
    harness.truthy(game:get(rune, component.ITEM),
        "an off-floor meal must leave the rune on its stack")
    harness.equal(game:get(player,
        component.JIYVA_ECOLOGY).next_due_aut, 200)

    local protected = item(ctx, item_ids.POT_CURING)

    game:add(protected, component.POSITION, {
        level_id = 2,
        x = 1,
        y = 1,
    })
    game.properties["2:1:1"] = {
        {
            kind = effects.PROPERTY,
            source_id = "aquarium",
            identity = properties.NO_JIYVA,
            overridden = false,
        },
    }

    periodic.tick(game, player, 200)
    harness.truthy(game:get(protected, component.ITEM),
        "no-Jiyva property also protects an inactive floor")
end

-- Keep the property and item gates isolated from the later feeding and
-- scheduler cases while sharing their production rule modules.
function test.run(ctx)
    property_cells(ctx)
    item_exclusions(ctx)
    active_feeding(ctx)
    gold_feeding(ctx)
    partial_and_incapacitated(ctx)
    jelly_split(ctx)
    merged_growth(ctx)
    polymorphed_growth(ctx)
    item_pursuit(ctx)
    periodic_spawn(ctx)
    off_floor_feeding(ctx)
end

return test
