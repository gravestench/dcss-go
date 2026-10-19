-- A monster's Grasping Roots uses the same saved restraint owner as the
-- player's Fastroot. These cases exercise production schemas and spell IDs.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fastroot = require("policy.magic.effects.zaps.fastroot")
local fixture = require("tests.fixtures.monster_status")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local species = require("ids.species")
local spells = require("ids.spells")
local terrain = require("constants.terrain")

local test = {}

-- A Jorgrun cast fixes its selected target, saves the caster handle, and
-- lets the ordinary root owner expire the grip on later actor actions.
function test.run(ctx)
    local player = fixture.actor(ctx,
        monsters.MONS_HUMAN, 3, 1, 30)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local caster = fixture.actor(ctx,
        monsters.MONS_JORGRUN, 1, 1, 30)
    local live = fixture.context(ctx, player, 0)
    local effect = effects.effect(spells.SPELL_GRASPING_ROOTS)

    -- The isolated rule host has ECS but no floor grid.
    function live:cell()
        return terrain.DNGN_FLOOR
    end

    local plan = effect.plan(live, caster, player)

    harness.truthy(plan, "a reachable player can be rooted")

    effect.resolve(live, caster, player, nil, plan)

    local state = ctx:get(player, component.GRASPING_ROOTS)

    harness.truthy(state, "the player owns a saved root condition")
    harness.equal(state.source, caster,
        "the condition keeps the caster's ECS handle")
    harness.truthy(state.remaining_aut >= 40,
        "source monster roots last at least four turns")
    harness.falsy(effect.plan(live, caster, player),
        "an already-rooted foe is not a useful recast target")

    fastroot.tick_monster(live, player)

    harness.equal(ctx:get(player, component.GRASPING_ROOTS).remaining_aut,
        state.remaining_aut - 10,
        "player root duration ages in the shared owner")

    harness.truthy(fastroot.escape(live, player),
        "a rooted player can break the grip by moving")
    harness.falsy(ctx:has(player, component.GRASPING_ROOTS),
        "a successful escape clears the saved player condition")

    local friendly = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 2, 2, 10)
    local aligned = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 2, 3, 10)

    harness.falsy(effect.plan(live, caster, aligned),
        "ordinary hostile casters do not root aligned monsters")

    ctx:add(friendly, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 200,
    })

    local monster_plan = effect.plan(live, caster, friendly)

    harness.truthy(monster_plan,
        "hostile roots also target an enemy monster")
    effect.resolve(live, caster, friendly, nil, monster_plan)
    harness.equal(ctx:get(friendly, component.GRASPING_ROOTS).source,
        caster, "friendly victim keeps the hostile caster handle")

    fastroot.damage_owner_action(live, caster, 10)

    harness.truthy(ctx:get(friendly, component.HEALTH).current < 10,
        "a caster action deals real constriction damage")
    harness.equal(ctx:get(friendly,
        component.GRASPING_ROOTS).held_aut, 10,
        "the saved hold time grows after the source acts")

    local caster_health = ctx:get(caster, component.HEALTH)

    caster_health.current = 0
    ctx:set(caster, component.HEALTH, caster_health)
    fastroot.tick_monster(live, friendly)

    harness.falsy(ctx:has(friendly, component.GRASPING_ROOTS),
        "a dead root caster releases its victim")

end

return test
