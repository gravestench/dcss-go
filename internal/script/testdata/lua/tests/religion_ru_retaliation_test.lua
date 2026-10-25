-- Ru's second passive responds to final HP loss through the shared
-- damage owner. These cases exercise real ECS statuses and catalog HD.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")
local monsters = require("ids.monsters")
local player_health = require("policy.combat.player_health")
local retaliation = require("policy.religion.ru.retaliation")
local status = require("policy.combat.monster_hexes.status")

local test = {}

-- Each case owns a player and source on a sparse floor, while all status
-- schemas and monster definitions come from the production mod.
local function case_at(ctx, x, kind_id, piety)
    local player = ctx:create()
    local game = fixture.context(ctx, player)
    local monster = fixture.actor(ctx, kind_id, x, 5, 100)

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = x,
        y = 7,
    })
    ctx:add(player, component.HEALTH, {
        current = 1000,
        max = 1000,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = piety,
    })

    -- Zero selects the successful chance and minimum enchant duration.
    function game:random(_, _)
        return 0
    end

    return game, player, monster
end

-- The source first tests piety chance, then computes power from damage
-- minus twice the target's current HD. Distinct damage pins each branch.
function test.run(ctx)
    local magic, wizard_player, wizard = case_at(ctx,
        5, monsters.MONS_ORC_WIZARD, 160)

    retaliation.on_damage(magic, wizard_player, 57,
        "hit", wizard)
    harness.equal(ctx:get(wizard,
        component.MONSTER_ENFEEBLE).antimagic_aut, 51)

    local paralyze, paralyze_player, orc = case_at(ctx,
        10, monsters.MONS_ORC, 160)

    retaliation.on_damage(paralyze, paralyze_player, 53,
        "hit", orc)
    harness.equal(ctx:get(orc,
        component.PARALYSIS).remaining_aut, 51)

    -- Unsusceptible high-power monsters fall through to paralysis.
    retaliation.on_damage(paralyze, paralyze_player, 53,
        "hit", orc)
    harness.equal(ctx:get(orc,
        component.PARALYSIS).remaining_aut, 102)

    local slowing, slow_player, slow_target = case_at(ctx,
        15, monsters.MONS_ORC, 160)

    retaliation.on_damage(slowing, slow_player, 28,
        "hit", slow_target)
    harness.equal(ctx:get(slow_target,
        component.PROJECTILE_SLOW).remaining_aut, 26)

    local blinding, blind_player, blind_target = case_at(ctx,
        20, monsters.MONS_ORC, 160)

    retaliation.on_damage(blinding, blind_player, 13,
        "hit", blind_target)
    harness.equal(ctx:get(blind_target,
        component.MONSTER_ENCHANT).blind_aut, 11)

    local illuminating, lit_player, lit_target = case_at(ctx,
        25, monsters.MONS_ORC, 160)

    retaliation.on_damage(illuminating, lit_player, 3,
        "hit", lit_target)
    harness.truthy(status.backlit(ctx, lit_target))

    -- Unblindable species skip blindness but may still be illuminated.
    local immune, immune_player, bat = case_at(ctx,
        30, monsters.MONS_FIRE_BAT, 160)
    local bounds = {}

    function immune:random(_, bound)
        bounds[#bounds + 1] = bound

        return 0
    end

    retaliation.on_damage(immune, immune_player, 21,
        "hit", bat)
    harness.truthy(status.backlit(ctx, bat))
    harness.truthy(not ctx:has(bat, component.MONSTER_ENCHANT))
    harness.equal(bounds[#bounds], 150)
    harness.truthy(bounds[#bounds - 1] ~= 100)

    -- The health boundary invokes the registered rule after a real hit;
    -- later piety and penance changes must remove eligibility immediately.
    local live, live_player, live_target = case_at(ctx,
        35, monsters.MONS_ORC, 160)

    player_health.damage(live, live_player, 53, false, live_target)
    harness.truthy(ctx:has(live_target, component.PARALYSIS))

    local worship = ctx:get(live_player,
        component.RELIGION_WORSHIP)

    worship.piety = 29
    ctx:set(live_player, component.RELIGION_WORSHIP, worship)
    ctx:remove(live_target, component.PARALYSIS)
    retaliation.on_damage(live, live_player, 53,
        "hit", live_target)
    harness.truthy(not ctx:has(live_target, component.PARALYSIS))

    worship.piety = 160
    worship.penance[gods.RU] = 1
    ctx:set(live_player, component.RELIGION_WORSHIP, worship)
    retaliation.on_damage(live, live_player, 53,
        "hit", live_target)
    harness.truthy(not ctx:has(live_target, component.PARALYSIS))

    worship.penance[gods.RU] = 0
    worship.god_id = gods.ZIN
    ctx:set(live_player, component.RELIGION_WORSHIP, worship)
    retaliation.on_damage(live, live_player, 53,
        "hit", live_target)
    harness.truthy(not ctx:has(live_target, component.PARALYSIS))

    -- A failed one-in-five roll never draws damage power or duration.
    local failed, failed_player, failed_target = case_at(ctx,
        40, monsters.MONS_ORC, 160)
    local failed_bounds = {}

    function failed:random(_, bound)
        failed_bounds[#failed_bounds + 1] = bound

        return bound == 5 and 1 or 0
    end

    retaliation.on_damage(failed, failed_player, 53,
        "hit", failed_target)
    harness.equal(#failed_bounds, 1)
    harness.equal(failed_bounds[1], 5)
    harness.truthy(not ctx:has(failed_target,
        component.PARALYSIS))

    -- Source ouch.cc checks the chance before resolving a lost monster ID.
    local missing, missing_player = case_at(ctx,
        45, monsters.MONS_ORC, 160)
    local missing_bounds = {}

    function missing:random(_, bound)
        missing_bounds[#missing_bounds + 1] = bound

        return 0
    end

    retaliation.on_damage(missing, missing_player, 53,
        "hit", nil)
    harness.equal(#missing_bounds, 1)
    harness.equal(missing_bounds[1], 5)

    -- A dead source likewise consumes the chance without power or
    -- duration draws; the health owner must not resurrect its status.
    local dead, dead_player, dead_target = case_at(ctx,
        48, monsters.MONS_ORC, 160)
    local dead_bounds = {}
    local dead_health = ctx:get(dead_target, component.HEALTH)

    dead_health.current = 0
    ctx:set(dead_target, component.HEALTH, dead_health)

    function dead:random(_, bound)
        dead_bounds[#dead_bounds + 1] = bound

        return 0
    end

    retaliation.on_damage(dead, dead_player, 53,
        "hit", dead_target)
    harness.equal(#dead_bounds, 1)
    harness.equal(dead_bounds[1], 5)
    harness.truthy(not ctx:has(dead_target, component.PARALYSIS))

    -- Nondivisible piety consumes a rounding draw before the chance,
    -- then another before power. The resulting bounds pin stream order.
    local rounded, rounded_player, rounded_target = case_at(ctx,
        50, monsters.MONS_ORC, 159)
    local rounded_bounds = {}

    function rounded:random(_, bound)
        rounded_bounds[#rounded_bounds + 1] = bound

        return 0
    end

    retaliation.on_damage(rounded, rounded_player, 53,
        "hit", rounded_target)
    local expected_bounds = {159, 6, 32, 50, 60}

    harness.equal(#rounded_bounds, #expected_bounds)

    for index, bound in ipairs(expected_bounds) do
        harness.equal(rounded_bounds[index], bound)
    end
    harness.truthy(ctx:has(rounded_target,
        component.PARALYSIS))
end

return test
