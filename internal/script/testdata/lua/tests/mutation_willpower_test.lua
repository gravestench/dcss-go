local component = require("constants.component")
local armour_egos = require("constants.armour_egos")
local classes = require("constants.mutation_classes")
local items = require("ids.items")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local resistance = require("policy.combat.player_resistance")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

local function player_context(ctx, owner)
    local proxy = setmetatable({}, { __index = ctx })

    function proxy.player()
        return owner
    end

    return proxy
end

local function equip(ctx, owner, kind_id, slot, ego)
    local item = ctx:create()

    ctx:add(item, component.ITEM, {
        kind_id = kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = ego or "",
    })
    ctx:add(item, component.CARRIED_BY, {
        holder = owner,
    })
    ctx:add(item, component.EQUIPPED, {
        slot = slot,
    })

    return item
end

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Willpower test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
        total_xp = 20000,
    })

    local player_ctx = player_context(ctx, player)

    harness.equal(resistance.willpower(player_ctx, player), 30,
        "Human XL10 starts with three willpower per level")

    records.grant_acquired(ctx, player, mutations.MUT_STRONG_WILLED, 2)
    harness.equal(resistance.willpower(player_ctx, player), 110,
        "each Strong-Willed level adds one forty-point pip")

    records.delete(ctx, player, mutations.MUT_STRONG_WILLED,
        classes.ACQUIRED, 2)
    records.grant_innate(ctx, player, mutations.MUT_DEMONIC_WILL, 1)
    harness.equal(resistance.willpower(player_ctx, player), 70,
        "Demonic Will adds one willpower pip")

    records.grant_acquired(ctx, player, mutations.MUT_WEAK_WILLED, 1)
    harness.equal(resistance.willpower(player_ctx, player), 30,
        "Weak-Willed removes one willpower pip")

    equip(ctx, player, items.RING_WILLPOWER, "ring_left")
    equip(ctx, player, items.ARM_QUICKSILVER_DRAGON_ARMOUR, "body")
    harness.equal(resistance.willpower(player_ctx, player), 110,
        "worn ring and body armour flags each add one pip")

    local cloak = equip(ctx, player, items.ARM_CLOAK,
        "cloak", armour_egos.WILLPOWER)

    harness.equal(resistance.willpower(player_ctx, player), 150,
        "willpower armour ego adds one pip")

    local cloak_item = ctx:get(cloak, component.ITEM)

    cloak_item.ego = armour_egos.GUILE
    ctx:set(cloak, component.ITEM, cloak_item)
    harness.equal(resistance.willpower(player_ctx, player), 30,
        "Guile armour ego removes two pips")

    records.delete(ctx, player, mutations.MUT_DEMONIC_WILL,
        classes.INNATE, 1)
    harness.equal(resistance.willpower(player_ctx, player), 0,
        "negative willpower modifiers stop at zero")
end

return test
