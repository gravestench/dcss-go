-- Maurice transfers real player items and gold into his ECS inventory.
-- The same carried entities must fall to the floor when he dies.
local actions = require("policy.combat.melee_actions")
local attack = require("policy.combat.monster_attack_flavours")
local attitudes = require("constants.attitude")
local component = require("constants.component")
local death = require("policy.death")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local save_inventory = require("policy.save.monster_inventory")
local species = require("ids.species")
local theft = require("policy.combat.monster_attack_flavours.theft")
local tithe_states = require("constants.zin_tithe_state")

local test = {}

-- All fixtures use the production item and carrier components; no test
-- schema shadows the data copied by the theft policy.
local function carried(ctx, holder, kind_id, quantity, slot)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = kind_id,
        quantity = quantity,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(entity, component.CARRIED_BY, {
        holder = holder,
    })

    if slot then
        ctx:add(entity, component.EQUIPPED, {
            slot = slot,
        })
    end

    return entity
end

-- Count physical inventory entities by carrier, as save and death do.
local function owned(ctx, holder, kind_id)
    local found = {}

    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
    })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)
        local item = ctx:get(entity, component.ITEM)

        if carrier.holder == holder and
            (not kind_id or item.kind_id == kind_id) then
            found[#found + 1] = entity
        end
    end

    return found
end

-- Only player contact can steal. A blocked or missed contact, confused
-- Maurice, and a pacified Maurice leave inventory and wallet alone.
local function contact_gates(ctx, game, maurice, player)
    local potion = carried(ctx, player, items.POT_CURING, 3)
    local hit = {
        kind = "miss",
        attacker = maurice,
        defender = player,
        damage_done = 1,
    }

    function game:random()
        return 0
    end

    harness.falsy(attack.apply(game, flavours.STEAL, hit),
        "missed contact cannot steal")

    hit.kind = "hit"
    hit.defender = fixture.actor(ctx, monsters.MONS_ORC,
        15, 10, 100)

    harness.falsy(attack.apply(game, flavours.STEAL, hit),
        "Maurice cannot steal from another monster")

    hit.defender = player
    ctx:add(maurice, component.MONSTER_CONFUSION, {
        remaining_aut = 20,
    })

    harness.falsy(attack.apply(game, flavours.STEAL, hit),
        "confused Maurice does not steal")

    ctx:remove(maurice, component.MONSTER_CONFUSION)
    ctx:add(maurice, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.GOOD_NEUTRAL,
    })

    harness.falsy(attack.apply(game, flavours.STEAL, hit),
        "pacified Maurice does not steal")

    ctx:remove(maurice, component.VAULT_ACTOR_OVERRIDES)
    harness.equal(ctx:get(potion, component.ITEM).quantity, 3,
        "ineligible contacts leave the carried stack untouched")

    return potion
end

-- A partial theft preserves the original stack and creates a carried copy
-- with the same instance knowledge. The monster's death drops that copy.
local function partial_stack(ctx, game, maurice, player, potion)
    ctx:add(potion, component.ITEM_IDENTIFICATION, {
        known_type = true,
        known_pluses = false,
        known_properties = false,
        cosmetic = 0,
    })

    harness.truthy(theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    }), "Maurice steals one potion from a stack")

    harness.equal(ctx:get(potion, component.ITEM).quantity, 2,
        "partial theft leaves the player's remainder")

    local stolen = owned(ctx, maurice, items.POT_CURING)

    harness.equal(#stolen, 1, "stolen portion becomes one carried item")
    harness.equal(ctx:get(stolen[1], component.ITEM).quantity, 1,
        "source stack draw controls the taken quantity")
    harness.truthy(ctx:get(stolen[1],
        component.ITEM_IDENTIFICATION).known_type,
        "split copy retains instance identification")

    local position = ctx:get(maurice, component.POSITION)
    local dropped = death.drop_inventory(game, maurice, position)

    harness.equal(#dropped, 1,
        "Maurice's death releases the stolen potion")
    harness.truthy(ctx:has(stolen[1], component.POSITION),
        "theft uses the ordinary monster loot path")

    ctx:destroy(potion)
end

-- The source reservoir replaces an earlier candidate when its value roll
-- lands inside that candidate's weight; inventory scans are deterministic.
local function weighted_choice(ctx, game, maurice, player)
    local potion = carried(ctx, player, items.POT_CURING, 1)
    local scroll = carried(ctx, player, items.SCR_TELEPORTATION, 1)

    function game:random()
        return 0
    end

    harness.truthy(theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    }), "weighted reservoir chooses an eligible item")

    harness.equal(ctx:get(scroll, component.CARRIED_BY).holder,
        maurice, "second candidate can replace first")
    harness.equal(ctx:get(potion, component.CARRIED_BY).holder,
        player, "unselected candidate remains carried")

    ctx:destroy(potion)
