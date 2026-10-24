-- Real catalog traits and ECS allegiance decide whether Fedhas shelters a
-- plant. The sparse fixture supplies only the level queries this rule reads.
local attitudes = require("constants.attitude")
local attribution = require("constants.cloud_attribution")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local cloud_exposure = require("policy.clouds.exposure")
local cloud_placement = require("policy.clouds.placement")
local clouds = require("ids.clouds")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local contact_outcomes = require("constants.beam_contact_outcomes")
local beam_resolution = require(
    "policy.combat.monster_beams.resolution")
local beam_blast = require(
    "policy.combat.monster_beams.explosion")
local beam_targeting = require(
    "policy.combat.monster_beams.targeting")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local mephitic = require(
    "policy.combat.monster_spells.mephitic_cloud")
local protection = require("policy.religion.fedhas.protection")
local flame = require("policy.magic.effects.zaps.flame")
local player_zap = require("policy.magic.effects.zaps.projectile")
local spells = require("ids.spells")
local target_kind = require("constants.target_kind")

local test = {}

-- Give the source passive a real worshipper and a nonstationary plant.
-- Protection uses plant holiness, while walking through plants also needs
-- stationary status; these two rules must remain separate.
local function actors(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 20,
        y = 20,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.FEDHAS,
        piety = 0,
        penance = {},
    })

    local plant = fixture.actor(ctx, monsters.MONS_SNAPLASHER_VINE,
        21, 20, 60)
    ctx:add(plant, component.FEDHAS_PLANT, {
        attitude = attitudes.GOOD_NEUTRAL,
        attempted = true,
    })

    return game, player, plant
end

