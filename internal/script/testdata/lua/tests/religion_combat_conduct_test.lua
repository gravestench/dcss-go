-- The source death classifier reads live ECS and the resolved monster
-- catalog. These fixtures use actual imported monsters and component schemas.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local kinds = require("constants.religion_conduct")
local monsters = require("ids.monsters")
local species = require("ids.species")
local jobs = require("ids.jobs")
local conduct = require("policy.religion.conduct")
local facts = require("policy.religion.conduct.monster_facts")
local traits = require("policy.religion.conduct.monster_traits")

local test = {}

-- A production actor record supplies identity; its combat side can be
-- overridden without changing the catalog species definition.
local function actor(ctx, kind_id, side)
    local entity = ctx:create()

    ctx:add(entity, component.ACTOR, { kind_id = kind_id })
    ctx:add(entity, component.HEALTH, {
        current = 0,
        max = 15,
    })

    if side then
        ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
            attitude = side,
        })
    end

    return entity
end

-- A priest's patron is part of source evil classification. Mennas follows
-- Zin, while an ordinary orc priest follows Beogh; a modded authored god
-- takes precedence over either species default.
local function priest_patron(ctx)
    local mennas = actor(ctx, monsters.MONS_MENNAS)
    local good = catalog.get(categories.MONSTERS, monsters.MONS_MENNAS)
    local priest = actor(ctx, monsters.MONS_ORC_PRIEST)
    local orc = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_PRIEST)

    harness.falsy(traits.evil(ctx, mennas, good, true))
    harness.truthy(traits.evil(ctx, priest, orc, true))
end

-- Return event IDs without depending on discovery or map traversal order.
local function has_event(events, wanted)
    for _, event in ipairs(events) do
        if event.id == wanted then
            return event
        end
    end

    return nil
end

-- Formerly neutral holy monsters stay protected after desertion changes
-- their current side. The saved marker is consulted by both attack and
-- death classifiers rather than inferred from today's attitude alone.
local function former_neutral(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    local holy = actor(ctx, monsters.MONS_ANGEL,
        attitudes.HOSTILE)
    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_ANGEL)

    ctx:add(holy, component.RELIGION_WAS_NEUTRAL, {
        remembered = true,
    })

    local attack = has_event(facts.attack(observed, holy, definition),
        kinds.ATTACK_HOLY)
    local death = has_event(facts.death(observed, holy, definition),
        kinds.KILL_HOLY)

    harness.truthy(attack.was_neutral)
    harness.truthy(death.was_neutral)
end

-- Trog can gain from both a natural kill and a spellcasting victim. The
-- special wizard response is independent of the ordinary holiness curve.
local function wizard_kill(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })
    local draws = 0

    function observed:player()
        return player
    end

    function observed:random(stream, bound)
        harness.equal(stream, "religion")
        harness.truthy(bound == 21 or bound == 13)
        draws = draws + 1

        return 0
    end

    ctx:add(player, component.PROGRESSION, { level = 1 })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.TROG,
        piety = 15,
    })

    local wizard = actor(ctx, monsters.MONS_ORC_WIZARD)
    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_WIZARD)
    local events = facts.death(observed, wizard, definition)

    harness.truthy(has_event(events, kinds.KILL_LIVING))
    harness.truthy(has_event(events, kinds.KILL_WIZARD))

    for _, event in ipairs(events) do
        conduct.record(observed, event)
    end

    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).piety, 17)
    harness.equal(draws, 2)
end

-- Source reward gates suppress friendly and summoned victims even when
-- their holiness and spellbook would otherwise produce the same events.
local function ineligible_kills(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    local friendly = actor(ctx, monsters.MONS_ORC_WIZARD,
        attitudes.FRIENDLY)
    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_WIZARD)
    local friend_events = facts.death(observed, friendly, definition)

    harness.falsy(has_event(friend_events, kinds.KILL_LIVING).credit)

    local summoned = actor(ctx, monsters.MONS_ORC_WIZARD)

    ctx:add(summoned, component.SUMMON, {
        owner = friendly,
        attitude = attitudes.HOSTILE,
    })

    local summon_events = facts.death(observed, summoned, definition)

    harness.falsy(has_event(summon_events, kinds.KILL_LIVING).credit)
