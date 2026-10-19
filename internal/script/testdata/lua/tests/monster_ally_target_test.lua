local ally_target = require("policy.combat.monster_support.ally_target")
local component = require("constants.component")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local attitudes = require("constants.attitude")

local test = {}

-- Every target in these cases would benefit from Haste; this isolates
-- the source's alliance, genus, distance, and beam-path selection rules.
local function benefits()
    return true
end

-- The source permits cross-genus help only for the explicit order, holy,
-- and special-caster groups. Put each case beyond every earlier caster's LOS.
local function special_groups(ctx, player)
    local convoker = fixture.actor(ctx,
        monsters.MONS_IRONBOUND_CONVOKER, 20, 20)
    local rat = fixture.actor(ctx, monsters.MONS_RAT, 21, 20)
    local naga = fixture.actor(ctx, monsters.MONS_NAGA_MAGE, 30, 30)
    local snake = fixture.actor(ctx, monsters.MONS_SHOCK_SERPENT, 31, 30)
    local angel = fixture.actor(ctx, monsters.MONS_ANGEL, 40, 40)
    local apis = fixture.actor(ctx, monsters.MONS_APIS, 41, 40)
    local game = fixture.context(ctx, player)

    harness.equal(ally_target.plan(game, convoker,
        spells.SPELL_HASTE_OTHER, benefits).entity, rat,
        "the convoker can buff a different-genus genuine ally")
    harness.equal(ally_target.plan(game, naga,
        spells.SPELL_HASTE_OTHER, benefits).entity, snake,
        "Naga casters can buff Snake-genus monsters")
    harness.equal(ally_target.plan(game, angel,
        spells.SPELL_HASTE_OTHER, benefits).entity, apis,
        "holy casters can buff a different holy genus")
end

-- Source firewood is not a recipient; an ineligible monster standing on
-- the beam ray still intercepts a more distant eligible ally.
local function blockers(ctx, player)
    local convoker = fixture.actor(ctx,
        monsters.MONS_IRONBOUND_CONVOKER, 50, 50)
    fixture.actor(ctx, monsters.MONS_PLANT, 51, 50)
    local game = fixture.context(ctx, player)

    harness.falsy(ally_target.plan(game, convoker,
        spells.SPELL_HASTE_OTHER, benefits),
        "stationary no-threat firewood cannot receive allied magic")

    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 60, 60)
    fixture.actor(ctx, monsters.MONS_RAT, 61, 60)
    fixture.actor(ctx, monsters.MONS_ORC_WARRIOR, 62, 60)

    harness.falsy(ally_target.plan(game, caster,
        spells.SPELL_HASTE_OTHER, benefits),
        "a wrong-genus actor intercepts the eligible ally's beam")
end

-- Charm does not erase an authored friendly monster's underlying allegiance.
-- The source checks that real attitude before allowing an allied buff.
local function friendly_charmed(ctx, player)
    local caster = fixture.actor(ctx,
        monsters.MONS_IRONBOUND_CONVOKER, 70, 70)
    local ally = fixture.actor(ctx, monsters.MONS_RAT, 71, 70)
    local game = fixture.context(ctx, player)

    ctx:add(caster, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(ally, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(ally, component.MONSTER_ALLEGIANCE, {
        charm_aut = 30,
    })

    harness.equal(ally_target.plan(game, caster,
        spells.SPELL_HASTE_OTHER, benefits).entity, ally,
        "a charmed monster that was already friendly remains an ally")
end

-- Source test monsters are explicitly exempt from the firewood exclusion,
-- including the stationary, no-threat test statue.
local function test_monster_exemption(ctx, player)
    local caster = fixture.actor(ctx,
        monsters.MONS_IRONBOUND_CONVOKER, 80, 80)
    local statue = fixture.actor(ctx, monsters.MONS_TEST_STATUE, 81, 80)
    local game = fixture.context(ctx, player)

    harness.equal(ally_target.plan(game, caster,
        spells.SPELL_HASTE_OTHER, benefits).entity, statue,
        "test statue remains a legal allied buff recipient")
end

-- Nearest eligible target wins; equal distances retain ECS entity order.
function test.run(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 3, 3)
    local first = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR, 4, 3)
    local second = fixture.actor(ctx, monsters.MONS_ORC_WIZARD, 2, 3)
    fixture.actor(ctx, monsters.MONS_RAT, 3, 4)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 3, 5)
    local game = fixture.context(ctx, player)
    local plan = ally_target.plan(game, caster,
        spells.SPELL_HASTE_OTHER, benefits)

    harness.equal(plan.entity, first,
        "equal-distance allies keep the first stable entity")
    ctx:add(first, component.MONSTER_ALLEGIANCE, {
        charm_aut = 30,
    })

    plan = ally_target.plan(game, caster,
        spells.SPELL_HASTE_OTHER, benefits)

    harness.equal(plan.entity, second,
        "temporarily charmed target is not a genuine ally")

    game.walls["2:3"] = true

    harness.falsy(ally_target.plan(game, caster,
        spells.SPELL_HASTE_OTHER, benefits),
        "wall blocks the remaining allied beam")

    game.walls["2:3"] = nil
    local selected = ally_target.plan(game, caster,
        spells.SPELL_HASTE_OTHER, benefits)
    local moved = ctx:get(second, component.POSITION)

    moved.y = 2
    ctx:set(second, component.POSITION, moved)

    harness.falsy(ally_target.selected(game, caster, selected),
        "a moved target no longer occupies the planned beam endpoint")

    moved.y = 3
    ctx:set(second, component.POSITION, moved)

    ctx:destroy(second)

    harness.falsy(ally_target.selected(game, caster, selected),
        "destroyed selected actor is not silently replaced")

    special_groups(ctx, player)
    blockers(ctx, player)
    friendly_charmed(ctx, player)
    test_monster_exemption(ctx, player)
end

return test