-- The player's allegiance, current penance, and the actual monster kind
-- are read for every shot, so a saved or modded plant does not carry a
-- stale immunity flag.
function test.run(ctx)
    local game, player, plant = actors(ctx)

    harness.truthy(protection.ignores(game, player, plant))

    local worship = game:get(player, component.RELIGION_WORSHIP)

    worship.penance[gods.FEDHAS] = 1
    game:set(player, component.RELIGION_WORSHIP, worship)
    harness.falsy(protection.ignores(game, player, plant))

    worship.penance[gods.FEDHAS] = 0
    game:set(player, component.RELIGION_WORSHIP, worship)

    local state = game:get(plant, component.FEDHAS_PLANT)

    state.attitude = attitudes.HOSTILE
    state.attempted = false
    game:set(plant, component.FEDHAS_PLANT, state)
    harness.falsy(protection.ignores(game, player, plant))

    local actor = game:get(plant, component.ACTOR)

    actor.kind_id = monsters.MONS_OKLOB_SAPLING
    game:set(plant, component.ACTOR, actor)
    harness.falsy(protection.ignores(game, player, plant))

    actor.kind_id = monsters.MONS_SNAPLASHER_VINE
    game:set(plant, component.ACTOR, actor)

    state.attitude = attitudes.GOOD_NEUTRAL
    state.attempted = true
    game:set(plant, component.FEDHAS_PLANT, state)

    local hostile = ctx:create()

    ctx:add(hostile, component.ACTOR, {
        kind_id = monsters.MONS_OGRE,
        speed = 10,
    })
    harness.falsy(protection.ignores(game, hostile, plant))

    local ally = fixture.actor(ctx, monsters.MONS_SNAPLASHER_VINE,
        20, 20, 60)
    ctx:add(ally, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    harness.truthy(protection.ignores(game, ally, plant))

    game:set(ally, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.GOOD_NEUTRAL,
    })
    harness.falsy(protection.ignores(game, ally, plant),
        "a good-neutral caster is not a friendly monster")
    game:set(ally, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    actor.kind_id = monsters.MONS_OGRE
    game:set(plant, component.ACTOR, actor)
    harness.falsy(protection.ignores(game, player, plant))

    actor.kind_id = monsters.MONS_SNAPLASHER_VINE
    game:set(plant, component.ACTOR, actor)

    local profile = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_THROW_FLAME)
    local outcome = contact.resolve(game, player, plant, profile,
        30, 20)

    harness.equal(outcome.kind, contact_outcomes.PASS)
    harness.equal(game:get(plant, component.HEALTH).current, 60)

    -- The player spell ray has its own contact owner. A guaranteed low
    -- roll would damage the vine if it were still treated as a target.
    function game:random()
        return 0
    end

    player_zap.fire(game, player, { dx = 1, dy = 0 }, nil,
        flame.spec, 30, 1)
    harness.equal(game:get(plant, component.HEALTH).current, 60)

    -- Custom monster beam hooks own their hit effect. The shared beam
    -- runner must bypass this hook for the protected plant while still
    -- reaching the enemy beyond it.
    local foe = fixture.actor(ctx, monsters.MONS_OGRE,
        22, 20, 60)
    local beam = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_ENERGY_BOLT)
    local touched = {}

    harness.truthy(beam_targeting.plan(game, ally, foe, beam, {}),
        "allied caster can plan through a protected plant")

    beam_resolution.resolve(game, ally, foe, beam, {
        kind = target_kind.ENTITY,
        entity = foe,
        dx = 2,
        dy = 0,
    }, {
        contact = function(_, _, defender)
            touched[#touched + 1] = defender

            return { kind = "hit" }
        end,
    })

    harness.equal(#touched, 1)
    harness.equal(touched[1], foe)

    -- A source area ray passes the plant before bursting at its foe.
    -- Both the ordinary explosion and Mephitic Cloud need that endpoint.
    local first_blast_cell
    local fireball = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_FIREBALL)

    beam_blast.resolve(game, ally, fireball, {
        contacts = {
            { actor = plant, x = 21, y = 20 },
            { actor = foe, x = 22, y = 20 },
        },
        x = 22,
        y = 20,
    }, {
        level_id = 1,
        x = 22,
        y = 20,
    }, 30, 20, {
        after_cell = function(_, _, _, cell)
            first_blast_cell = first_blast_cell or cell
        end,
    })
    harness.equal(first_blast_cell.x, 22)

    function game:random(_, bound)
        return bound - 1
    end

    game:set(foe, component.POSITION, {
        level_id = 1,
        x = 23,
        y = 20,
    })
    mephitic.resolve(game, ally, foe, nil, {
        kind = target_kind.CELL,
        level_id = 1,
        x = 23,
        y = 20,
    })
    harness.truthy(cloud_placement.at(game, 1, 23, 20),
        "Mephitic Cloud bursts at the hostile target")

    local plant_cloud = cloud_placement.at(game, 1, 21, 20)

    if plant_cloud then
        cloud_placement.remove(game, plant_cloud)
    end

    -- A player-owned harmful cloud cannot be placed atop the plant. A
    -- restored friendly cloud also skips exposure, even after its source
    -- actor vanishes. The saved kill category owns that source relation.
    local placed = cloud_placement.place(game, clouds.CLOUD_FIRE,
        player, 1, 21, 20, 20)

    harness.falsy(placed)

    -- Poison gas can occupy an Oklob plant's cell because that monster
    -- already resists its effect. Fedhas need not veto an immune cloud.
    actor.kind_id = monsters.MONS_OKLOB_PLANT
    game:set(plant, component.ACTOR, actor)
    local poison_cloud = cloud_placement.place(game,
        clouds.CLOUD_POISON, player, 1, 21, 20, 20)

    harness.truthy(poison_cloud)
    cloud_placement.remove(game, poison_cloud)
    actor.kind_id = monsters.MONS_SNAPLASHER_VINE
    game:set(plant, component.ACTOR, actor)

    local cloud = {
        kind_id = clouds.CLOUD_FIRE,
        level_id = 1,
        x = 21,
        y = 20,
        decay_aut = 20,
        source_actor_id = game:id(player),
        kill_category = attribution.PLAYER,
    }
    local protected = cloud_exposure.apply(game, plant,
        nil, cloud, 10)

    harness.equal(protected, 0)
    harness.equal(game:get(plant, component.HEALTH).current, 60)

    cloud.source_actor_id = 0

    local orphaned = cloud_exposure.apply(game, plant,
        nil, cloud, 10)

    harness.equal(orphaned, 0)

    cloud.kill_category = attribution.OTHER

    local unowned = cloud_exposure.apply(game, plant,
        nil, cloud, 10)

    harness.truthy(unowned > 0)
end

return test
