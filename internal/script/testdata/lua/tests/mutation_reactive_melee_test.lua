
local component = require("constants.component")
local jobs = require("ids.jobs")
local items = require("ids.items")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local species = require("ids.species")
local terrain = require("constants.terrain")
local catalog = require("policy.catalog")
local melee_actions = require("policy.combat.melee_actions")
local reactions = require("policy.combat.player_reactions")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Seed reactive melee attacker and target independently before the reaction mutates either.
local function fixture(ctx)
    local player = ctx:create()
    local monster = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Reactive mutation test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 27,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(monster, component.HEALTH, {
        current = 30,
        max = 30,
    })
    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })

    return player, monster, catalog.get("monsters", monsters.MONS_RAT)
end

-- Separate passive freeze rolls from damage and message assertions.
local function battle_context(ctx, player, freeze_roll)
    local battle = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to reactive melee fixture actor so player-only branches execute on that entity.
    function battle.player()
        return player
    end

    -- Hold spell and skill checks high while steering the separate freeze proc.
    function battle.random(_, stream, bound)
        if stream == "spell" then
            return bound - 1
        end

        if stream == "skill" then
            return bound - 1
        end

        if stream == "clouds" then
            return 0
        end

        harness.equal(stream, "melee", "reaction uses the melee RNG")

        if freeze_roll and bound == 11 then
            return 10
        end

        if bound == 35 then
            return 34
        end

        return 0
    end

    -- Define reactive melee fixture's traversable cells for movement and targeting checks.
    function battle.walkable()
        return true
    end

    -- Return reactive melee fixture terrain that gates the environmental branch.
    function battle.cell()
        return terrain.DNGN_FLOOR
    end

    -- Make reactive melee sight deterministic while leaving actor positions to the ECS fixture.
    function battle.visible()
        return true
    end

    -- Freeze reactive melee world time; the explicit aut argument drives every timer change.
    function battle.aut()
        return 0
    end

    return battle
end

-- Passive freeze deals cold damage after a hit.
function test.run(ctx)
    local player, monster, definition = fixture(ctx)
    local battle = battle_context(ctx, player, false)

    reactions.before_contact(battle, monster, definition)
    harness.equal(ctx:get(monster, component.HEALTH).current, 30,
        "unmutated player has no spine retaliation")

    records.grant_acquired(ctx, player, mutations.MUT_SPINY, 3)
    reactions.before_contact(battle, monster, definition)

    -- Pre-contact retaliation can kill or damage an attacker before its ordinary hit resolves.
    harness.equal(ctx:get(monster, component.HEALTH).current, 27,
        "spines strike before the monster lands its hit")

    records.grant_acquired(ctx, player, mutations.MUT_PASSIVE_FREEZE, 1)
    local freezing = battle_context(ctx, player, true)

    reactions.after_hit(freezing, monster, definition, 1)

    -- Post-contact freeze must wait until the attack has actually connected.
    harness.equal(ctx:get(monster, component.HEALTH).current, 17,
        "passive freeze deals cold damage after a hit")

    records.grant_acquired(ctx, player, mutations.MUT_FOUL_STENCH, 3)
    reactions.after_hit(battle, monster, definition, 1)

    harness.equal(#ctx:query({ component.WORLD_CLOUD }), 1,
        "a damaging hit can emit a miasma cloud")

    records.grant_acquired(ctx, player, mutations.MUT_EYEBALLS, 3)
    reactions.after_attack(battle, monster, definition)

    harness.truthy(ctx:has(monster, component.MONSTER_CONFUSION),
        "eyeballs can confuse an adjacent attacker after its attack")

    local weapon = ctx:create()

    ctx:add(weapon, component.ITEM, {
        kind_id = items.WPN_DAGGER,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(weapon, component.CARRIED_BY, {
        holder = monster,
    })
    ctx:add(weapon, component.EQUIPPED, {
        slot = "weapon",
    })
    records.grant_acquired(ctx, player, mutations.MUT_TENDRILS, 1)
    reactions.after_attack(battle, monster, definition)

    harness.falsy(ctx:has(weapon, component.CARRIED_BY),
        "tendrils pull the monster's weapon from its inventory")
    -- Tendrils move the weapon out of monster inventory instead of destroying it.
    harness.truthy(ctx:has(weapon, component.POSITION),
        "disarmed weapon becomes a floor item")

    local live_player, live_monster = fixture(ctx)

    ctx:add(live_player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(live_player, component.SKILLS, {
        entries = {},
    })
    ctx:add(live_player, component.COMBAT, {
        shield_blocks = 0,
    })
    ctx:add(live_player, component.HEALTH, {
        current = 30,
        max = 30,
    })
    records.grant_acquired(ctx, live_player, mutations.MUT_SPINY, 3)

    local live_battle = battle_context(ctx, live_player, false)

    melee_actions.monster(live_battle, live_monster)

    harness.equal(ctx:get(live_monster, component.HEALTH).current, 27,
        "the live melee action invokes spines before an attack misses")

    harness.truthy(reactions.has_mutation(
        mutations.MUT_REFLEXIVE_HEADBUTT),
        "reflexive headbutt has a registered miss reaction")

    records.grant_acquired(ctx, live_player,
        mutations.MUT_REFLEXIVE_HEADBUTT, 1)
    records.grant_acquired(ctx, live_player, mutations.MUT_HORNS, 1)
    local before_retaliation = ctx:get(live_monster,
        component.HEALTH).current
    local retaliation_battle = battle_context(ctx, live_player, false)

    -- Force the reflexive headbutt proc, then bound its remaining melee draws.
    function retaliation_battle.random(_, stream, bound)
        harness.equal(stream, "melee",
            "reflexive headbutt uses the melee RNG")

        if bound == 100 then
            return 0
        end

        return bound - 1
    end

    reactions.after_miss(retaliation_battle, live_monster,
        catalog.get("monsters", monsters.MONS_RAT))

    harness.truthy(ctx:get(live_monster, component.HEALTH).current <
        before_retaliation,
        "the registered reflexive reaction damages a missed attacker")
end

return test
