local auxiliary = require("policy.combat.auxiliary")
local attacks = require("constants.auxiliary_attacks")
local mutations = require("ids.mutations")
local species = require("ids.species")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local catalog = require("policy.catalog")
local component = require("constants.component")
local size = require("constants.size")
local records = require("policy.mutations.records")
local harness = require("tests.harness")
local lowered_will = require("policy.magic.effects.statuses.lowered_will")
local confusing_touch = require("policy.magic.effects.statuses.confusing_touch")
local player_constriction = require("policy.combat.player_constriction")
local will = require("policy.magic.effects.zaps.will")

local test = {}

local function attack_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    function proxy.player()
        return player
    end

    function proxy.random(_, stream, _)
        harness.equal(stream, "melee", "auxiliary attacks use melee RNG")

        return 0
    end

    return proxy
end

local function input()
    return {
        level = 27,
        horns = 0,
        hooves = 0,
        talons = 0,
        tentacle_spike = 0,
        strength = 10,
        dexterity = 10,
        fighting100 = 0,
        fighting30 = 0,
        defender_ev = 0,
        defender_ac = 0,
        mighty = false,
        offhand = true,
        punch_eligible = true,
        unarmed5 = 0,
        unarmed1 = 0,
        claws = 0,
        tentacles = 0,
        form_id = "",
        can_see = true,
        adjacent = true,
        player_size = 4,
        target_size = 3,
        target_immune_to_constriction = false,
        existing_grips = 0,
        free_tentacles = 0,
        confused = false,
    }