end

-- A single-item stack changes carrier in place. Identity, charges, and
-- appearance should not be reconstructed when no split is needed.
local function whole_item(ctx, game, maurice, player)
    local wand = carried(ctx, player, items.WAND_FLAME, 1)
    local item = ctx:get(wand, component.ITEM)

    item.charges = 3
    ctx:set(wand, component.ITEM, item)

    harness.truthy(theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    }), "whole wand can be stolen")

    harness.equal(ctx:get(wand, component.CARRIED_BY).holder,
        maurice, "whole item retains its entity identity")
    harness.equal(ctx:get(wand, component.ITEM).charges, 3,
        "whole transfer preserves the wand's charges")

    local spare = carried(ctx, player, items.WAND_FLAME, 1)

    harness.falsy(theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    }), "occupied monster wand slot excludes another wand")

    harness.equal(ctx:get(spare, component.CARRIED_BY).holder,
        player, "slot rejection leaves the second wand with player")

    ctx:destroy(spare)
end

-- A two-handed theft releases Maurice's shield at his feet before the
-- weapon becomes active. Keeping both would grant impossible defenses.
local function two_handed_weapon(ctx, game, player)
    local thief = fixture.actor(ctx, monsters.MONS_MAURICE,
        12, 10, 1000)
    local shield = carried(ctx, thief, items.ARM_BUCKLER, 1, "shield")
    local sword = carried(ctx, player, items.WPN_GREAT_SWORD, 1)

    ctx:add(thief, component.AI, {
        behavior = "seek",
    })

    harness.truthy(theft.apply(game, {
        kind = "hit",
        attacker = thief,
        defender = player,
    }), "Maurice can steal a two-handed sword")

    harness.equal(ctx:get(sword, component.CARRIED_BY).holder,
        thief, "stolen sword belongs to Maurice")
    harness.equal(ctx:get(sword, component.EQUIPPED).slot,
        "weapon", "two-handed sword becomes the active weapon")
    harness.falsy(ctx:has(shield, component.CARRIED_BY),
        "two-handed theft releases the old shield")
    harness.falsy(ctx:has(shield, component.EQUIPPED),
        "released shield no longer grants defense")
    harness.truthy(ctx:has(shield, component.POSITION),
        "released shield stays on the dungeon floor")
end

-- A stolen melee weapon occupies Maurice's normal weapon slot. The next
-- eligible weapon uses the source alternate slot instead of replacing it.
local function weapon_slots(ctx, game, maurice, player)
    local first = carried(ctx, player, items.WPN_DAGGER, 1)

    theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    })

    harness.equal(ctx:get(first, component.EQUIPPED).slot, "weapon",
        "first stolen weapon occupies Maurice's weapon slot")

    local second = carried(ctx, player, items.WPN_DAGGER, 1)

    theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    })

    harness.equal(ctx:get(second, component.EQUIPPED).slot,
        "alternate_weapon", "second stolen weapon uses alternate slot")
end

-- Equipping an item or beginning a saved equipment action removes it
-- from the source candidate pool before weighted selection.
local function protected_items(ctx, game, maurice, player)
    local weapon = carried(ctx, player, items.WPN_DAGGER, 1, "weapon")
    local armour = carried(ctx, player,
        items.ARM_ROBE, 1)

    ctx:add(player, component.EQUIPMENT_DELAY, {
        phase = "wear",
        slot = "body",
        item_id = armour,
        remaining = 2,
    })

    harness.falsy(theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    }), "Maurice cannot take equipped or in-use items")

    harness.equal(ctx:get(weapon, component.CARRIED_BY).holder, player,
        "wielded weapon stays with player")
    harness.equal(ctx:get(armour, component.CARRIED_BY).holder, player,
        "pending wear item stays with player")

    ctx:remove(player, component.EQUIPMENT_DELAY)

    return armour
