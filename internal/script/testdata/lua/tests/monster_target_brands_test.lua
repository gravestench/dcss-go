-- These attacks use the real melee owners and item ECS records. Replaying
-- the same maximal rolls isolates brand effects from ordinary contact.
local actions = require("policy.combat.melee_actions")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local species = require("ids.species")
local jobs = require("ids.jobs")
local brands = require("constants.weapon_brands")
local holiness = require("constants.monster_holiness")
local summons = require("policy.combat.summon_melee")
local target_brands = require("policy.combat.monster_target_brands")
local monster_stats = require("policy.combat.monster_stats")
local monster_flags = require("constants.monster_flags")

local test = {}

-- Equip one real item so ordinary monster melee takes the same equipment
-- path as generated vault monsters and their saved copies.
local function equip(ctx, holder, brand_id)
    local weapon = ctx:create()

    ctx:add(weapon, component.ITEM, {
        kind_id = items.WPN_DAGGER,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = brand_id,
    })
    ctx:add(weapon, component.CARRIED_BY, { holder = holder })
    ctx:add(weapon, component.EQUIPPED, { slot = "weapon" })

    return weapon
end

-- Restore HP and shield contest state between identical seeded contacts.
-- A greater second loss can then come only from the brand resolution.
local function reset(ctx, target)
    ctx:set(target, component.HEALTH, {
        current = 100,
        max = 100,
    })
end