end

-- Attack conduct is based on the target's state before the strike. A miss
-- still counts, while an ordinary hostile target produces no attack event.
local function attack_facts(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_WIZARD)
    local friend = actor(ctx, monsters.MONS_ORC_WIZARD,
        attitudes.FRIENDLY)
    local neutral = actor(ctx, monsters.MONS_ORC_WIZARD,
        attitudes.NEUTRAL)
    local hostile = actor(ctx, monsters.MONS_ORC_WIZARD)

    harness.truthy(has_event(facts.attack(observed, friend, definition),
        kinds.ATTACK_FRIEND))
    harness.truthy(has_event(facts.attack(observed, neutral, definition),
        kinds.ATTACK_NEUTRAL))
    harness.equal(#facts.attack(observed, hostile, definition), 0)
end

-- Source melee, missiles, and spell contacts forgive an unseen accidental
-- ally strike. Visibility is captured before damage reveals the monster.
local function unseen_attack(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:visible()
        return false
    end

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    local friend = actor(ctx, monsters.MONS_ORC_WIZARD,
        attitudes.FRIENDLY)

    ctx:add(friend, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })

    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_WIZARD)
    local event = has_event(facts.attack(observed, friend, definition),
        kinds.ATTACK_FRIEND)

    harness.falsy(event.known)
end

