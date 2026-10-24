-- A beast's saved form must drive every live consumer. These fixtures use
-- the real catalog, Akara components, and ordinary combat/spell policies.
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local attack_types = require("constants.monster_attack_types")
local flavours = require("constants.attack_flavours")
local resistances = require("constants.resistance_ids")
local monster_flags = require("constants.monster_flags")
local spell_flags = require("constants.monster_spell_flags")
local form = require("policy.monsters.mutant_beast.form")
local profile = require("policy.combat.monster_profile")
local stats = require("policy.combat.monster_stats")
local sequence = require("policy.combat.monster_attack_sequence")
local defense = require("policy.combat.monster_defense")
local resistance = require("policy.combat.monster_resistance")
local spellbook = require("policy.combat.monster_spellbook")
local factory = require("policy.population.factory")
local actions = require("policy.combat.melee_actions")
local attitudes = require("constants.attitude")
local spell_prospect = require("policy.ai.spell_prospect")
local breath = require("policy.combat.monster_breath")
local route = require("policy.ai.route")
local reach = require("policy.combat.monster_reach")
local flavour_policy = require("policy.combat.monster_attack_flavours")

local test = {}

-- A saved tier sets HD and the primary hit. Only facets with a physical
-- attack fill later slots, in authored order rather than a sorted order.
local function tier_and_contacts(ctx)
    local catalog_beast = catalog.get("monsters",
        monsters.MONS_MUTANT_BEAST)
    local tiers = {
        { name = "larval", hd = 3, hit = 12, facet = 5 },
        { name = "juvenile", hd = 9, hit = 19, facet = 10 },
        { name = "mature", hd = 15, hit = 26, facet = 15 },
        { name = "elder", hd = 21, hit = 33, facet = 20 },
        { name = "primal", hd = 27, hit = 40, facet = 25 },
    }

    for index, tier in ipairs(tiers) do
        local beast = fixture.actor(ctx, monsters.MONS_MUTANT_BEAST,
            index + 10, 20, 100)

        ctx:add(beast, component.MONSTER_MUTANT_BEAST,
            form.parse(tier.name ..
                " ox-sting-fire-weird mutant beast"))

        local current = profile.definition(ctx, beast, catalog_beast)
        local contacts = sequence.for_actor(ctx, beast, current)

        harness.equal(stats.base_hit_dice(ctx, beast, current), tier.hd,
            "tier controls live monster HD")
        harness.equal(#contacts, 4,
            "three attack facets add three contacts after primary")
        harness.equal(contacts[1].attack.type_id, attack_types.HIT,
            "mutant beast starts with primary hit")
        harness.equal(contacts[1].attack.damage, tier.hit,
            "primary hit scales with source tier")
        harness.equal(contacts[2].attack.type_id, attack_types.TRAMPLE,
            "Ox retains its authored first facet position")
        harness.equal(contacts[2].attack.flavour_id, flavours.TRAMPLE,
            "Ox contact carries trample flavour")
        harness.equal(contacts[2].attack.damage, tier.facet,
            "facet damage scales with source tier")
        harness.equal(contacts[3].attack.type_id, attack_types.STING,
            "Sting retains its authored second facet position")
        harness.equal(contacts[3].attack.flavour_id,
            flavours.REACH_STING, "Sting keeps reach poison flavour")
        harness.equal(contacts[4].attack.type_id,
            attack_types.CONSTRICT, "Weird contributes constriction")
        harness.equal(contacts[4].attack.flavour_id,
            flavours.CRUSH, "Weird constriction crushes")
    end
end

