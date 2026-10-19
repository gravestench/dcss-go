-- The wall test invokes production geometry and summon expiry. Its sparse
-- fixture supplies floor cells while real ECS components hold each patch.
local component = require("constants.component")
local attitudes = require("constants.attitude")
local brambles = require("policy.combat.monster_plants.brambles")
local effects = require("policy.combat.monster_spells")
local expiry = require("systems.magic_summon_expiry")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- An adjacent foe makes a defensive wall useless; a more distant foe
-- causes real briar actors with individually saved source lifetimes.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 5, 1, 40)
    local caster = fixture.actor(ctx,
        monsters.MONS_THORN_HUNTER, 1, 1, 40)
    local game = fixture.context(ctx, player)
    local effect = effects.effect(spells.SPELL_WALL_OF_BRAMBLES)

    ctx:add(player, component.PLAYER, {})

    function game:random()
        return 0
    end

    local plan = effect.plan(game, caster, player)

    harness.truthy(plan, "a distant foe permits a legal wall arc")
    effect.resolve(game, caster, player, nil, plan)

    local patches = {}

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local actor = ctx:get(entity, component.ACTOR)

        if actor.kind_id == monsters.MONS_BRIAR_PATCH then
            patches[#patches + 1] = entity
            local summon = ctx:get(entity, component.SUMMON)

            harness.equal(summon.owner, caster,
                "a patch keeps the thorn hunter as owner")
            harness.equal(summon.expires_aut, 80,
                "zero duration roll produces source minimum lifetime")
        end
    end

    harness.truthy(#patches > 1,
        "the arc contains multiple physical briar actors")

    local attacker = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 4, 4, 30)

    ctx:add(attacker, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 500,
    })

    local before = ctx:get(attacker, component.HEALTH).current

    harness.truthy(brambles.thorns(game, attacker, patches[1], false),
        "unblocked physical contact can trigger source thorns")
    harness.truthy(ctx:get(attacker, component.HEALTH).current < before,
        "the thorns deal armour-checked retaliation damage")

    function game:aut()
        return 80
    end

    expiry.update(game, player)

    for _, patch in ipairs(patches) do
        harness.falsy(ctx:has(patch, component.ACTOR),
            "expiry removes the patch's physical obstruction")
    end
end

return test
