-- A melee action follows the actor's current attack sequence. These
-- assertions use real catalog monsters and saved Akara head components.
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")
local actions = require("policy.combat.melee_actions")
local attitudes = require("constants.attitude")
local species = require("ids.species")
local attack_types = require("constants.monster_attack_types")
local flavours = require("constants.attack_flavours")
local constriction_system = require("systems.status_constriction")
local equipment = require("policy.combat.equipment")
local items = require("ids.items")

local test = {}

-- A later attack slot belongs to the same action, while a saved head
-- count repeats a hydra's first bite before its later catalog slots.
local function sequence_shape(ctx)
    local okay, sequence = pcall(require,
        "policy.combat.monster_attack_sequence")

    harness.truthy(okay, "monster attack sequence owner loads")

    local ettin = fixture.actor(ctx, monsters.MONS_ETTIN,
        10, 10, 100)
    local ettin_kind = catalog.get("monsters", monsters.MONS_ETTIN)
    local blows = sequence.for_actor(ctx, ettin, ettin_kind)

    harness.equal(#blows, 2,
        "both Ettin hits belong to one melee round")
    harness.equal(blows[1].slot, 1,
        "first contact reads catalog slot one")
    harness.equal(blows[2].slot, 2,
        "second contact reads catalog slot two")

    local rat = fixture.actor(ctx, monsters.MONS_RAT,
        12, 10, 100)

    harness.equal(#sequence.for_actor(ctx, rat,
        catalog.get("monsters", monsters.MONS_RAT)), 1,
        "ordinary rat keeps one contact")

    local hydra = fixture.actor(ctx, monsters.MONS_HYDRA,
        14, 10, 100)

    ctx:add(hydra, component.MONSTER_HYDRA_HEADS, {
        count = 3,
    })

    local bites = sequence.for_actor(ctx, hydra,
        catalog.get("monsters", monsters.MONS_HYDRA))

    harness.equal(#bites, 3,
        "saved three headed hydra attempts three bites")

    for _, bite in ipairs(bites) do
        harness.equal(bite.slot, 1,
            "each hydra head reuses first catalog bite")
    end

    local lernaean = fixture.actor(ctx,
        monsters.MONS_LERNAEAN_HYDRA, 16, 10, 100)

    ctx:add(lernaean, component.MONSTER_HYDRA_HEADS, {
        count = 27,
    })

    harness.equal(#sequence.for_actor(ctx, lernaean,
        catalog.get("monsters", monsters.MONS_LERNAEAN_HYDRA)),
        27, "Lernaean hydra keeps all 27 heads")

    local ordinary = fixture.actor(ctx, monsters.MONS_ORC,
        18, 10, 100)

    ctx:add(ordinary, component.VAULT_ACTOR_OVERRIDES, {
        base_id = monsters.MONS_HYDRA,
    })
    ctx:add(ordinary, component.MONSTER_HYDRA_HEADS, {
        count = 3,
    })

    harness.equal(#sequence.for_actor(ctx, ordinary,
        catalog.get("monsters", monsters.MONS_ORC)), 1,
        "unrelated vault base cannot grant hydra attacks")

    local zombie = fixture.actor(ctx, monsters.MONS_ZOMBIE,
        20, 10, 100)

    ctx:add(zombie, component.VAULT_ACTOR_OVERRIDES, {
        base_id = monsters.MONS_FIRE_DRAGON,
    })

    local inherited = sequence.for_actor(ctx, zombie,
        catalog.get("monsters", monsters.MONS_ZOMBIE))

    harness.equal(#inherited, 3,
        "zombie uses its corpse base's complete attack sequence")
    harness.equal(inherited[1].attack.type_id,
        attack_types.BITE, "zombie inherits base attack type")
    harness.equal(inherited[1].attack.damage, 16,
        "zombie attack damage is eighty percent of base")
    harness.equal(inherited[1].attack.flavour_id,
        flavours.PLAIN, "zombie loses unpreserved attack flavour")

    local cherub = fixture.actor(ctx, monsters.MONS_CHERUB,
        22, 10, 100)
    local cherub_blows = sequence.for_actor(ctx, cherub,
        catalog.get("monsters", monsters.MONS_CHERUB))
    local draw = {
        random = function(_, stream, bound)
            harness.equal(stream, "melee",
                "attack type selection uses combat RNG")
            harness.equal(bound, 4,
                "Cherub chooses from four source attack types")

            return 0
        end,
    }

    harness.equal(sequence.contact_type(draw,
        cherub_blows[2].attack), attack_types.HIT,
        "Cherub's second contact can become a weapon hit")

    draw.random = function(_, _, bound)
        return bound - 1
    end

    harness.equal(sequence.contact_type(draw,
        cherub_blows[2].attack), attack_types.GORE,
        "Cherub's second contact also reaches its gore outcome")