-- Source allied protections are narrower for Beogh, Jiyva, and Fedhas.
-- Their per-god filters must not punish strikes against unrelated allies.
local function protected_friends(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    local cases = {
        {
            god = gods.BEOGH,
            protected = monsters.MONS_ORC_WIZARD,
            unrelated = monsters.MONS_RAT,
        },
        {
            god = gods.JIYVA,
            protected = monsters.MONS_JELLY,
            unrelated = monsters.MONS_RAT,
        },
        {
            god = gods.FEDHAS,
            protected = monsters.MONS_PLANT,
            unrelated = monsters.MONS_RAT,
        },
    }

    for _, case in ipairs(cases) do
        local definition = catalog.get(categories.GODS, case.god)
        local handler = require(definition.conduct_module)
        local rule = handler.dislikes[kinds.ATTACK_FRIEND]

        for _, sample in ipairs({
            { id = case.protected, expected = true },
            { id = case.unrelated, expected = false },
        }) do
            local victim = actor(ctx, sample.id, attitudes.FRIENDLY)
            local profile = catalog.get(categories.MONSTERS, sample.id)
            local event = has_event(facts.attack(observed, victim, profile),
                kinds.ATTACK_FRIEND)

            harness.equal(rule.filter(observed, player, event),
                sample.expected)
        end
    end
end

-- Okawaru uses two independent draws of the victim's actual XP value.
-- At Human XL1 the source level factor is zero, so their sum is exact.
local function okawaru_difficulty(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })
    local bounds = {}

    function observed:player()
        return player
    end

    function observed:random(stream, bound)
        harness.equal(stream, "religion")
        bounds[#bounds + 1] = bound

        return math.floor(bound / 2)
    end

    ctx:add(player, "core.player", {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, { level = 1 })

    local wizard = actor(ctx, monsters.MONS_ORC_WIZARD)
    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_WIZARD)
    local event = has_event(facts.death(observed, wizard, definition),
        kinds.KILL_LIVING)
    local rule = require("policy.religion.conduct.okawaru").likes[event.id]
    local numerator, denominator = rule.special(observed, player, event,
        0, 1)
    local bound = event.experience * 100

    harness.truthy(bound > 0)
    harness.equal(bounds[1], bound)
    harness.equal(bounds[2], bound)
    harness.equal(numerator, 2 * math.floor(bound / 2))
    harness.equal(denominator, 550)
end

-- The source emits distinct conduct classes for evil, unclean, and chaotic
-- victims. Test named imported monsters instead of duplicating their traits.
local function special_deaths(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    for _, sample in ipairs({
        {
            monster = monsters.MONS_ORC_PRIEST,
            conduct = kinds.KILL_NATURAL_EVIL,
        },
        {
            monster = monsters.MONS_CRAZY_YIUF,
            conduct = kinds.KILL_UNCLEAN,
        },
        {
            monster = monsters.MONS_UGLY_THING,
            conduct = kinds.KILL_CHAOTIC,
        },
    }) do
        local victim = actor(ctx, sample.monster)
        local definition = catalog.get(categories.MONSTERS,
            sample.monster)
        local events = facts.death(observed, victim, definition)

        harness.truthy(has_event(events, sample.conduct),
            sample.monster .. " must produce source conduct")
    end
end

-- The Shining One considers an XP-bearing monster only on first sight,
-- then declines the encounter reward when that creature is already evil.
local function first_sight(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    ctx:add(player, component.PROGRESSION, { level = 4 })

    local rat = actor(ctx, monsters.MONS_RAT)
    local rat_def = catalog.get(categories.MONSTERS, monsters.MONS_RAT)
    local encounter = facts.sight(observed, rat, rat_def)
    local rule = require("policy.religion.conduct.shining_one")
        .likes[kinds.SEE_MONSTER]
    local gain, chance = rule.special(observed, player, encounter, 0, 1)

    harness.equal(encounter.id, kinds.SEE_MONSTER)
    harness.truthy(rule.filter(observed, player, encounter))
    harness.equal(chance,
        math.floor(rat_def.hd / 2) + 6 - math.floor(4 / 4))
    harness.equal(gain, chance - 4)

    local undead = actor(ctx, monsters.MONS_WIGHT)
    local undead_def = catalog.get(categories.MONSTERS,
        monsters.MONS_WIGHT)

    harness.falsy(rule.filter(observed, player,
        facts.sight(observed, undead, undead_def)))
end

-- A sufficiently faster foe always gets Cheibriados's doubled pace
-- appreciation; the source chance uses the delta out of twelve.
local function cheibriados_pace(ctx)
    local handler = require("policy.religion.conduct.cheibriados")
    local rule = handler.likes[kinds.KILL_FAST]
    local observed = setmetatable({}, { __index = ctx })
    local draws = 0

    function observed:random(stream, bound)
        harness.equal(stream, "religion")
        harness.equal(bound, 12)
        draws = draws + 1

        return 0
    end

    local numerator, denominator, message = rule.special(observed,
        nil, { speed_delta = 12 }, 8, 20)

    harness.equal(numerator, 16)
    harness.equal(denominator, 20)
    harness.truthy(message:find("thoroughly", 1, true))
    harness.equal(draws, 1)
end

-- Fedhas only calls a corpse-bearing living kill an ecosystem contribution.
-- Creatures without a corpse keep the ordinary acceptance message.
local function fedhas_ecosystem()
    local rule = require("policy.religion.conduct.fedhas")
        .likes[kinds.KILL_LIVING]
    local _, _, contribution = rule.special(nil, nil,
        { leaves_corpse = true }, 2, 20)
    local _, _, ordinary = rule.special(nil, nil,
        { leaves_corpse = false }, 2, 20)

    harness.truthy(contribution:find("ecosystem", 1, true))
    harness.truthy(ordinary:find("accepts", 1, true))
end

-- Multiple source conducts can result from one death; each resolves
-- before the actor is destroyed and before later turn systems run.
function test.run(ctx)
    priest_patron(ctx)
    former_neutral(ctx)
    wizard_kill(ctx)
    ineligible_kills(ctx)
    attack_facts(ctx)
    unseen_attack(ctx)
    protected_friends(ctx)
    okawaru_difficulty(ctx)
    special_deaths(ctx)
    first_sight(ctx)
    cheibriados_pace(ctx)
    fedhas_ecosystem()
end

return test
