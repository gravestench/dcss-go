-- Fastroot should expire after its saved duration.

local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local fastroot = require("policy.magic.effects.zaps.fastroot")
local flight = require("policy.combat.flight")
local harness = require("tests.harness")
local monster_fixture = require("tests.monster_ally_support_fixture")
local monsters = require("ids.monsters")
local unravelling = require("policy.magic.effects.zaps.unravelling")
local zap_ids = require("policy.magic.effects.zaps.ids")

local test = {}

-- Resolve a zap against a real monster entity to verify damage, resistance,
-- and status hooks use its saved components rather than catalog data alone.
function test.run(ctx)
    local game = monster_fixture.observed_context(ctx)
    local giant = ctx:create()

    ctx:add(giant, component.ACTOR, {
        kind_id = monsters.MONS_STONE_GIANT,
        speed = 10,
    })
    ctx:add(giant, component.HEALTH, {
        current = 500,
        max = 500,
    })
    ctx:add(giant, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    local definition = require("policy.catalog").get(
        "monsters", monsters.MONS_STONE_GIANT)

    unravelling.affect_monster(game, giant, 60)

    local current = ctx:get(giant, component.HEALTH)
    local mutation = ctx:get(giant, zap_ids.component.WRETCHED)

    harness.truthy(current.current < 500,
        "Unravelling's mutagenic blast must damage its victim")
    harness.truthy(mutation and mutation.remaining_aut > 0,
        "Unravelling must apply saved monster malmutation")
    harness.equal(defense.armour(ctx, giant, definition),
        math.max(0, (definition.ac or 0) - 8),
        "Wretched must reduce current monster AC by eight")

    ctx:add(giant, component.GRASPING_ROOTS, {
        source = giant,
        remaining_aut = 20,
        power = 50,
        held_aut = 0,
        escape_attempts = 0,
    })

    harness.truthy(fastroot.restrained(ctx, giant),
        "Fastroot should restrain while its saved mark lasts")
    harness.truthy(defense.evasion(ctx, giant, definition) <
        (definition.ev or 0),
        "Fastroot should lower current monster EV")

    fastroot.tick_monster(ctx, giant)
    harness.truthy(fastroot.restrained(ctx, giant),
        "Fastroot should remain after one ten-aut tick")

    fastroot.tick_monster(ctx, giant)
    harness.falsy(fastroot.restrained(ctx, giant),
        "Fastroot should expire after its saved duration")

    local flyer = harness.actor_with(ctx, component.ZAP_FLIGHT, {
        remaining_aut = 60,
    })

    harness.truthy(flight.active(ctx, flyer),
        "Vortex flight should be projected from saved state")
    ctx:remove(flyer, component.ZAP_FLIGHT)
    harness.falsy(flight.active(ctx, flyer),
        "Flight should end when its saved duration ends")
end

return test
