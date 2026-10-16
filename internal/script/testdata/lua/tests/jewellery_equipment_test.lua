local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local harness = require("tests.harness")
local jewellery = require("policy.inventory.jewellery")
local ids = require("ids.items")
local species = require("ids.species")
local input_items = require("policy.input.items")
local input_commands = require("policy.input.commands")
local modals = require("policy.presentation.modals")
local jewellery_system = require("systems.item_jewellery")
local save_equipment = require("policy.save.equipment")
local intent_kinds = require("constants.intent")
local equipment = require("policy.inventory.equipment")
local play_input = require("policy.input.play")
local mutation_records = require("policy.mutations.records")
local mutations = require("ids.mutations")
local timing = require("policy.command_timing")
local inventory_items = require("policy.inventory.items")
local jewellery_kinds = require("constants.jewellery_kind")
local fixture = require("tests.fixtures.jewellery")

local test = {}
local make_player = fixture.player
local carry = fixture.carry

local function check_catalog()
    local active = 0
    local rings = 0
    local amulets = 0

    for _, definition in ipairs(catalog.all(categories.ITEMS)) do
        if definition.class == classes.OBJ_JEWELLERY and
            not definition.explicitly_removed then
            active = active + 1

            local kind = jewellery.kind(definition)

            if kind == "ring" then
                rings = rings + 1
            elseif kind == "amulet" then
                amulets = amulets + 1
            else
                error("unknown active jewellery kind " .. definition.id)
            end
        end
    end

    harness.equal(active, 24, "the pinned source has 24 active jewellery items")
    harness.equal(rings, 18, "all active rings have a slot kind")
    harness.equal(amulets, 6, "all active amulets have a slot kind")

    local valid = pcall(jewellery.kind, {
        id = "MOD_BAD_RING",
        class = classes.OBJ_JEWELLERY,
        jewellery = { kind = "other" },
    })

    harness.falsy(valid, "a modded ring with invalid slot metadata fails")

    local modded = {
        id = "MOD_ENCHANTED_RING",
        class = classes.OBJ_JEWELLERY,
        stackable = false,
        jewellery = {
            kind = jewellery_kinds.RING,
            pluses = true,
        },
    }

    harness.equal(jewellery.kind(modded), jewellery_kinds.RING,
        "a mod-added ring uses the shared slot policy")
    harness.truthy(pcall(inventory_items.validate, {
        quantity = 1,
        charges = 0,
        plus = 4,
        ego = "",
    }, modded), "a mod-added enchanted ring can save its plus")
end

local function check_commands(ctx)
    local battle, player = make_player(ctx)
    local ring = carry(ctx, player, ids.RING_PROTECTION)
    local amulet = carry(ctx, player, ids.AMU_REFLECTION)
    local put_on = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(ring),
    })

    harness.equal(put_on.intent.kind, intent_kinds.JEWELLERY_ON,
        "ring put-on uses the jewellery intent")
    harness.equal(put_on.intent.target_id, "ring_left",
        "the first free human ring slot is selected")

    ctx:add(player, "core.intent", put_on.intent)
    jewellery_system.update(battle, player)

    harness.equal(ctx:get(ring, "core.equipped").slot, "ring_left",
        "the ring is equipped through the ECS system")
    harness.truthy(jewellery.worn(battle, player).ring_left,
        "effective jewellery query returns the worn ring")

    local enchanted = ctx:get(ring, "core.item")
    enchanted.plus = 3
    ctx:set(ring, "core.item", enchanted)
    harness.truthy(pcall(save_equipment.run, battle),
        "an enchanted ring passes save validation")

    local fire = carry(ctx, player, ids.RING_FIRE)
    local invalid = ctx:get(fire, "core.item")
    invalid.plus = 1
    ctx:set(fire, "core.item", invalid)
    harness.falsy(pcall(save_equipment.run, battle),
        "a ring without pluses rejects unsupported enchantment")
    invalid.plus = 0
    ctx:set(fire, "core.item", invalid)

    local remove = jewellery.prepare_remove(battle, player, {
        item_id = ctx:id(ring),
    })

    harness.equal(remove.intent.kind, intent_kinds.JEWELLERY_OFF,
        "ring removal uses the jewellery intent")
    ctx:set(player, "core.intent", remove.intent)
    jewellery_system.update(battle, player)
    harness.falsy(ctx:has(ring, "core.equipped"),
        "ring removal clears the equipment relation")

    local second = carry(ctx, player, ids.RING_PROTECTION)
    local third = carry(ctx, player, ids.RING_PROTECTION)

    ctx:add(ring, "core.equipped", { slot = "ring_left" })
    ctx:add(second, "core.equipped", { slot = "ring_right" })

    local full = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(third),
    })

    harness.equal(full.selection.title, "Replace which ring?",
        "full ring slots request a replacement choice")

    local cancelled = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(third),
        cancelled = true,
    })

    harness.equal(cancelled.message, "Okay.",
        "Esc cancels a full-slot replacement prompt")

    local replacing = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(third),
        target_id = "ring_left",
    })

    harness.equal(replacing.intent.kind, intent_kinds.JEWELLERY_OFF,
        "ring replacement first removes the old ring")
    harness.equal(replacing.delay.phase, "ring_swap",
        "replacement keeps the new ring in a saved delay")
    ctx:set(player, "core.intent", replacing.intent)
    jewellery_system.update(battle, player)
    harness.falsy(ctx:has(ring, "core.equipped"),
        "replacing a full ring slot removes the selected ring")
    harness.falsy(ctx:has(third, "core.equipped"),
        "new ring is not worn during the first half-turn")

    equipment.start(battle, player, replacing.delay)
    harness.truthy(pcall(save_equipment.run, battle),
        "the in-progress ring swap passes save validation")
    harness.equal(timing.action_cost(battle, player, {
        intent_kind = intent_kinds.WAIT,
    }, 10), 5, "the second swap phase costs half a turn")
    equipment.advance(battle, player)
    harness.equal(ctx:get(third, "core.equipped").slot, "ring_left",
        "the replacement ring is equipped in the second half-turn")

    ctx:add(ring, "core.equipped", { slot = "ring_left" })
    harness.falsy(pcall(save_equipment.run, battle),
        "save validation rejects duplicate ring slots")
    ctx:remove(ring, "core.equipped")

    local carrier = ctx:get(third, "core.carried_by")
    ctx:remove(third, "core.carried_by")
    harness.falsy(pcall(save_equipment.run, battle),
        "save validation rejects equipped jewellery without a carrier")
    ctx:add(third, "core.carried_by", carrier)

    local amulet_on = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(amulet),
    })

    harness.equal(amulet_on.delay.slot, "amulet",
        "amulet uses the existing saved equipment delay")
    harness.equal(amulet_on.delay.phase, "wear",
        "amulet starts a wear delay")

    equipment.start(battle, player, amulet_on.delay)

    for _ = 1, 4 do
        equipment.advance(battle, player)
    end

    harness.equal(ctx:get(amulet, "core.equipped").slot, "amulet",
        "amulet wear delay equips the saved item")
    harness.truthy(pcall(save_equipment.run, battle),
        "rings and amulet pass equipped save validation")

    local amulet_off = jewellery.prepare_remove(battle, player, {
        item_id = ctx:id(amulet),
    })

    equipment.start(battle, player, amulet_off.delay)

    for _ = 1, 4 do
        equipment.advance(battle, player)
    end

    harness.falsy(ctx:has(amulet, "core.equipped"),
        "amulet removal delay clears its equipment relation")