end

-- The source's one-in-ten gold diversion wins even with an eligible robe.
-- With no eligible item it always creates or grows monster-carried gold.
local function gold_fallback(ctx, game, maurice, player, armour)
    ctx:add(player, component.WALLET, {
        gold = 100,
    })

    harness.truthy(theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    }), "gold fallback transfers physical loot")

    local gold = owned(ctx, maurice, items.OBJ_GOLD)

    harness.equal(ctx:get(player, component.WALLET).gold, 80,
        "gold theft debits balance without a shop purchase")
    harness.equal(ctx:get(player, component.WALLET).purchases, 0,
        "theft does not count as a purchase")
    harness.equal(#gold, 1,
        "first gold theft creates one monster-carried pile")
    harness.equal(ctx:get(gold[1], component.ITEM).quantity, 20,
        "source gold range starts at twenty")

    harness.equal(ctx:get(armour, component.CARRIED_BY).holder,
        player, "one-in-ten gold diversion leaves eligible robe alone")

    ctx:destroy(armour)

    theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    })

    harness.equal(#owned(ctx, maurice, items.OBJ_GOLD), 1,
        "later theft accumulates in the same gold slot")
    harness.equal(ctx:get(gold[1], component.ITEM).quantity, 40,
        "repeated source gold draws add to carried loot")
    harness.equal(ctx:get(gold[1], component.GOLD_TITHE).state,
        tithe_states.NO_PIETY,
        "recovered gold keeps its source tithe exclusion")

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.ZIN,
    })

    theft.apply(game, {
        kind = "hit",
        attacker = maurice,
        defender = player,
    })

    harness.equal(ctx:get(gold[1], component.GOLD_TITHE).state,
        tithe_states.NO_TITHE,
        "Zin cannot tithe the same stolen coins again")

    ctx:add(maurice, component.AI, {
        behavior = "seek",
    })

    save_inventory.validate(game)
end

-- The live melee path must dispatch Maurice's catalog attack after a
-- physical hit, rather than only passing direct policy calls.
local function live_contact(ctx, game)
    local maurice = fixture.actor(ctx, monsters.MONS_MAURICE,
        40, 40, 1000)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        41, 40, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.ITEM_KNOWLEDGE, {
        known_types = {
            [items.POT_CURING] = true,
            [items.SCR_TELEPORTATION] = true,
            [items.WAND_FLAME] = true,
        },
    })
    ctx:add(player, component.PROGRESSION, {
        level = 27,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.COMBAT, {
        shield_blocks = 0,
    })
    ctx:add(player, component.WALLET, {
        gold = 100,
    })

    game.player_entity = player

    function game:random(_, bound)
        return bound - 1
    end

    actions.monster(game, maurice)

    harness.truthy(ctx:get(player, component.WALLET).gold < 100,
        "live Maurice melee reaches the gold theft owner")
    harness.equal(#owned(ctx, maurice, items.OBJ_GOLD), 1,
        "live melee leaves stolen gold on Maurice")
end

-- The common world gives direct policy cases and a separate full melee
-- case real actors, components, catalogs, and event delivery.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        11, 10, 1000)
    local maurice = fixture.actor(ctx, monsters.MONS_MAURICE,
        10, 10, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })

    local game = fixture.context(ctx, player)
    ctx:add(player, component.ITEM_KNOWLEDGE, {
        known_types = {
            [items.POT_CURING] = true,
            [items.SCR_TELEPORTATION] = true,
            [items.WAND_FLAME] = true,
        },
    })
    local potion = contact_gates(ctx, game, maurice, player)

    partial_stack(ctx, game, maurice, player, potion)
    weighted_choice(ctx, game, maurice, player)
    whole_item(ctx, game, maurice, player)
    two_handed_weapon(ctx, game, player)
    weapon_slots(ctx, game, maurice, player)
    local armour = protected_items(ctx, game, maurice, player)

    gold_fallback(ctx, game, maurice, player, armour)
    live_contact(ctx, game)
end

return test
