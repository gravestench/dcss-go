-- Give Item uses the same ECS carrier and equipment components as combat.
-- These rules test a complete two-step selection and its one-gift limit.
local abilities = require("ids.abilities")
local attitudes = require("constants.attitude")
local component = require("constants.component")
local gift_item = require("policy.abilities.beogh.gift_item")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local monster_slots = require("constants.monster_equipment_slots")
local gift_categories = require("constants.beogh_gift_categories")
local species = require("ids.species")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- A named orc, an ordinary player weapon, and live worship make the
-- selection useful without copying catalog records into the test.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 10, 10)
    local orc = fixture.actor(ctx, monsters.MONS_ORC, 11, 10)
    local item = ctx:create()
    local old_weapon = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HILL_ORC,
        job_id = jobs.JOB_FIGHTER,
        name = "Gift tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.BEOGH,
        piety = 170,
    })
    ctx:add(player, component.ITEM_KNOWLEDGE, {})
    ctx:add(orc, component.BEOGH_ORC, {
        attitude = attitudes.FRIENDLY,
        attempted = true,
        gift = true,
    })
    ctx:add(orc, component.VAULT_ACTOR_OVERRIDES, {
        custom_name = "Urug",
    })
    ctx:add(item, component.ITEM, {
        kind_id = items.WPN_HAND_AXE,
        quantity = 1,
    })
    ctx:add(item, component.CARRIED_BY, { holder = player })
    ctx:add(old_weapon, component.ITEM, {
        kind_id = items.WPN_CLUB,
        quantity = 1,
    })
    ctx:add(old_weapon, component.CARRIED_BY, { holder = orc })
    ctx:add(old_weapon, component.EQUIPPED, {
        slot = monster_slots.WEAPON,
    })

    local game = fixture.context(ctx, player)

    ctx:add(item, component.EQUIPPED, {
        slot = monster_slots.WEAPON,
    })
    harness.falsy(gift_item.eligible_item(game, player, item))
    ctx:remove(item, component.EQUIPPED)

    local first = gift_item.prepare(game, player, {})

    harness.equal(first.selection.options[1].id,
        tostring(ctx:id(orc)))

    local second = gift_item.prepare(game, player, {
        target_id = tostring(ctx:id(orc)),
    })

    harness.equal(second.selection.options[1].id,
        tostring(ctx:id(item)))
    gift_item.validate(game, player)

    -- A stale saved choice whose follower has already received a gift
    -- must fail restore rather than silently target a different orc.
    local state = ctx:get(orc, component.BEOGH_ORC)

    state.gift_category = gift_categories.MELEE_WEAPON
    ctx:set(orc, component.BEOGH_ORC, state)

    local valid = pcall(gift_item.validate, game, player)

    harness.falsy(valid)
    state.gift_category = ""
    ctx:set(orc, component.BEOGH_ORC, state)

    harness.equal(gift_item.prepare(game, player, {
        cancelled = true,
    }), "Okay.")
    harness.falsy(ctx:has(player, component.BEOGH_GIFT_CHOICE))
    gift_item.prepare(game, player, {
        target_id = tostring(ctx:id(orc)),
    })

    local chosen = {
        target_id = tostring(ctx:id(item)),
        ability_id = abilities.BEOGH_GIFT_ITEM,
    }

    harness.equal(gift_item.prepare(game, player, chosen), nil)
    gift_item.resolve(game, player, {
        item_id = ctx:entity(chosen.item_id),
    })

    harness.equal(ctx:get(item, component.CARRIED_BY).holder, orc)
    harness.equal(ctx:get(item, component.EQUIPPED).slot,
        monster_slots.WEAPON)
    harness.falsy(ctx:has(old_weapon, component.CARRIED_BY))
    harness.equal(ctx:get(old_weapon, component.POSITION).x, 11)
    harness.equal(ctx:get(orc, component.BEOGH_ORC).gift_category,
        gift_categories.MELEE_WEAPON)
    harness.falsy(gift_item.follower(game, player, orc))
end

return test
