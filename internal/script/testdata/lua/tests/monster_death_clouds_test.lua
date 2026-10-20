-- Source monster deaths and summon dismissals leave clouds according to
-- their actual species and summon source. These checks run the ECS death
-- owner and the shared summon teardown on the same fixture as combat tests.
local cloud_ids = require("ids.clouds")
local clouds = require("policy.clouds.placement")
local component = require("constants.component")
local death = require("systems.actor_death")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local save_clouds = require("policy.save.clouds")
local spells = require("ids.spells")
local summons = require("policy.magic.effects.summons.common")

local test = {}

-- Supply the ECS fields the death owner reads, while the fixture keeps a
-- simple walkable grid so clouds can be inspected at exact cells.
local function actor(ctx, kind_id, x, health)
    local entity = fixture.actor(ctx, kind_id, x, 10, health)

    ctx:add(entity, component.COMBAT, {
        shield_blocks = 0,
    })

    return entity
end

-- Death and summon rules share one live context and deterministic cloud
-- draws. A real player entity is needed for cloud attribution and sight.
local function world(ctx)
    local player = actor(ctx, monsters.MONS_HUMAN, 60, 100)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})
    game.draws = {}

    function game:random(_, bound)
        harness.truthy(bound > 0, "invalid cloud draw")
        self.draws[#self.draws + 1] = bound

        return 0
    end

    return game, player
end

-- Read the actual world-cloud ECS component instead of substituting a
-- fake placement function, so the test covers its saved cloud identity.
local function cloud_kind(ctx, game, x)
    local entity = clouds.at(game, 1, x, 10)
    local state = entity and ctx:get(entity, component.WORLD_CLOUD)

    return state and state.kind_id
end

-- Kill a creature through the ordinary death system; its cloud hook must
-- run before the actor entity disappears from the world.
local function kill(ctx, game, entity)
    local health = ctx:get(entity, component.HEALTH)

    health.current = 0
    ctx:set(entity, component.HEALTH, health)
    death.update(game)
end

-- Fire vortices and simulacra have species-specific clouds even without
-- a summon component. Chaos spawn always leave primal chaos behind.
local function intrinsic_clouds(ctx, game)
    local cases = {
        {
            kind_id = monsters.MONS_FIRE_VORTEX,
            x = 5,
            cloud_id = cloud_ids.CLOUD_FIRE,
        },
        {
            kind_id = monsters.MONS_SIMULACRUM,
            x = 10,
            cloud_id = cloud_ids.CLOUD_COLD,
        },
        {
            kind_id = monsters.MONS_SIMULACRUM_SMALL,
            x = 11,
            cloud_id = cloud_ids.CLOUD_COLD,
        },
        {
            kind_id = monsters.MONS_SIMULACRUM_LARGE,
            x = 12,
            cloud_id = cloud_ids.CLOUD_COLD,
        },
        {
            kind_id = monsters.MONS_CHAOS_SPAWN,
            x = 15,
            cloud_id = cloud_ids.CLOUD_CHAOS,
        },
    }

    for _, case in ipairs(cases) do
        local dying = actor(ctx, case.kind_id, case.x, 20)

        kill(ctx, game, dying)
        harness.equal(cloud_kind(ctx, game, case.x), case.cloud_id,
            case.kind_id .. " death cloud")
    end
end

-- Ordinary summons poof into random smoke on dismissal; source shadows,
-- holy beings, and living spells have a visible exit without a cloud.
local function summon_clouds(ctx, game, player)
    local cases = {
        {
            kind_id = monsters.MONS_RAT,
            source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
            x = 20,
            cloud_id = cloud_ids.CLOUD_GREY_SMOKE,
            verify_draws = true,
        },
        {
            kind_id = monsters.MONS_RAT,
            source_id = spells.SPELL_SHADOW_CREATURES,
            x = 25,
        },
        {
            kind_id = monsters.MONS_RAT,
            source_id = items.SCR_SUMMONING,
            x = 28,
        },
        {
            kind_id = monsters.MONS_RAT,
            source_id = spells.SPELL_SPECTRAL_CLOUD,
            x = 29,
        },
        {
            kind_id = monsters.MONS_ANGEL,
            source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
            x = 30,
        },
        {
            kind_id = monsters.MONS_LIVING_SPELL,
            source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
            x = 35,
        },
        {
            kind_id = monsters.MONS_DROWNED_SOUL,
            source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
            x = 36,
        },
        {
            kind_id = monsters.MONS_RAT,
            source_id = spells.SPELL_PHANTOM_MIRROR,
            x = 37,
            mirrored = true,
        },
        {
            kind_id = monsters.MONS_SIMULACRUM,
            source_id = spells.SPELL_SIMULACRUM,
            x = 40,
            cloud_id = cloud_ids.CLOUD_COLD,
        },
    }

    for _, case in ipairs(cases) do
        local summoned = actor(ctx, case.kind_id, case.x, 20)

        game.draws = {}
        ctx:add(summoned, component.SUMMON, {
            owner = player,
            source_id = case.source_id,
            expires_aut = 20,
        })

        if case.mirrored then
            ctx:add(summoned, component.SUMMON_MIRROR, {
                origin_kind_id = monsters.MONS_RAT,
                origin_entity_id = "test-rat",
                hp_percent = 50,
            })
        end

        summons.expire(game, summoned)

        harness.equal(cloud_kind(ctx, game, case.x), case.cloud_id,
            case.kind_id .. " summon cloud")

        if case.verify_draws then
            harness.equal(game.draws[1], 4,
                "smoke kind must be drawn before duration")
            harness.equal(game.draws[2], 3,
                "smoke duration must follow its kind")
        end
    end
end

-- Both lifecycle paths must agree so killing and dismissing the same
-- species do not leave different elemental terrain behind.
function test.run(ctx)
    local game, player = world(ctx)

    intrinsic_clouds(ctx, game)
    summon_clouds(ctx, game, player)
    save_clouds.validate(game)
end

return test
