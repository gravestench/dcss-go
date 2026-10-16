local attunement = require("policy.jewellery.attunement")
local capabilities = require("constants.jewellery_capabilities")
local component = require("constants.component")
local equipment = require("policy.inventory.equipment")
local jewellery = require("policy.inventory.jewellery")
local effects = require("policy.inventory.jewellery_effects")
local fixture = require("tests.fixtures.jewellery")
local harness = require("tests.harness")
local ids = require("ids.items")
local regeneration = require("policy.character.regeneration")
local spirit_shield = require("policy.combat.spirit_shield")
local save_jewellery = require("policy.save.jewellery")
local acrobat = require("policy.jewellery.acrobat")
local fighter = require("policy.combat.fighter")
local navigation = require("policy.commands.entries_navigation")
local command_prepare = require("policy.command_prepare")
local command_action_start = require("policy.command_action_start")
local commands = require("policy.input.commands")
local terrain = require("constants.terrain")
local mutations = require("ids.mutations")
local mutation_classes = require("constants.mutation_classes")
local mutation_records = require("policy.mutations.records")

local test = {}

local function finish(ctx, player, delay)
    equipment.start(ctx, player, delay)

    for _ = 1, 4 do
        equipment.advance(ctx, player)
    end
end

local function check_hp_attunement(ctx)
    local battle, player = fixture.player(ctx)
    local amulet = fixture.carry(ctx, player, ids.AMU_REGENERATION)

    ctx:add(player, component.HEALTH, { current = 5, max = 10 })
    ctx:add(player, component.MAGIC, { current = 3, max = 3 })

    local baseline = regeneration.rates(battle, player, 10, 3)
    local wear = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(amulet),
    })

    finish(battle, player, wear.delay)

    local state = ctx:get(amulet, component.JEWELLERY_ATTUNEMENT)

    harness.falsy(state.active, "injured player cannot attune HP amulet")
    harness.equal(effects.sum(battle, player, capabilities.HP_REGEN), 0,
        "inert amulet grants no HP regeneration")

    local health = ctx:get(player, component.HEALTH)
    health.current = health.max
    ctx:set(player, component.HEALTH, health)
    attunement.refresh(battle, player)

    harness.truthy(ctx:get(amulet,
        component.JEWELLERY_ATTUNEMENT).active,
        "HP amulet attunes when health reaches full")

    local hp_rate = regeneration.rates(battle, player, 10, 3)

    harness.equal(hp_rate, baseline + 80,
        "attuned amulet adds one source regeneration pip")

    mutation_records.grant_acquired(ctx, player,
        mutations.MUT_NO_REGENERATION, 1)
    attunement.refresh(battle, player)
    harness.falsy(ctx:get(amulet,
        component.JEWELLERY_ATTUNEMENT).active,
        "losing HP regeneration deactivates an attuned amulet")

    mutation_records.delete(ctx, player, mutations.MUT_NO_REGENERATION,
        mutation_classes.ACQUIRED, 1)
    attunement.refresh(battle, player)
    harness.truthy(ctx:get(amulet,
        component.JEWELLERY_ATTUNEMENT).active,
        "full health attunes again when regeneration returns")

    harness.truthy(pcall(save_jewellery.run, battle, player),
        "equipped attunement survives save validation")

    local active = ctx:get(amulet, component.JEWELLERY_ATTUNEMENT)
    ctx:remove(amulet, component.JEWELLERY_ATTUNEMENT)
    harness.falsy(pcall(save_jewellery.run, battle, player),
        "a saved regeneration amulet requires attunement state")
    ctx:add(amulet, component.JEWELLERY_ATTUNEMENT, active)

    local remove = jewellery.prepare_remove(battle, player, {
        item_id = ctx:id(amulet),
    })

    finish(battle, player, remove.delay)
    harness.falsy(ctx:has(amulet, component.JEWELLERY_ATTUNEMENT),
        "removing the amulet clears saved attunement")
    ctx:add(amulet, component.JEWELLERY_ATTUNEMENT, active)
    harness.falsy(pcall(save_jewellery.run, battle, player),
        "orphaned attunement fails save validation")
    ctx:remove(amulet, component.JEWELLERY_ATTUNEMENT)
end

local function check_mp_attunement(ctx)
    local battle, player = fixture.player(ctx)
    local amulet = fixture.carry(ctx, player, ids.AMU_MANA_REGENERATION)

    ctx:add(player, component.HEALTH, { current = 10, max = 10 })
    ctx:add(player, component.MAGIC, { current = 1, max = 3 })

    local _, baseline = regeneration.rates(battle, player, 10, 3)
    local wear = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(amulet),
    })

    finish(battle, player, wear.delay)

    harness.falsy(ctx:get(amulet,
        component.JEWELLERY_ATTUNEMENT).active,
        "low MP leaves the mana amulet inert")

    local magic = ctx:get(player, component.MAGIC)
    magic.current = magic.max
    ctx:set(player, component.MAGIC, magic)
    attunement.refresh(battle, player)

    local _, mp_rate = regeneration.rates(battle, player, 10, 3)

    harness.equal(mp_rate, baseline + 40,
        "attuned mana amulet adds source MP regeneration")
end

local function check_spirit_shield(ctx)
    local battle, player = fixture.player(ctx)
    local amulet = fixture.carry(ctx, player, ids.AMU_GUARDIAN_SPIRIT)

    ctx:add(amulet, component.EQUIPPED, { slot = "amulet" })
    harness.truthy(spirit_shield.active(battle, player),
        "guardian spirit capability activates the existing shield")
    ctx:remove(amulet, component.EQUIPPED)
    harness.falsy(spirit_shield.active(battle, player),
        "removing guardian spirit disables the shield")