-- An ordinary monster must burn another monster after its physical hit.
local function ordinary(ctx, game)
    local attacker = fixture.actor(ctx, monsters.MONS_ORC, 20, 20)
    local target = fixture.actor(ctx, monsters.MONS_RAT, 21, 20, 100)
    local weapon = equip(ctx, attacker, "")

    ctx:add(target, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    actions.monster_target(game, attacker, target)

    local base = 100 - ctx:get(target, component.HEALTH).current
    local item = ctx:get(weapon, component.ITEM)

    reset(ctx, target)
    item.ego = brands.FLAMING
    ctx:set(weapon, component.ITEM, item)
    actions.monster_target(game, attacker, target)

    local burned = 100 - ctx:get(target, component.HEALTH).current

    harness.truthy(burned > base,
        "ordinary monster melee applies its weapon brand to monsters")
end

-- Petrification halves the physical strike before a fire brand scales its
-- bonus. A branded bite must also ignore an unrelated held weapon.
local function physical_contact(ctx, game)
    local attacker = fixture.actor(ctx, monsters.MONS_ORC, 24, 20)
    local target = fixture.actor(ctx, monsters.MONS_RAT, 25, 20, 100)
    local weapon = equip(ctx, attacker, "")

    ctx:add(target, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(target, component.MONSTER_STASIS, {
        hibernating = false,
        sleep_wary_aut = 0,
        petrifying_aut = 0,
        petrified_aut = 100,
    })

    actions.monster_target(game, attacker, target)

    local physical = 100 - ctx:get(target, component.HEALTH).current
    local item = ctx:get(weapon, component.ITEM)

    harness.truthy(physical > 0,
        "petrified defender still receives a physical strike")
    reset(ctx, target)
    item.ego = brands.FLAMING
    ctx:set(weapon, component.ITEM, item)
    actions.monster_target(game, attacker, target)

    local total = 100 - ctx:get(target, component.HEALTH).current
    local fire = 1 + math.floor((physical - 1) / 2)

    harness.equal(total, physical + math.floor(fire / 2),
        "fire brand scales from actual petrified HP loss")

    local adder = fixture.actor(ctx, monsters.MONS_ADDER, 27, 20)
    local bite_target = fixture.actor(ctx, monsters.MONS_RAT,
        28, 20, 100)
    local bite_weapon = equip(ctx, adder, "")

    ctx:add(bite_target, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    actions.monster_target(game, adder, bite_target)

    local bite = 100 - ctx:get(bite_target, component.HEALTH).current
    local held = ctx:get(bite_weapon, component.ITEM)

    reset(ctx, bite_target)
    held.ego = brands.FLAMING
    ctx:set(bite_weapon, component.ITEM, held)
    actions.monster_target(game, adder, bite_target)
    harness.equal(100 - ctx:get(bite_target, component.HEALTH).current,
        bite, "natural bite cannot transmit a held weapon brand")
end

-- A player illusion has no carried weapon, so its saved brand must enter
-- the same effect path from the captured ghost component.
local function illusion(ctx, game)
    local attacker = fixture.actor(ctx,
        monsters.MONS_PLAYER_ILLUSION, 40, 20)
    local target = fixture.actor(ctx, monsters.MONS_RAT, 41, 20, 100)

    ctx:add(target, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(attacker, component.SUMMON, {
        owner = fixture.actor(ctx, monsters.MONS_MARA, 38, 20),
        source_id = "SPELL_SUMMON_ILLUSION",
        attitude = attitudes.HOSTILE,
        expires_aut = 100,
    })
    ctx:add(attacker, component.SUMMON_STATS, { hd = 10 })
    ctx:add(attacker, component.PLAYER_ILLUSION, {
        name = "Ghost",
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        damage = 12,
        brand_id = brands.NORMAL,
        holiness_id = holiness.NATURAL,
    })

    harness.truthy(summons.attack(game, attacker, target),
        "illusion uses special summoned melee")

    local base = 100 - ctx:get(target, component.HEALTH).current
    local profile = ctx:get(attacker, component.PLAYER_ILLUSION)

    reset(ctx, target)
    profile.brand_id = brands.FLAMING
    ctx:set(attacker, component.PLAYER_ILLUSION, profile)
    summons.attack(game, attacker, target)

    local burned = 100 - ctx:get(target, component.HEALTH).current

    harness.truthy(burned > base,
        "summoned player illusion applies its saved brand to monsters")
end

-- A direct brand envelope uses the same production dispatcher as both
-- melee owners. Its target has real ECS health and status components.
local function hit(ctx, attacker, defender, amount, credit)
    local actor = ctx:get(defender, component.ACTOR)

    return {
        attacker = attacker,
        attacker_name = "orc",
        defender = defender,
        definition = catalog.get("monsters", actor.kind_id),
        damage_done = amount,
        health = ctx:get(defender, component.HEALTH),
        player_credit = credit,
    }
end

-- Hostile brands cannot award experience, while player-side damage keeps
-- the one-live-to-dead kill signal used by ordinary melee.
local function kill_credit(ctx, game)
    local attacker = fixture.actor(ctx, monsters.MONS_ORC, 55, 20)
    local target = fixture.actor(ctx, monsters.MONS_RAT, 56, 20, 1)
    local signals = 0

    function game:signal(name)
        if name == "player_kill" then
            signals = signals + 1
        end
    end

    local hostile = hit(ctx, attacker, target, 10, false)

    target_brands.apply(game, brands.FLAMING, hostile)
    harness.equal(signals, 0,
        "hostile brand damage does not award player kill credit")

    ctx:set(target, component.HEALTH, {
        current = 1,
        max = 1,
    })

    local allied = hit(ctx, attacker, target, 10, true)

    target_brands.apply(game, brands.FLAMING, allied)
    harness.equal(signals, 1,
        "credited brand kill signals the player's side exactly once")
end

-- Effects with their own status or resistance owner are exercised through
-- the shared dispatcher so monster attackers cannot silently skip them.
local function effect_families(ctx, game)
    local attacker = fixture.actor(ctx, monsters.MONS_ORC, 60, 20, 30)
    local target = fixture.actor(ctx, monsters.MONS_RAT, 61, 20, 100)

    local venom = hit(ctx, attacker, target, 8, false)

    target_brands.apply(game, brands.VENOM, venom)
    harness.truthy(ctx:has(target, component.PROJECTILE_POISON),
        "monster attacker venom creates the target's poison state")

    local draining = hit(ctx, attacker, target, 8, false)

    target_brands.apply(game, brands.DRAINING, draining)
    harness.truthy(ctx:has(target, component.MONSTER_DRAINED),
        "monster attacker draining creates the target's drain state")

    local wizard = fixture.actor(ctx,
        monsters.MONS_ORC_WIZARD, 62, 20, 100)
    local antimagic = hit(ctx, attacker, wizard, 8, false)

    target_brands.apply(game, brands.ANTIMAGIC, antimagic)
    harness.truthy(ctx:has(wizard, component.MONSTER_ENFEEBLE),
        "monster attacker Antimagic disrupts a wizard's spell state")

    local acid = hit(ctx, attacker, target, 8, false)
    local before = acid.health.current

    target_brands.apply(game, brands.ACID, acid)
    harness.truthy(acid.health.current < before,
        "acid brand applies its independent monster splash")

    local health = ctx:get(attacker, component.HEALTH)

    health.current = 10
    ctx:set(attacker, component.HEALTH, health)

    local vampire = hit(ctx, attacker, target, 8, false)

    target_brands.apply(game, brands.VAMPIRISM, vampire)
    harness.truthy(ctx:get(attacker, component.HEALTH).current > 10,
        "monster attacker vampirism heals a wounded wielder")
end

-- A saved player illusion uses the source player's Necromancy skill for
-- Pain; undead susceptibility and electrical immunity stay with the target.
local function special_resistance(ctx, game)
    local ghost = fixture.actor(ctx,
        monsters.MONS_PLAYER_ILLUSION, 70, 20)
    local living = fixture.actor(ctx, monsters.MONS_RAT, 71, 20, 100)

    ctx:add(ghost, component.PLAYER_ILLUSION, {
        name = "Necromancer",
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        brand_id = brands.PAIN,
        holiness_id = holiness.NATURAL,
        necromancy_skill = 10,
    })

    local painful = hit(ctx, ghost, living, 8, false)

    target_brands.apply(game, brands.PAIN, painful)
    harness.truthy(painful.health.current < 100,
        "illusion Pain uses captured Necromancy skill")

    local undead = fixture.actor(ctx, monsters.MONS_ZOMBIE,
        72, 20, 100)
    local holy_hit = hit(ctx, ghost, undead, 8, false)

    target_brands.apply(game, brands.HOLY_WRATH, holy_hit)
    harness.truthy(holy_hit.health.current < 100,
        "Holy Wrath uses the monster target's holiness")

    local electric_target = fixture.actor(ctx,
        monsters.MONS_RAT, 73, 20, 100)
    local original_random = game.random

    -- Force only the one-in-four lightning proc; other bounds stay at
    -- their maximal values so the electrical bonus remains visible.
    function game:random(stream, bound)
        if bound == 4 then
            return 0
        end

        return original_random(self, stream, bound)
    end

    local electric = hit(ctx, ghost, electric_target, 8, false)

    target_brands.apply(game, brands.ELECTROCUTION, electric)
    harness.truthy(electric.health.current < 100,
        "Electrocution applies to an unresistant monster")

    local eel = fixture.actor(ctx, monsters.MONS_ELECTRIC_EEL,
        74, 20, 100)
    local immune = hit(ctx, ghost, eel, 8, false)

    target_brands.apply(game, brands.ELECTROCUTION, immune)
    harness.equal(immune.health.current, 100,
        "electrical resistance blocks the lightning burst")

    local ice_beast = fixture.actor(ctx, monsters.MONS_ICE_BEAST,
        75, 20, 100)
    local frozen = hit(ctx, ghost, ice_beast, 8, false)

    target_brands.apply(game, brands.FREEZING, frozen)
    harness.equal(frozen.health.current, 100,
        "cold resistance blocks Freezing bonus damage")

    game.random = original_random
end

-- Monster Chaos Confuse uses AF_CONFUSE's one-in-three gate and an HD
-- duration; it does not make the player's willpower contest.
local function monster_confuse(ctx, game)
    local attacker = fixture.actor(ctx, monsters.MONS_ORC, 76, 20)
    local target = fixture.actor(ctx, monsters.MONS_RAT, 77, 20, 100)
    local contact = hit(ctx, attacker, target, 0, false)
    local original_random = game.random

    ctx:add(attacker, component.SUMMON_STATS, { hd = 20 })

    function game:random(_, bound)
        return bound - 1
    end

    target_brands.apply(game, brands.CONFUSE, contact)
    harness.falsy(ctx:has(target, component.MONSTER_CONFUSION),
        "two out of three monster Confuse results do nothing")

    function game:random(_, bound)
        if bound == 3 then
            return 0
        end

        return bound - 1
    end

    target_brands.apply(game, brands.CONFUSE, contact)

    local definition = catalog.get("monsters", monsters.MONS_ORC)
    local hd = monster_stats.hit_dice(ctx, attacker, definition)
    local status = ctx:get(target, component.MONSTER_CONFUSION)

    harness.truthy(status.remaining_aut > 0 and
        status.remaining_aut < (3 + hd) * 10,
        "monster Confuse converts HD-based strength to beam duration")

    ctx:remove(target, component.MONSTER_CONFUSION)

    local clear_hit = hit(ctx, attacker, target, 0, false)

    clear_hit.definition = {
        name = "rat",
        flags = { monster_flags.CLARITY },
    }
    target_brands.apply(game, brands.CONFUSE, clear_hit)
    harness.falsy(ctx:has(target, component.MONSTER_CONFUSION),
        "innate clarity blocks monster Chaos confusion")
    game.random = original_random
end

-- A zero-damage contact still carries Venom, while Flaming needs a
-- positive ordinary strike before its separate elemental roll.
local function zero_damage(ctx, game)
    local attacker = fixture.actor(ctx, monsters.MONS_ORC, 78, 20)
    local target = fixture.actor(ctx, monsters.MONS_RAT, 79, 20, 100)
    local empty = hit(ctx, attacker, target, 0, false)

    target_brands.apply(game, brands.FLAMING, empty)
    harness.equal(ctx:get(target, component.HEALTH).current, 100,
        "zero-damage Flaming does not add elemental damage")

    target_brands.apply(game, brands.VENOM, empty)
    harness.truthy(ctx:has(target, component.PROJECTILE_POISON),
        "zero-damage Venom still poisons on contact")
end

-- Fixed maximal rolls make both passes hit and give the bonus a positive
-- bound; the test does not mirror the production damage formula.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    -- Maximal rolls ensure hits and eligible brand procs repeat exactly.
    function game:random(_, bound)
        return bound - 1
    end

    ordinary(ctx, game)
    physical_contact(ctx, game)
    illusion(ctx, game)
    kill_credit(ctx, game)
    effect_families(ctx, game)
    special_resistance(ctx, game)
    monster_confuse(ctx, game)
    zero_damage(ctx, game)
end

return test