-- Resistance is a live facet trait, and Ox's AC is intrinsic so the
-- ordinary defense policy adds equipment and statuses after it.
local function defenses(ctx)
    local beast = fixture.actor(ctx, monsters.MONS_MUTANT_BEAST,
        30, 20, 100)

    ctx:add(beast, component.MONSTER_MUTANT_BEAST,
        form.parse("mature sting-fire-shock-ox mutant beast"))

    local current = profile.definition(ctx, beast,
        catalog.get("monsters", monsters.MONS_MUTANT_BEAST))

    for _, id in ipairs({
        resistances.POISON,
        resistances.FIRE,
        resistances.ELECTRICITY,
        resistances.COLD,
    }) do
        harness.equal(resistance.level(ctx, beast, current, id), 1,
            "each defensive facet grants its source resistance")
    end

    harness.equal(defense.armour(ctx, beast, current),
        catalog.get("monsters", monsters.MONS_MUTANT_BEAST).ac + 5,
        "Ox grants five intrinsic AC")
end

-- Bat speed is saved on the actor used by energy, while its projected
-- BATTY flag reaches the ordinary post-contact retreat policy.
local function bat_speed_and_spawn(ctx)
    ctx:add(ctx:player(), component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        boris_killed = false,
    })

    local authored = form.parse("mature bat-weird mutant beast")
    local beast = factory.spawn(ctx, monsters.MONS_MUTANT_BEAST,
        1, 40, 20, {
            mutant_beast = authored,
        })
    local current = profile.definition(ctx, beast,
        catalog.get("monsters", monsters.MONS_MUTANT_BEAST))

    harness.equal(ctx:get(beast, component.ACTOR).speed, 20,
        "Bat doubles saved actor speed for energy")
    harness.equal(current.speed, 20,
        "Bat doubles the current profile speed")
    harness.truthy(current.flags[#current.flags] == monster_flags.BATTY,
        "Bat uses the existing batty movement flag")

    local natural = factory.spawn(ctx, monsters.MONS_MUTANT_BEAST,
        1, 42, 20)
    local rolled = ctx:get(natural, component.MONSTER_MUTANT_BEAST)

    harness.truthy(rolled, "natural beast saves its rolled form")
    harness.equal(rolled.tier, "mature",
        "catalog HD fifteen gives natural mature tier")
    harness.equal(#rolled.facets, 2,
        "natural beast rolls two facets")
    harness.truthy(rolled.facets[1] ~= rolled.facets[2],
        "natural beast facets are distinct")
end

-- Fire and Shock add actor-specific natural slots; these are consumed by
-- the same prospect and effect policies as any ordinary monster spell.
local function facet_spells(ctx)
    local beast = fixture.actor(ctx, monsters.MONS_MUTANT_BEAST,
        50, 20, 100)

    ctx:add(beast, component.MONSTER_MUTANT_BEAST,
        form.parse("primal shock-fire mutant beast"))

    local book = spellbook.for_actor(ctx, beast)

    harness.equal(#book.slots, 2,
        "two casting facets make two ordinary spell slots")
    harness.equal(book.slots[1].spell_id, spells.SPELL_BLINKBOLT,
        "Shock adds Blinkbolt in authored order")
    harness.equal(book.slots[2].spell_id, spells.SPELL_FIRE_BREATH,
        "Fire adds Fire Breath in authored order")

    for _, slot in ipairs(book.slots) do
        harness.equal(slot.frequency, 60,
            "facet spell keeps source frequency")
        harness.equal(slot.flags[1], spell_flags.NATURAL,
            "facet spell is natural")
    end

    harness.equal(book.slots[2].flags[2], spell_flags.BREATH,
        "Fire Breath uses the breath cooldown flag")

    local fire_only = {
        slots = { book.slots[2] },
    }
    local condition = {
        hp = 100,
        max_hp = 100,
        distance = 2,
        silenced = false,
        breath_ready = true,
    }
    local function first_draw()
        return 0
    end

    harness.truthy(spell_prospect.choose(fire_only,
        condition, first_draw), "ready beast may choose Fire Breath")

    function ctx:random(_, bound)
        return bound - 1
    end

    breath.begin(ctx, beast)
    condition.breath_ready = breath.ready(ctx, beast)

    harness.falsy(condition.breath_ready,
        "completed breath starts a saved monster cooldown")
    harness.falsy(spell_prospect.choose(fire_only,
        condition, first_draw),
        "cooling beast cannot choose Fire Breath again")

    for _ = 1, 4 do
        breath.advance(ctx, beast)
        harness.falsy(breath.ready(ctx, beast),
            "Fire Breath remains cooling during own actions")
    end

    breath.advance(ctx, beast)
    harness.truthy(breath.ready(ctx, beast),
        "Fire Breath recovers after five own actions")
end

-- The Sting contact must poison a monster defender through the same
-- ordinary melee flavour path as other poison-bearing monsters.
local function sting_vs_monster(ctx)
    local beast = fixture.actor(ctx, monsters.MONS_MUTANT_BEAST,
        60, 20, 100)
    local victim = fixture.actor(ctx, monsters.MONS_RAT,
        61, 20, 1000)

    ctx:add(beast, component.MONSTER_MUTANT_BEAST,
        form.parse("mature sting mutant beast"))
    ctx:add(victim, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    function ctx:random(stream, bound)
        if stream == "melee" and bound == 3 then
            return 0
        end

        return bound - 1
    end

    actions.monster_target(ctx, beast, victim)

    harness.truthy(ctx:has(victim, component.PROJECTILE_POISON),
        "Sting facet poisons a monster hit by its contact")

    local armoured = fixture.actor(ctx, monsters.MONS_RAT,
        63, 20, 1000)

    flavour_policy.apply(ctx, flavours.REACH_STING, {
        kind = "hit",
        attacker = beast,
        defender = armoured,
        defender_definition = catalog.get("monsters", monsters.MONS_RAT),
        hit_dice = 15,
        damage_done = 0,
    })

    harness.falsy(ctx:has(armoured, component.PROJECTILE_POISON),
        "an armoured zero-damage Sting cannot poison")
end

-- Source rerolls HP when a vault supplies a different HD. The same HP
-- stream outcome should make a primal body sturdier than a mature one.
local function authored_hit_points(ctx)
    function ctx:random(_, bound)
        return bound - 1
    end

    local mature = factory.spawn(ctx, monsters.MONS_MUTANT_BEAST,
        1, 52, 20, {
            mutant_beast = form.parse("mature fire-shock mutant beast"),
        })
    local primal = factory.spawn(ctx, monsters.MONS_MUTANT_BEAST,
        1, 54, 20, {
            mutant_beast = form.parse("primal fire-shock mutant beast"),
            hd = 27,
        })

    harness.truthy(ctx:get(primal, component.HEALTH).max >
        ctx:get(mature, component.HEALTH).max,
        "primal authored HD raises source average HP")
end

-- DES permits a tier without listed facets and a facet list without a
-- tier. Both forms must reach the same saved profile as a full spelling.
local function partial_des_forms()
    local tier_only = form.parse("primal mutant beast")
    local facet_only = form.parse("sting-ox mutant beast")

    harness.equal(tier_only.hit_dice, 27,
        "tier-only DES form keeps its authored HD")
    harness.equal(#tier_only.facets, 0,
        "tier-only DES form requests random facets")
    harness.equal(facet_only.tier, "mature",
        "facet-only DES form uses catalog tier")
    harness.equal(facet_only.facets[1], "sting",
        "facet-only DES form keeps authored order")

    local upgraded = form.with_hit_dice(facet_only, 27)

    harness.equal(upgraded.tier, "primal",
        "an explicit HD upgrades facet-only tier")
    harness.equal(upgraded.hit_dice, 27,
        "explicit HD and saved form agree")
end

-- Save validation requires every current beast to retain its live form
-- and rejects a beast component borrowed by an unrelated species.
local function saved_form_invariant(ctx)
    local beast = fixture.actor(ctx, monsters.MONS_MUTANT_BEAST,
        74, 20, 100)
    local actor = ctx:get(beast, component.ACTOR)
    local okay = pcall(form.validate_actor, ctx, beast, actor)

    harness.falsy(okay, "save rejects a beast missing its form")

    ctx:add(beast, component.MONSTER_MUTANT_BEAST,
        form.parse("primal sting-ox mutant beast"))
    form.validate_actor(ctx, beast, actor)

    local invalid = ctx:get(beast, component.MONSTER_MUTANT_BEAST)

    invalid.hit_dice = 15
    ctx:set(beast, component.MONSTER_MUTANT_BEAST, invalid)
    okay = pcall(form.validate_actor, ctx, beast, actor)

    harness.falsy(okay, "save rejects tier and HD disagreement")
end

-- A Sting beast can strike across one open intervening cell without
-- spending a move. Blocking both middle cells on a diagonal denies reach.
local function sting_reach(ctx)
    local beast = fixture.actor(ctx, monsters.MONS_MUTANT_BEAST,
        70, 20, 100)
    local victim = fixture.actor(ctx, monsters.MONS_RAT,
        72, 20, 100)

    ctx:add(beast, component.MONSTER_MUTANT_BEAST,
        form.parse("mature sting mutant beast"))
    ctx:add(victim, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    local state = {
        target_x = 72,
        target_y = 20,
    }
    local origin = ctx:get(beast, component.POSITION)
    local target = ctx:get(victim, component.POSITION)
    local intent = route.follow(ctx, beast, state, origin,
        target, victim, true)

    harness.equal(intent.kind, 2,
        "Sting beast chooses melee at two cells")
    harness.equal(intent.dx, 2,
        "distant melee targets the real foe cell")
    harness.truthy(reach.can(ctx, beast, origin, target),
        "open middle cell permits Sting reach")
    local contacts = sequence.for_actor(ctx, beast,
        profile.definition(ctx, beast,
            catalog.get("monsters", monsters.MONS_MUTANT_BEAST)))

    harness.falsy(reach.contact(ctx, beast,
        contacts[1].attack, 1, 2),
        "the primary hit cannot strike from two cells")
    harness.truthy(reach.contact(ctx, beast,
        contacts[2].attack, 2, 2),
        "only the Sting slot can strike from two cells")

    local contact_messages = 0

    function ctx:emit(channel, message)
        if channel == "combat" and
            (message:find("The mutant beast hits the rat", 1, true) or
                message:find("The mutant beast misses the rat", 1, true) or
                message:find("The rat dodges the mutant beast", 1, true) or
                message:find("The rat blocks the mutant beast", 1, true)) then
            contact_messages = contact_messages + 1
        end
    end

    actions.monster_target(ctx, beast, victim)
    harness.equal(contact_messages, 1,
        "distant round resolves Sting but skips the primary hit")

    ctx.walls["71:20"] = true
    harness.falsy(reach.can(ctx, beast, origin, target),
        "a blocked middle cell prevents straight reach")

    -- The sparse fixture has no grid pathfinder; offer the blocked direct
    -- step so route.follow must use its ordinary safe detour.
    function ctx:route_step()
        return 1, 0, true
    end

    intent = route.follow(ctx, beast, state, origin,
        target, victim, true)
    harness.equal(intent.kind, 1,
        "blocked Sting reach returns to ordinary routing")

    ctx.walls["71:20"] = nil
    ctx:move_actor(victim, 1, 72, 21)
    target = ctx:get(victim, component.POSITION)
    ctx.walls["71:20"] = true
    harness.truthy(reach.can(ctx, beast, origin, target),
        "one open diagonal middle cell still permits reach")

    ctx.walls["71:21"] = true
    harness.falsy(reach.can(ctx, beast, origin, target),
        "two blocked diagonal middle cells prevent reach")
end

-- Each assertion calls the production owner rather than recreating its
-- schema or its derived state in a test-only combat implementation.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    tier_and_contacts(game)
    defenses(game)
    bat_speed_and_spawn(game)
    facet_spells(game)
    sting_vs_monster(game)
    authored_hit_points(game)
    partial_des_forms()
    saved_form_invariant(game)
    sting_reach(game)
end

return test