end

local function check_reflection_shield(ctx)
    local battle, player = fixture.player(ctx)
    local amulet = fixture.carry(ctx, player, ids.AMU_REFLECTION)
    local baseline = fighter.defense(battle).shield_class

    ctx:add(amulet, component.EQUIPPED, { slot = "amulet" })

    harness.equal(fighter.defense(battle).shield_class, baseline + 10,
        "reflection amulet adds source shield points")
end

local function check_regeneration_restrictions(ctx)
    local battle, player = fixture.player(ctx)
    local health_amulet = fixture.carry(ctx, player, ids.AMU_REGENERATION)

    ctx:add(player, component.HEALTH, { current = 10, max = 10 })
    ctx:add(player, component.MAGIC, { current = 0, max = 0 })
    mutation_records.grant_acquired(ctx, player,
        mutations.MUT_NO_REGENERATION, 1)

    local wear = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(health_amulet),
    })

    finish(battle, player, wear.delay)
    harness.falsy(ctx:get(health_amulet,
        component.JEWELLERY_ATTUNEMENT).active,
        "no-regeneration mutation prevents HP amulet attunement")

    mutation_records.delete(ctx, player, mutations.MUT_NO_REGENERATION,
        mutation_classes.ACQUIRED, 1)

    local health = ctx:get(player, component.HEALTH)
    health.current = 5
    ctx:set(player, component.HEALTH, health)
    attunement.refresh(battle, player)
    harness.falsy(ctx:get(health_amulet,
        component.JEWELLERY_ATTUNEMENT).active,
        "HP amulet stays inert until health becomes full")

    local remove = jewellery.prepare_remove(battle, player, {
        item_id = ctx:id(health_amulet),
    })

    finish(battle, player, remove.delay)

    local magic_amulet = fixture.carry(ctx, player,
        ids.AMU_MANA_REGENERATION)

    mutation_records.grant_acquired(ctx, player,
        mutations.MUT_HP_CASTING, 1)

    wear = jewellery.prepare_put_on(battle, player, {
        item_id = ctx:id(magic_amulet),
    })

    finish(battle, player, wear.delay)
    harness.falsy(ctx:get(magic_amulet,
        component.JEWELLERY_ATTUNEMENT).active,
        "HP casting prevents 0/0 MP from attuning a mana amulet")

    mutation_records.delete(ctx, player, mutations.MUT_HP_CASTING,
        mutation_classes.ACQUIRED, 1)
    ctx:set(player, component.MAGIC, { current = 1, max = 3 })
    attunement.refresh(battle, player)
    harness.falsy(ctx:get(magic_amulet,
        component.JEWELLERY_ATTUNEMENT).active,
        "mana amulet waits for full MP after HP casting ends")
end

local function check_acrobat(ctx)
    local battle, player = fixture.player(ctx)
    local amulet = fixture.carry(ctx, player, ids.AMU_ACROBAT)

    function battle.cell()
        return terrain.DNGN_FLOOR
    end

    ctx:add(amulet, component.EQUIPPED, { slot = "amulet" })
    ctx:add(player, component.HEALTH, { current = 10, max = 10 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 5,
        y = 5,
    })

    local baseline = fighter.defense(battle).ev
    local wait = navigation.wait(battle, player, nil, nil, nil)

    harness.truthy(wait.explicit_wait,
        "explicit wait marks the acrobat action window")

    local prepared = command_prepare.run(battle, { kind = commands.wait })

    command_action_start.run(battle, {
        waited_explicitly = prepared.explicit_wait,
    })
    harness.equal(fighter.defense(battle).ev, baseline + 15,
        "waiting with acrobat grants the source EV bonus")
    harness.truthy(pcall(save_jewellery.run, battle, player),
        "the action window survives save validation")

    acrobat.begin_action(battle, player, false)
    harness.equal(fighter.defense(battle).ev, baseline,
        "another action expires the acrobat bonus")

    ctx:add(player, "magic.channel", {
        spell_id = "test_channel",
    })

    local channel_wait = navigation.wait(battle, player, nil, nil, nil)

    harness.truthy(channel_wait.explicit_wait,
        "channelled explicit wait retains the acrobat action window")
    prepared = command_prepare.run(battle, { kind = commands.wait })
    command_action_start.run(battle, {
        waited_explicitly = prepared.explicit_wait,
    })
    harness.equal(fighter.defense(battle).ev, baseline + 15,
        "channelled wait activates acrobat through command preparation")
    ctx:remove(player, "magic.channel")

    acrobat.moved(battle, player)
    harness.equal(fighter.defense(battle).ev, baseline + 15,
        "movement grants the same source EV bonus")

    ctx:remove(amulet, component.EQUIPPED)
    acrobat.equipment_changed(battle, player)
    harness.equal(acrobat.bonus(battle, player), 0,
        "removing the amulet clears acrobat")
    harness.falsy(ctx:has(player, component.JEWELLERY_ACROBAT),
        "no orphaned saved acrobat state remains")
end

function test.run(ctx)
    check_hp_attunement(ctx)
    check_mp_attunement(ctx)
    check_regeneration_restrictions(ctx)
    check_spirit_shield(ctx)
    check_reflection_shield(ctx)
    check_acrobat(ctx)
end

return test
