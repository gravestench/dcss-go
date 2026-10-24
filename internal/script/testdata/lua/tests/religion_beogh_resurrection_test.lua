-- Resurrection reads the saved actor from an ordinary corpse and uses
-- the normal monster factory and grid owner to return it to play.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local component = require("constants.component")
local corpse = require("policy.abilities.beogh.corpse")
local death = require("policy.death")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local items = require("ids.items")
local monster_slots = require("constants.monster_equipment_slots")
local gift_categories = require("constants.beogh_gift_categories")
local monsters = require("ids.monsters")
local resurrection = require("policy.abilities.beogh.resurrection")
local species = require("ids.species")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- The source body is consumed only after a valid adjacent placement.
-- Its name, HP, and prior gift history become the new follower's state.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        10, 10, 20)
    local orc = fixture.actor(ctx, monsters.MONS_ORC, 12, 10, 1)
    local gear = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HILL_ORC,
        job_id = jobs.JOB_FIGHTER,
        name = "Resurrection tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.BEOGH,
        piety = 200,
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(orc, component.BEOGH_ORC, {
        attitude = attitudes.FRIENDLY,
        attempted = true,
        gift = true,
        gift_category = gift_categories.MELEE_WEAPON,
    })
    ctx:add(orc, component.VAULT_ACTOR_OVERRIDES, {
        custom_name = "Burguk",
    })
    ctx:add(gear, component.ITEM, {
        kind_id = items.WPN_CLUB,
        quantity = 1,
    })
    ctx:add(gear, component.CARRIED_BY, { holder = orc })
    ctx:add(gear, component.EQUIPPED, {
        slot = monster_slots.WEAPON,
    })

    local game = fixture.context(ctx, player)

    function game:random()
        return 0
    end

    local definition = catalog.get("monsters", monsters.MONS_ORC)
    local body = death.corpse(game, definition,
        ctx:get(player, component.POSITION))

    harness.truthy(body)
    local dropped = death.drop_inventory(game, orc,
        ctx:get(player, component.POSITION))

    corpse.record(game, orc, body, dropped)
    corpse.validate(game, body)

    -- A forged snapshot cannot restore an impossible zero-HP actor.
    local saved = ctx:get(body, component.BEOGH_CORPSE)

    saved.max_hp = 0
    ctx:set(body, component.BEOGH_CORPSE, saved)

    local valid = pcall(corpse.validate, game, body)

    harness.falsy(valid)
    saved.max_hp = 100
    ctx:set(body, component.BEOGH_CORPSE, saved)

    -- A forged slot pointing at a real weapon must fail before restore.
    saved.dropped_gear[monster_slots.SHIELD] = ctx:id(gear)
    ctx:set(body, component.BEOGH_CORPSE, saved)
    harness.falsy(pcall(corpse.validate, game, body))
    saved.dropped_gear[monster_slots.SHIELD] = nil
    ctx:set(body, component.BEOGH_CORPSE, saved)

    game:remove_actor(orc)
    ctx:destroy(orc)

    local first = resurrection.prepare(game, player, {})

    harness.equal(first.selection.options[1].id,
        tostring(ctx:id(body)))

    saved.custom_name = ""
    ctx:set(body, component.BEOGH_CORPSE, saved)

    local unnamed = resurrection.prepare(game, player, {
        target_id = tostring(ctx:id(body)),
    })

    harness.equal(unnamed.confirmation,
        "Resurrect " .. definition.name .. "?")
    saved.custom_name = "Burguk"
    ctx:set(body, component.BEOGH_CORPSE, saved)
    resurrection.prepare(game, player, { cancelled = true })

    local confirm = resurrection.prepare(game, player, {
        target_id = tostring(ctx:id(body)),
    })

    harness.truthy(confirm.confirmation)
    resurrection.validate(game, player)

    local chosen = { forced = true }

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(10 + dx) .. ":" .. (10 + dy)] = true
            end
        end
    end

    harness.equal(resurrection.prepare(game, player, chosen),
        "There's no room!")

    harness.truthy(ctx:has(body, component.BEOGH_CORPSE))
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).piety,
        200)

    game.walls = {}
    resurrection.prepare(game, player, {
        target_id = tostring(ctx:id(body)),
    })
    chosen = { forced = true }
    resurrection.prepare(game, player, chosen)
    resurrection.resolve(game, player, {
        item_id = ctx:entity(chosen.item_id),
    })

    local followers = ctx:query({ component.BEOGH_RESURRECTED })

    harness.equal(#followers, 1)
    harness.equal(ctx:get(followers[1], component.HEALTH).current,
        100)
    harness.equal(ctx:get(followers[1],
        component.BEOGH_ORC).gift_category,
        gift_categories.MELEE_WEAPON)
    harness.equal(ctx:get(followers[1],
        component.VAULT_ACTOR_OVERRIDES).custom_name, "Burguk")
    harness.equal(ctx:get(gear, component.CARRIED_BY).holder,
        followers[1])
    harness.equal(ctx:get(gear, component.EQUIPPED).slot,
        monster_slots.WEAPON)
    harness.falsy(ctx:has(body, component.BEOGH_CORPSE))
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).piety,
        173)
end

return test
