-- Holy Flames fills only eligible cells around the selected foe, preserving
-- preexisting cloud state and monster occupancy.
local clouds = require("ids.clouds")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local placement = require("policy.clouds.placement")
local spells = require("ids.spells")

local test = {}

-- Source cloud duration uses the caster's HD while walls, monsters and existing
-- clouds remove individual ring cells without cancelling the whole cast.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 7, 5, 50)
    local caster = fixture.actor(ctx, monsters.MONS_OPHAN, 2, 5, 30)
    local blocker = fixture.actor(ctx, monsters.MONS_GOBLIN, 8, 5, 10)
    local game = fixture.context(ctx, player)
    local effect = effects.effect(spells.SPELL_HOLY_FLAMES)

    ctx:add(player, component.PLAYER, {})
    game.walls["6:4"] = true

    function game:random()
        return 0
    end

    local previous = placement.place(game, clouds.CLOUD_FIRE,
        caster, 1, 7, 4, 90)

    harness.truthy(previous, "test has a preexisting cloud")

    local plan = effect.plan(game, caster, player)

    harness.truthy(plan, "visible foe permits a holy flame ring")
    effect.resolve(game, caster, player, nil, plan)

    local holy = 0

    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local cloud = ctx:get(entity, component.WORLD_CLOUD)

        if cloud.kind_id == clouds.CLOUD_HOLY then
            holy = holy + 1

            harness.equal(cloud.decay_aut, 80,
                "zero duration rolls leave eight source turns")
        end
    end

    harness.equal(holy, 5,
        "holy ring excludes wall, existing cloud and occupied cell")
    harness.equal(ctx:get(previous, component.WORLD_CLOUD).kind_id,
        clouds.CLOUD_FIRE, "existing cloud is unchanged")
    harness.truthy(ctx:has(blocker, component.ACTOR),
        "the occupied actor remains in its cell")
end

return test
