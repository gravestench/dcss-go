-- Exercise the production item catalog and saved ECS choice, rather than
-- mirroring the blessing's predicates in a separate test declaration.
local abilities = require("ids.abilities")
local blessing = require("policy.abilities.lugonu.bless_weapon")
local brands = require("constants.weapon_brands")
local component = require("constants.component")
local commands = require("policy.commands.abilities")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local species = require("ids.species")

local test = {}

-- Give one melee and one ranged weapon to a real Lugonu worshipper.
-- Only the melee entity may enter the confirmation and timed action.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_ABYSSAL_KNIGHT,
        name = "Blessing tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.LUGONU,
        piety = piety.breakpoint(6),
    })
    ctx:add(player, component.ITEM_KNOWLEDGE, {})

    local sword = ctx:create()
    local bow = ctx:create()

    ctx:add(sword, component.ITEM, {
        kind_id = items.WPN_LONG_SWORD,
        quantity = 1,
        plus = 8,
    })
    ctx:add(sword, component.CARRIED_BY, { holder = player })
    ctx:add(bow, component.ITEM, {
        kind_id = items.WPN_SHORTBOW,
        quantity = 1,
    })
    ctx:add(bow, component.CARRIED_BY, { holder = player })

    harness.truthy(blessing.eligible(ctx, player, sword))
    harness.falsy(blessing.eligible(ctx, player, bow))

    local menu = blessing.prepare(ctx, player, {})

    harness.equal(#menu.selection.options, 1)
    harness.equal(menu.selection.options[1].id,
        tostring(ctx:id(sword)))

    local confirm = blessing.prepare(ctx, player, {
        target_id = tostring(ctx:id(sword)),
    })

    harness.truthy(confirm.confirmation)
    harness.truthy(ctx:has(player, component.LUGONU_BLESS_CHOICE))
    blessing.validate(ctx, player)
    harness.equal(blessing.prepare(ctx, player, { cancelled = true }),
        "Okay.")
    harness.falsy(ctx:has(player, component.LUGONU_BLESS_CHOICE))

    blessing.prepare(ctx, player, {
        target_id = tostring(ctx:id(sword)),
    })

    -- Esc must clear an owned prompt even after conversion removes the
    -- ability from the menu; otherwise the command slot stays locked.
    local changed_worship = ctx:get(player,
        component.RELIGION_WORSHIP)

    changed_worship.god_id = gods.NO_GOD
    ctx:set(player, component.RELIGION_WORSHIP,
        changed_worship)

    local cancelled = commands.prepare(ctx, player, {
        ability_id = abilities.LUGONU_BLESS_WEAPON,
        cancelled = true,
    })

    harness.equal(cancelled.message, "Okay.")
    harness.falsy(ctx:has(player, component.LUGONU_BLESS_CHOICE))
    changed_worship.god_id = gods.LUGONU
    ctx:set(player, component.RELIGION_WORSHIP,
        changed_worship)

    blessing.prepare(ctx, player, {
        target_id = tostring(ctx:id(sword)),
    })
    harness.equal(blessing.prepare(ctx, player, { forced = true }), nil)

    blessing.resolve(ctx, player, {
        ability_id = abilities.LUGONU_BLESS_WEAPON,
        item_id = sword,
    })

    local changed = ctx:get(sword, component.ITEM)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(changed.ego, brands.DISTORTION)
    harness.equal(changed.plus, 9)
    harness.truthy(worship.one_time_abilities[gods.LUGONU])
    harness.falsy(registry.usable_now(ctx, player,
        registry.get(abilities.LUGONU_BLESS_WEAPON)))
end

return test