end

local function check_species_slots(ctx)
    local human, player = make_player(ctx)

    harness.equal(#jewellery.ring_slots(human, player), 2,
        "ordinary species have two ring slots")
    mutation_records.grant_acquired(ctx, player,
        mutations.MUT_MISSING_HAND, 1)
    harness.equal(jewellery.ring_slots(human, player)[1], "ring_right",
        "missing hand removes the left ring slot")

    local octopode, octo_player = make_player(ctx)
    local identity = ctx:get(octo_player, "core.player")
    identity.species_id = species.SP_OCTOPODE
    ctx:set(octo_player, "core.player", identity)

    harness.equal(#jewellery.ring_slots(octopode, octo_player), 8,
        "Octopodes have eight tentacle ring slots")
    mutation_records.grant_acquired(ctx, octo_player,
        mutations.MUT_MISSING_HAND, 1)
    harness.equal(#jewellery.ring_slots(octopode, octo_player), 7,
        "missing tentacle removes the eighth ring slot")
end

local function check_all_active_intents(ctx)
    for _, definition in ipairs(catalog.all(categories.ITEMS)) do
        if definition.class == classes.OBJ_JEWELLERY and
            not definition.explicitly_removed then
            local battle, player = make_player(ctx)
            local entity = carry(ctx, player, definition.id)
            local prepared = jewellery.prepare_put_on(battle, player, {
                item_id = ctx:id(entity),
            })

            harness.truthy(prepared.intent,
                definition.id .. " uses the shared put-on command")
        end
    end
end

local function check_interrupted_swap(ctx)
    local battle, player = make_player(ctx)
    local old = carry(ctx, player, ids.RING_PROTECTION)
    local right = carry(ctx, player, ids.RING_FIRE)
    local replacement = carry(ctx, player, ids.RING_EVASION)

    ctx:add(old, "core.equipped", { slot = "ring_left" })
    ctx:add(right, "core.equipped", { slot = "ring_right" })

    local prepared = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(replacement),
        target_id = "ring_left",
    })

    ctx:add(player, "core.intent", prepared.intent)
    jewellery_system.update(battle, player)
    equipment.start(battle, player, prepared.delay)
    mutation_records.grant_acquired(ctx, player,
        mutations.MUT_MISSING_HAND, 1)

    local messages = equipment.advance(battle, player)

    harness.equal(messages[1], "You can no longer put on that ring.",
        "a lost ring slot cancels the pending swap")
    harness.falsy(ctx:has(replacement, "core.equipped"),
        "a cancelled swap does not equip the replacement")
    harness.falsy(ctx:has(player, "core.equipment_delay"),
        "a cancelled swap clears its delay")
end

local function check_terminal()
    harness.equal(play_input.route({ key = "P" }).screen, "put_on",
        "P opens the jewellery put-on screen")
    harness.equal(play_input.route({ key = "R" }).screen,
        "remove_jewellery", "R opens the jewellery removal screen")

    local ring = {
        id = 7,
        class = classes.OBJ_JEWELLERY,
        name = "ring of protection",
        slot = "",
        quantity = 1,
    }

    harness.equal(input_items.put_on({
        key = "a",
        inventory = { ring },
    }).kind, input_commands.wear, "P selects the generic wear command")
    harness.truthy(#modals.rows({
        mode = "put_on",
        inventory = { ring },
        height = 24,
    }).writes > 1, "put-on modal renders jewellery")

    ring.slot = "ring_left"

    harness.equal(input_items.remove_jewellery({
        key = "a",
        inventory = { ring },
    }).kind, input_commands.take_off,
        "R selects the generic remove command")
end

function test.run(ctx)
    check_catalog()
    check_commands(ctx)
    check_species_slots(ctx)
    check_all_active_intents(ctx)
    check_interrupted_swap(ctx)
    check_terminal()
end

return test