end

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, "core.player", {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Auxiliary test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 27,
    })
    local battle = attack_context(ctx, player)
    local ordered = auxiliary.all()

    harness.equal(ordered[1].id, attacks.CONSTRICT.id,
        "source order starts with constriction")
    harness.equal(ordered[2].id, attacks.KICK.id,
        "source order keeps kick after constriction")
    harness.equal(ordered[3].id, attacks.HEADBUTT.id,
        "source order keeps headbutt after kick")
    harness.equal(ordered[4].id, attacks.PECK.id,
        "source order keeps peck after headbutt")
    harness.equal(ordered[5].id, attacks.TAILSLAP.id,
        "source order keeps tail slap after peck")
    harness.equal(ordered[6].id, attacks.TOUCH.id,
        "source order puts touch before punch")
    harness.equal(ordered[7].id, attacks.PUNCH.id,
        "source order puts punch before bite")
    harness.equal(ordered[8].id, attacks.BITE.id,
        "source order keeps bite after punch")
    harness.equal(ordered[9].id, attacks.PSEUDOPODS.id,
        "source order keeps pseudopods after bite")
    harness.equal(ordered[10].id, attacks.TENTACLES.id,
        "source order keeps tentacles last")

    harness.falsy(auxiliary.resolve_one(battle, input(),
        auxiliary.get(attacks.PECK.id)).attempted,
        "a player without a beak does not peck")

    records.grant_acquired(ctx, player, mutations.MUT_BEAK, 1)

    local peck = auxiliary.resolve_one(battle, input(),
        auxiliary.get(attacks.PECK.id))

    harness.truthy(peck.attempted and peck.hit,
        "Beak adds a source-ordered peck attack")
    harness.equal(peck.name, "peck", "the message names the beak attack")
    harness.equal(peck.verb, "peck", "the peck has its own action verb")

    records.grant_acquired(ctx, player, mutations.MUT_ARMOURED_TAIL, 1)

    local tail = auxiliary.resolve_one(battle, input(),
        auxiliary.get(attacks.TAILSLAP.id))

    harness.truthy(tail.attempted and tail.hit,
        "Armoured Tail adds a source-ordered tail slap")
    harness.equal(tail.name, "tail-slap", "tail attack has a named message")

    local rat = ctx:create()
    local rat_definition = catalog.get("monsters", monsters.MONS_RAT)

    ctx:add(rat, "core.actor", {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(rat, "core.health", {
        current = 5,
        max = 5,
    })

    records.grant_acquired(ctx, player,
        mutations.MUT_CONSTRICTING_TAIL, 2)

    local grip_input = input()

    grip_input.target = rat

    local grab = auxiliary.resolve_one(battle, grip_input,
        auxiliary.get(attacks.CONSTRICT.id))

    harness.truthy(grab.attempted and grab.hit,
        "Constricting Tail adds a source-first grab")
    harness.equal(grab.damage, 0, "the grab deals no contact damage")
    auxiliary.get(attacks.CONSTRICT.id).on_hit(battle, rat,
        rat_definition, grab)
    harness.equal(ctx:get(rat, component.PLAYER_CONSTRICTION).by, player,
        "the monster owns its direct player grip")

    local second_rat = ctx:create()
    local second_grip = input()

    second_grip.target = second_rat
    second_grip.existing_grips = 1

    harness.falsy(auxiliary.resolve_one(battle, second_grip,
        auxiliary.get(attacks.CONSTRICT.id)).attempted,
        "a tail cannot hold two monsters")

    records.grant_acquired(ctx, player, mutations.MUT_TENTACLE_ARMS, 1)
    second_grip.free_tentacles = 1

    harness.truthy(auxiliary.resolve_one(battle, second_grip,
        auxiliary.get(attacks.CONSTRICT.id)).attempted,
        "a free tentacle can add another grip")

    second_grip.target_immune_to_constriction = true

    harness.falsy(auxiliary.resolve_one(battle, second_grip,
        auxiliary.get(attacks.CONSTRICT.id)).attempted,
        "an insubstantial or spiny monster cannot be grabbed")

    local stubborn = setmetatable({}, { __index = battle })

    function stubborn.random(_, stream, bound)
        harness.equal(stream, "melee", "escape uses melee RNG")

        return bound - 1
    end

    harness.falsy(player_constriction.escape(stubborn, rat),
        "a monster can fail to break the player's grip")
    harness.equal(ctx:get(rat, component.PLAYER_CONSTRICTION).escape_attempts,
        1, "the failed escape attempt is saved on the monster")
    harness.truthy(player_constriction.escape(battle, rat),
        "the next source escape roll can free the monster")
    harness.falsy(ctx:has(rat, component.PLAYER_CONSTRICTION),
        "successful escape removes the grip")

    records.grant_acquired(ctx, player, mutations.MUT_STINGER, 1)
    auxiliary.get(attacks.TAILSLAP.id).on_hit(battle, rat, rat_definition, {
        damage = 1,
    })

    harness.truthy(ctx:has(rat, "projectile.poison"),
        "Stinger's damaging tail slap can poison a living monster")

    records.grant_acquired(ctx, player,
        mutations.MUT_WEAKNESS_STINGER, 3)
    auxiliary.get(attacks.TAILSLAP.id).on_hit(battle, rat, rat_definition, {
        damage = 1,
    })

    harness.truthy(ctx:get(rat, "magic.monster_enfeeble").weak_aut >= 60,
        "third-level weakness stinger weakens a living monster")

    records.grant_acquired(ctx, player, mutations.MUT_FANGS, 1)

    local bite = auxiliary.resolve_one(battle, input(),
        auxiliary.get(attacks.BITE.id))

    harness.truthy(bite.attempted and bite.hit,
        "Fangs adds a source-ordered bite")
    harness.equal(bite.name, "bite", "bite has a named message")

    records.grant_acquired(ctx, player, mutations.MUT_ACIDIC_BITE, 1)

    harness.equal(auxiliary.get(attacks.BITE.id).on_hit(battle, rat,
        rat_definition, { damage = 2 }), 2,
        "Acidic Bite splashes a rat for the source minimum 2d4")

    ctx:add(player, "core.magic", {
        current = 0,
        max = 10,
    })
    records.grant_acquired(ctx, player,
        mutations.MUT_ANTIMAGIC_BITE, 1)

    auxiliary.get(attacks.BITE.id).on_hit(battle, rat, rat_definition, {
        damage = 2,
    })

    harness.equal(ctx:get(player, "core.magic").current, 1,
        "Antimagic Bite restores magic from a damaging hit")

    records.grant_acquired(ctx, player, mutations.MUT_PSEUDOPODS, 1)

    local bludgeon = auxiliary.resolve_one(battle, input(),
        auxiliary.get(attacks.PSEUDOPODS.id))

    harness.truthy(bludgeon.attempted and bludgeon.hit,
        "Pseudopods adds the bludgeon attack")
    harness.equal(bludgeon.verb, "bludgeon",
        "pseudopod attack uses the source verb")

    local squeeze = auxiliary.resolve_one(battle, input(),
        auxiliary.get(attacks.TENTACLES.id))

    harness.truthy(squeeze.attempted and squeeze.hit,
        "Tentacle Arms adds the squeeze attack")
    harness.equal(squeeze.verb, "squeeze",
        "tentacle attack uses the source verb")

    local punch = auxiliary.resolve_one(battle, input(),
        auxiliary.get(attacks.PUNCH.id))

    harness.truthy(punch.attempted and punch.hit,
        "a free offhand can make the source bonus punch")

    local guarded = setmetatable({}, { __index = battle })

    function guarded.random(_, stream, bound)
        harness.equal(stream, "melee", "shield uses melee RNG")

        return bound > 100 and bound - 1 or 0
    end

    local shield_input = input()

    shield_input.defender_shield = {
        ac = 10,
        plus = 20,
        subtype = 14,
        size = size.MEDIUM,
        hit_dice = 10,
        blocks = 0,
        name = "buckler",
    }

    local blocked = auxiliary.resolve_one(guarded, shield_input,
        auxiliary.get(attacks.PUNCH.id))

    harness.truthy(blocked.attempted and blocked.blocked and not blocked.hit,
        "a monster shield can stop an auxiliary punch after contact")

    records.grant_acquired(ctx, player, mutations.MUT_DEMONIC_TOUCH, 1)

    local touch = auxiliary.resolve_one(battle, input(),
        auxiliary.get(attacks.TOUCH.id))

    harness.truthy(touch.attempted and touch.hit,
        "Demonic Touch adds a non-XL-scaled touch attack")
    harness.equal(touch.name, "touch", "touch has its own combat message")

    records.grant_acquired(ctx, player, mutations.MUT_DEMONIC_TOUCH, 2)
    auxiliary.get(attacks.TOUCH.id).on_hit(battle, rat,
        rat_definition, { damage = 1 })

    harness.equal(ctx:get(rat, component.MONSTER_LOWERED_WILL).remaining_aut,
        40, "third-level Demonic Touch lowers will for four turns")

    local spell = setmetatable({}, { __index = ctx })

    function spell.random(_, stream, _)
        harness.equal(stream, "spell", "will check uses spell RNG")

        return 50
    end

    local resistant = {
        name = rat_definition.name,
        willpower = 100,
    }

    harness.truthy(will.resists(spell, resistant, 100),
        "a monster resists before Demonic Touch")
    harness.falsy(will.resists(spell, resistant, 100, rat),
        "Demonic Touch halves the target's willpower")
    harness.truthy(confusing_touch.apply(spell, rat, resistant, 100),
        "Confusing Touch reads the lowered will of its target")
    harness.truthy(will.resists(spell, {
        willpower = -5,
        hd = 15,
    }, 100), "negative catalog willpower scales with hit dice")
    harness.truthy(will.resists(spell, {
        willpower = 5000,
    }, 100, rat), "invulnerable will ignores the status")

    lowered_will.tick(ctx, rat)

    harness.equal(ctx:get(rat, component.MONSTER_LOWERED_WILL).remaining_aut,
        30, "lowered will loses one turn per monster action")
end

return test
