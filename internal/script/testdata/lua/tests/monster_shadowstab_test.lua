-- Shadowstab spans the pre-hit, pre-armour, and post-contact phases of
-- source melee. These tests use the production catalog and ECS schemas.
local actions = require("policy.combat.melee_actions")
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local flavours = require("constants.attack_flavours")
local harness = require("tests.harness")
local hex_status = require("policy.combat.monster_hexes.status")
local jobs = require("ids.jobs")
local melee = require("policy.combat.melee")
local monsters = require("ids.monsters")
local shadowstab = require("policy.combat.monster_shadowstab")
local species = require("ids.species")
local invisibility = require("policy.combat.monster_support.invisibility")

local test = {}

-- A nonzero unseen bonus must happen before AC. A sleeper receives the
-- same bonus from an ordinary attack, while a seen waking target does not.
local function damage_phases(ctx, game, shadow, player, orc)
    local attack = {
        attacker = shadow,
        defender = player,
        hd = 6,
        damage = 14,
        type_id = "AT_HIT",
        flavour_id = flavours.SHADOWSTAB,
    }
    local defense = {
        ac = 10,
        gdr = 0,
    }

    function game:random(_, bound)
        return bound - 1
    end

    local seen = melee.monster_damage(game, attack, defense)

    attack.flavour_id = flavours.PLAIN

    ctx:add(player, component.PLAYER_SLEEP, {
        remaining_aut = 50,
        immunity_aut = 0,
    })

    local sleeping_player = melee.monster_damage(game, attack, defense)

    harness.truthy(sleeping_player > seen * 2,
        "ordinary melee gains the sleeping-player stab bonus")

    ctx:remove(player, component.PLAYER_SLEEP)
    attack.flavour_id = flavours.SHADOWSTAB

    invisibility.grant(game, shadow, 50)

    local unseen = melee.monster_damage(game, attack, defense)

    harness.truthy(unseen > seen * 2,
        "unseen stab multiplies raw damage before armour")

    attack.flavour_id = flavours.PLAIN
    attack.defender = orc

    ctx:add(orc, component.AI, {
        behavior = "sleep",
    })

    local sleeper = melee.monster_damage(game, attack, defense)

    harness.truthy(sleeper > seen * 2,
        "ordinary monster melee receives the source sleeping bonus")

    shadowstab.after_hit(game, {
        kind = "hit",
        attacker = shadow,
    })
end

-- Auto-hit ignores EV but the shield gate still runs first. The same
-- visibility owner handles both player and monster defenders.
local function contact_phases(ctx, game, shadow, player, orc)
    local attack = {
        attacker = shadow,
        defender = player,
        hd = 6,
        damage = 14,
        type_id = "AT_HIT",
        flavour_id = flavours.SHADOWSTAB,
    }
    local defense = {
        ev = 30,
        ac = 0,
        gdr = 0,
        shield_class = 0,
        shield_blocks = 0,
    }

    function game:random(_, bound)
        if bound == 100 then
            return 50
        end

        if bound == 60 or bound == 61 then
            return bound - 1
        end

        if bound >= 2000 then
            return bound - 1
        end

        return 0
    end

    harness.equal(melee.monster_contact(game, attack, defense).kind,
        "dodge", "visible Shadow still faces ordinary evasion")

    invisibility.grant(game, shadow, 50)

    harness.equal(melee.monster_contact(game, attack, defense).kind,
        "hit", "unseen Shadow bypasses evasion")

    hex_status.corona(game, shadow, 50)

    harness.equal(melee.monster_contact(game, attack, defense).kind,
        "dodge", "backlit Shadow remains visible despite invisibility")

    ctx:remove(shadow, component.HEX_STATUS)

    function game:random(_, bound)
        if bound == 100 then
            return 0
        end

        return 0
    end

    harness.equal(melee.monster_contact(game, attack, defense).kind,
        "hit", "automatic Shadowstab cannot draw an automatic miss")

    function game:random(_, bound)
        if bound == 100 then
            return 50
        end

        if bound == 60 or bound == 61 or bound >= 2000 then
            return bound - 1
        end

        return 0
    end

    attack.defender = orc

    harness.equal(melee.monster_contact(game, attack, defense).kind,
        "hit", "monster target cannot evade an unseen Shadow")

    local seeing = fixture.actor(ctx, monsters.MONS_SHADOW_WRAITH,
        10, 9, 100)

    attack.defender = seeing

    harness.equal(melee.monster_contact(game, attack, defense).kind,
        "dodge", "see-invisible monster retains ordinary evasion")

    attack.defender = orc

    defense.shield_class = 1000

    harness.equal(melee.monster_contact(game, attack, defense).kind,
        "block", "shield still blocks an unseen Shadow")
