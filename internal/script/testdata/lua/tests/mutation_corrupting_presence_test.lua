
local component = require("constants.component")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local species = require("ids.species")
local damage = require("policy.magic.damage")
local monster_health = require("policy.combat.monster_health")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Seed corrupting presence attacker and target independently before the reaction mutates either.
local function fixture(ctx, monster_id)
    local player = ctx:create()
    local monster = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Corrupting presence test",
    })
    ctx:add(monster, component.ACTOR, {
        kind_id = monster_id or monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(monster, component.HEALTH, {
        current = 30,
        max = 30,
    })

    return player, monster
end

-- Script corrosion and mutation draws at the incoming-damage boundary.
local function damage_context(ctx, player, chance, corrosion_roll)
    local battle = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to corrupting presence fixture actor so player-only branches execute on that entity.
    function battle.player()
        return player
    end

    -- Control the mutation proc separately from the melee corrosion roll.
    function battle.random(_, stream, bound)
        if stream == "mutation" and bound == 12 then
            return chance
        end

        if stream == "melee" and bound == 2 and corrosion_roll then
            return corrosion_roll
        end

        return ctx:random(stream, bound)
    end

    return battle
end

-- First level corrodes a surviving monster after player damage.
function test.run(ctx)
    local player, monster = fixture(ctx)
    local battle = damage_context(ctx, player, 0)

    damage.apply(battle, monster, 1)
    harness.falsy(ctx:has(monster, component.MONSTER_ENCHANT),
        "unmutated player does not corrode a target")

    records.grant_acquired(ctx, player,
        mutations.MUT_CORRUPTING_PRESENCE, 1)
    damage.apply(battle, monster, 1)

    local corrosion = ctx:get(monster, component.MONSTER_ENCHANT)

    -- Corrosion is a post-damage reaction and requires a living hostile target.
    harness.truthy(corrosion and corrosion.corrosion_aut > 0,
        "first level corrodes a surviving monster after player damage")
    harness.falsy(ctx:has(monster, component.WRETCHED),
        "first level does not malmutate")

    records.grant_acquired(ctx, player,
        mutations.MUT_CORRUPTING_PRESENCE, 1)
    damage.apply(battle, monster, 1)

    -- The second mutation level adds a separate malmutation outcome.
    harness.truthy(ctx:has(monster, component.WRETCHED),
        "second level can malmutate a surviving monster")

    local skipped_player, skipped_monster = fixture(ctx)

    records.grant_acquired(ctx, skipped_player,
        mutations.MUT_CORRUPTING_PRESENCE, 2)
    damage.apply(damage_context(ctx, skipped_player, 11),
        skipped_monster, 1)

    harness.falsy(ctx:has(skipped_monster, component.MONSTER_ENCHANT),
        "failed one-in-twelve roll does not corrode")
    harness.falsy(ctx:has(skipped_monster, component.WRETCHED),
        "failed one-in-twelve roll does not malmutate")

    local _, summoned_target = fixture(ctx)

    monster_health.damage(battle, summoned_target, 1, monster)
    harness.falsy(ctx:has(summoned_target, component.MONSTER_ENCHANT),
        "an allied monster hit does not borrow the player's mutation")

    local _, lethal_target = fixture(ctx)

    damage.apply(battle, lethal_target, 30, player)
    -- A lethal hit must skip both survivor-only effects even when the chance draw succeeds.
    harness.falsy(ctx:has(lethal_target, component.MONSTER_ENCHANT),
        "a killing hit cannot corrode the dead target")

    local protected_player, protected_target = fixture(ctx,
        monsters.MONS_ACID_DRAGON)

    records.grant_acquired(ctx, protected_player,
        mutations.MUT_CORRUPTING_PRESENCE, 1)
    damage.apply(damage_context(ctx, protected_player, 0, 0),
        protected_target, 1, protected_player)

    harness.falsy(ctx:has(protected_target, component.MONSTER_ENCHANT),
        "acid resistance can protect against corrosion")
end

return test
