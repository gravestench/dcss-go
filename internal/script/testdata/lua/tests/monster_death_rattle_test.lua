-- Death Rattle must hurt along its ray and leave separate miasma clouds in
-- every traversed cell. The test uses the production beam and cloud owners.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local clouds = require("ids.clouds")
local effects = require("policy.combat.monster_spells")

local test = {}

-- Source foe_ratio 30 permits an allied ray contact when enough hostile
-- power lies behind it, while a weak foe cannot justify the friendly hit.
local function weighted_targeting(ctx, game, effect)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_WIZARD,
        20, 20)
    local ally = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        21, 20)
    local strong = fixture.actor(ctx, monsters.MONS_ORC_WARLORD,
        23, 20)

    for _, entity in ipairs({ caster, ally }) do
        ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
            attitude = attitudes.FRIENDLY,
        })
    end

    harness.truthy(effect.plan(game, caster, strong),
        "strong foe makes an allied contact worth a Death Rattle cast")

    local weak_caster = fixture.actor(ctx, monsters.MONS_ORC_WIZARD,
        20, 30)
    local weak_ally = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        21, 30)
    local weak_foe = fixture.actor(ctx, monsters.MONS_RAT,
        23, 30)

    for _, entity in ipairs({ weak_caster, weak_ally }) do
        ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
            attitude = attitudes.FRIENDLY,
        })
    end

    harness.falsy(effect.plan(game, weak_caster, weak_foe),
        "a weak foe cannot justify damaging an allied monster")
end

-- A deterministic live ECS cast proves the spell leaves one trail cloud
-- per ray cell, including the cell occupied by its defender.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_WIZARD,
        3, 3, 100)
    local target = fixture.actor(ctx, monsters.MONS_RAT,
        5, 3, 100)

    ctx:add(caster, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(target, component.COMBAT, {
        shield_blocks = 0,
    })

    function game:random()
        return 0
    end

    local effect = effects.effect(spells.SPELL_DEATH_RATTLE)
    local plan = effect.plan(game, caster, target)

    harness.truthy(plan, "Death Rattle plans a clear ray")
    effect.resolve(game, caster, target, nil, plan)

    harness.truthy(ctx:get(target, component.HEALTH).current < 100,
        "Death Rattle deals direct damage")

    local found = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local cloud = ctx:get(entity, component.WORLD_CLOUD)

        if cloud.kind_id == clouds.CLOUD_MIASMA then
            found[cloud.x .. ":" .. cloud.y] = cloud.decay_aut
        end
    end

    harness.equal(found["4:3"], 40,
        "the first ray cell receives a four-turn miasma cloud")
    harness.equal(found["5:3"], 40,
        "the defender's cell receives its own miasma cloud")

    weighted_targeting(ctx, game, effect)
end

return test