end

-- The flavour removes only temporary invisibility after a hit. Other
-- enchantments survive, and a miss must leave the timer untouched.
local function after_contact(ctx, game, shadow, player)
    local state = ctx:get(shadow, component.MONSTER_ENCHANT)

    state.blind_aut = 20
    ctx:set(shadow, component.MONSTER_ENCHANT, state)

    shadowstab.after_hit(game, {
        kind = "miss",
        attacker = shadow,
        defender = player,
    })

    harness.truthy(invisibility.active(game, shadow),
        "a missed stab preserves invisibility")

    shadowstab.after_hit(game, {
        kind = "hit",
        attacker = shadow,
        defender = player,
        physical_damage = 0,
        damage_done = 0,
    })

    state = ctx:get(shadow, component.MONSTER_ENCHANT)

    harness.equal(state.invisible_aut, 0,
        "armour-absorbed hit still ends temporary invisibility")
    harness.equal(state.blind_aut, 20,
        "Shadowstab preserves unrelated enchantment fields")
end

-- A live contact must pass through the same pre-hit and post-hit owners;
-- neither an isolated multiplier nor a direct flavour call suffices.
local function live_monster_contact(ctx, game)
    local shadow = fixture.actor(ctx, monsters.MONS_SHADOW,
        40, 40, 1000)
    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        41, 40, 1000)

    ctx:add(orc, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    invisibility.grant(game, shadow, 50)

    function game:random(_, bound)
        return bound - 1
    end

    local before = ctx:get(orc, component.HEALTH).current
    local messages = {}

    function game:emit(channel, message)
        messages[#messages + 1] = message
        self.base:emit(channel, message)
    end

    actions.monster_target(game, shadow, orc)

    harness.truthy(ctx:get(orc, component.HEALTH).current < before,
        "live unseen Shadow strikes monster target")
    harness.falsy(invisibility.active(game, shadow),
        "live monster contact ends Shadow's invisibility")

    local darkness = 0

    for _, message in ipairs(messages) do
        if message:find("from the darkness", 1, true) then
            darkness = darkness + 1
        end

        harness.falsy(message:find(" misses the ", 1, true),
            "unseen contact does not emit an ordinary miss")
    end

    harness.equal(darkness, 1,
        "live unseen hit announces darkness once")
end

-- Player defense uses a separate full-action entry, so verify it also
-- clears the enchant and resolves through the same Shadowstab rule.
local function live_player_contact(ctx, game)
    local shadow = fixture.actor(ctx, monsters.MONS_SHADOW,
        50, 40, 1000)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        51, 40, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 27,
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.COMBAT, {
        shield_blocks = 0,
    })

    game.player_entity = player
    invisibility.grant(game, shadow, 50)

    function game:random(_, bound)
        return bound - 1
    end

    actions.monster(game, shadow)

    harness.truthy(ctx:get(player, component.HEALTH).current < 1000,
        "live unseen Shadow wounds player")
    harness.falsy(invisibility.active(game, shadow),
        "live player contact ends Shadow's invisibility")
end

-- A single test world exercises each attack phase against saved entities.
function test.run(ctx)
    local shadow = fixture.actor(ctx, monsters.MONS_SHADOW,
        10, 10, 1000)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        11, 10, 1000)
    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        10, 11, 1000)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })

    local game = fixture.context(ctx, player)

    damage_phases(ctx, game, shadow, player, orc)
    contact_phases(ctx, game, shadow, player, orc)
    after_contact(ctx, game, shadow, player)
    live_monster_contact(ctx, game)
    live_player_contact(ctx, game)
end

return test