end

-- An Ettin's second AT_HIT uses its second held weapon; a non-dual
-- wielder cannot make a spare weapon active by placing it in that slot.
local function offhand_weapon(ctx)
    local ettin = fixture.actor(ctx, monsters.MONS_ETTIN,
        26, 10, 100)
    local primary = ctx:create()
    local secondary = ctx:create()

    for entity, slot in pairs({
        [primary] = "weapon",
        [secondary] = "alternate_weapon",
    }) do
        ctx:add(entity, component.ITEM, {
            kind_id = items.WPN_DAGGER,
            quantity = 1,
            plus = 0,
            charges = 0,
            ego = "",
        })
        ctx:add(entity, component.CARRIED_BY, {
            holder = ettin,
        })
        ctx:add(entity, component.EQUIPPED, {
            slot = slot,
        })
    end

    harness.equal(equipment.monster_melee(ctx, ettin, 1).entity,
        primary, "first Ettin hand uses primary weapon")
    harness.equal(equipment.monster_melee(ctx, ettin, 2).entity,
        secondary, "second Ettin hand uses offhand weapon")

    local orc = fixture.actor(ctx, monsters.MONS_ORC,
        28, 10, 100)
    local spare = ctx:create()

    ctx:add(spare, component.ITEM, {
        kind_id = items.WPN_DAGGER,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(spare, component.CARRIED_BY, {
        holder = orc,
    })
    ctx:add(spare, component.EQUIPPED, {
        slot = "alternate_weapon",
    })

    harness.falsy(equipment.monster_melee(ctx, orc, 1),
        "ordinary spare weapon does not wield itself")
end

-- Population rolls head state once. Authored DES counts and the Lernaean
-- fixed count must survive as actor data for every later melee action.
local function spawn_heads(ctx)
    ctx:add(ctx:player(), component.PLAYER_UNIQUE_HISTORY, {
        status = {},
        monsters = {},
        pan_states = {},
        boris_killed = false,
    })

    local natural = factory.spawn(ctx, monsters.MONS_HYDRA,
        1, 20, 20)
    local state = ctx:get(natural,
        component.MONSTER_HYDRA_HEADS)

    harness.truthy(state, "natural hydra saves its head roll")
    harness.truthy(state.count >= 4 and state.count <= 8,
        "natural hydra rolls four through eight heads")

    local authored = factory.spawn(ctx, monsters.MONS_HYDRA,
        1, 22, 20, {
            hydra_heads = 2,
        })

    harness.equal(ctx:get(authored,
        component.MONSTER_HYDRA_HEADS).count, 2,
        "authored two headed hydra keeps its source count")

    local lernaean = factory.spawn(ctx,
        monsters.MONS_LERNAEAN_HYDRA, 1, 24, 20)

    harness.equal(ctx:get(lernaean,
        component.MONSTER_HYDRA_HEADS).count, 27,
        "Lernaean hydra saves its fixed 27 heads")
end

-- A round must actually apply later slots to a durable enemy, instead of
-- merely advertising those slots in the sequence projection.
local function target_round(ctx)
    local attacker = fixture.actor(ctx, monsters.MONS_ETTIN,
        30, 20, 100)
    local victim = fixture.actor(ctx, monsters.MONS_RAT,
        31, 20, 1000)
    local messages = {}

    ctx:set(victim, component.HEALTH, {
        current = 1000,
        max = 1000,
    })
    ctx:add(victim, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    function ctx:random(_, bound)
        return bound - 1
    end

    function ctx:emit(channel, message)
        if channel == "combat" then
            messages[#messages + 1] = message
        end
    end

    actions.monster_target(ctx, attacker, victim)

    harness.equal(#messages, 2,
        "Ettin resolves two contacts in one monster action")
    harness.truthy(ctx:get(victim, component.HEALTH).current < 1000,
        "resolved contacts affect real target health")

    local killer = fixture.actor(ctx, monsters.MONS_ETTIN,
        34, 20, 100)
    local dying = fixture.actor(ctx, monsters.MONS_RAT,
        35, 20, 1)

    ctx:add(dying, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    messages = {}

    actions.monster_target(ctx, killer, dying)

    harness.equal(#messages, 1,
        "ordinary melee stops when its first contact kills")

    local hydra = fixture.actor(ctx, monsters.MONS_HYDRA,
        40, 20, 100)
    local first = fixture.actor(ctx, monsters.MONS_RAT,
        41, 20, 1)
    local second = fixture.actor(ctx, monsters.MONS_RAT,
        40, 21, 100)

    ctx:add(hydra, component.MONSTER_HYDRA_HEADS, {
        count = 2,
    })
    ctx:add(first, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(second, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    messages = {}

    actions.monster_target(ctx, hydra, first)

    harness.equal(#messages, 2,
        "living hydra redirects its next head to adjacent enemy")
    harness.truthy(ctx:get(second, component.HEALTH).current < 100,
        "retargeted head damages the second monster")
end

-- Player defense stays on its real ECS actor. The round should emit one
-- contact result per Ettin hand while spending only the enclosing action.
local function player_round(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        51, 30, 1000)
    local ettin = fixture.actor(ctx, monsters.MONS_ETTIN,
        50, 30, 100)
    local game = fixture.context(ctx, player)
    local messages = {}

    ctx:set(player, component.HEALTH, {
        current = 1000,
        max = 1000,
    })
    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
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

    function game:random(_, bound)
        return bound - 1
    end

    function game:emit(channel, message)
        if channel == "combat" then
            messages[#messages + 1] = message
        end
    end

    actions.monster(game, ettin)

    harness.equal(#messages, 2,
        "Ettin makes both contacts against player in one action")

    ctx:set(player, component.HEALTH, {
        current = 1,
        max = 1000,
    })
    messages = {}

    actions.monster(game, ettin)

    harness.equal(#messages, 1,
        "player death ends an Ettin round after first contact")

    ctx:set(player, component.HEALTH, {
        current = 1000,
        max = 1000,
    })

    local naga = fixture.actor(ctx, monsters.MONS_NAGA,
        51, 31, 100)

    messages = {}
    actions.monster(game, naga)

    harness.equal(#messages, 2,
        "Naga's second-slot grab is one contact")
    harness.truthy(ctx:has(player, component.CONSTRICTION),
        "Naga grab saves a hold on its surviving target")

    ctx:remove(player, component.CONSTRICTION)

    local anaconda = fixture.actor(ctx,
        monsters.MONS_ANACONDA, 51, 29, 100)
    local anaconda_actor = ctx:get(anaconda, component.ACTOR)

    anaconda_actor.speed = catalog.get("monsters",
        monsters.MONS_ANACONDA).speed
    ctx:set(anaconda, component.ACTOR, anaconda_actor)

    actions.monster(game, anaconda)

    harness.truthy(ctx:has(player, component.CONSTRICTION),
        "first-slot Anaconda constriction saves its hold")

    local before = ctx:get(player, component.HEALTH).current

    constriction_system.update(game, anaconda)

    harness.equal(before - ctx:get(player,
        component.HEALTH).current, 3,
        "Anaconda hold ticks with its constrict slot damage")

    ctx:remove(player, component.CONSTRICTION)
    ctx:set(player, component.HEALTH, {
        current = 1,
        max = 1000,
    })
    game:move_actor(player, 1, 60, 30)

    local hydra = fixture.actor(ctx, monsters.MONS_HYDRA,
        61, 30, 100)
    local second_target = fixture.actor(ctx, monsters.MONS_RAT,
        61, 31, 100)

    ctx:add(hydra, component.MONSTER_HYDRA_HEADS, {
        count = 2,
    })
    ctx:add(second_target, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    actions.monster(game, hydra)

    harness.truthy(ctx:get(second_target,
        component.HEALTH).current < 100,
        "hydra redirects a head after killing the player")
end

-- The observed context gives every monster a real entity and position;
-- production policy reads those components without a test-only schema.
function test.run(ctx)
    local game = fixture.observed_context(ctx)

    sequence_shape(game)
    offhand_weapon(game)
    spawn_heads(game)
    player_round(ctx)
    target_round(game)
end

return test
