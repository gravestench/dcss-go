-- Abjuration changes the production summon lifetime rather than deleting an
-- actor itself; the shared expiry system performs the later teardown.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.fixtures.monster_status")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")

local test = {}

-- A hostile caster shortens only enemy summons in sight. Each recipient
-- draws its own fuzz, so identical summon lifetimes may diverge.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {})

    local caster = fixture.actor(ctx,
        monsters.MONS_ORC_SORCERER, 1, 1, 30)
    local enemy = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 3, 1, 10)
    local ally = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 2, 1, 10)
    local second = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 4, 1, 10)
    local third = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 5, 1, 10)

    ctx:add(enemy, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 140,
    })
    ctx:add(ally, component.SUMMON, {
        owner = caster,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.HOSTILE,
        expires_aut = 140,
    })
    ctx:add(second, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 300,
    })
    ctx:add(third, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 300,
    })

    local live = fixture.context(ctx, player, 100)
    local draws = 0

    -- Give the later victim upper-bound draws. A single cast-wide roll
    -- would leave the equal initial lifetimes equal after abjuration.
    function live:random(_, bound)
        draws = draws + 1

        if draws <= 4 then
            return 0
        end

        return bound - 1
    end

    local effect = effects.effect(spells.SPELL_ABJURATION)
    local plan = effect.plan(live, caster, player)

    harness.truthy(plan, "enemy summon makes Abjuration useful")

    effect.resolve(live, caster, player, nil, plan)

    harness.truthy(ctx:get(enemy, component.SUMMON).expires_aut <= 100,
        "Abjuration makes the enemy summon expire at the next barrier")
    harness.equal(ctx:get(ally, component.SUMMON).expires_aut, 140,
        "aligned summons are not abjured")
    harness.truthy(ctx:get(second, component.SUMMON).expires_aut ~=
        ctx:get(third, component.SUMMON).expires_aut,
        "each enemy summon receives an independent fuzz roll")
end

return test
