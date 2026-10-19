-- Bind Souls marks only living, natural, corpse-bearing allies. The saved
-- mark later turns a marked body into a simulacrum on the death-hook path.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local death_hooks = require("policy.combat.death_hooks")
local saved_summons = require("policy.save.summons")

local test = {}

-- Exercise the real ECS mark and death hook so a reload can preserve the
-- expiry and turn the fallen ally into the expected derived undead body.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_SORCERER,
        3, 3)
    local ally = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        4, 3)
    local enemy = fixture.actor(ctx, monsters.MONS_RAT,
        5, 3)
    local undead = fixture.actor(ctx, monsters.MONS_WRAITH,
        4, 4)
    local slime = fixture.actor(ctx, monsters.MONS_SLIME_CREATURE,
        3, 4)

    for _, entity in ipairs({ caster, ally, undead, slime }) do
        ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
            attitude = attitudes.FRIENDLY,
        })
    end

    function game:random()
        return 0
    end

    local effect = effects.effect(spells.SPELL_BIND_SOULS)
    local plan = effect.plan(game, caster)

    harness.truthy(plan, "Bind Souls sees a suitable ally")
    effect.resolve(game, caster, nil, nil, plan)

    local mark = ctx:get(ally, component.MONSTER_BOUND_SOUL)

    harness.truthy(mark, "the natural ally receives a saved soul mark")
    harness.equal(mark.expires_aut, 100,
        "minimum source soul binding lasts ten turns")
    harness.falsy(ctx:has(enemy, component.MONSTER_BOUND_SOUL),
        "enemy receives no mark")
    harness.falsy(ctx:has(undead, component.MONSTER_BOUND_SOUL),
        "undead ally receives no mark")
    harness.truthy(ctx:has(slime, component.MONSTER_BOUND_SOUL),
        "natural slime can be bound despite leaving no ordinary corpse")

    -- Source SAME_ATTITUDE reads the monster at death, not at marking.
    ctx:set(ally, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.HOSTILE,
    })

    local position = ctx:get(ally, component.POSITION)

    game:remove_actor(ally)

    local consumed = death_hooks.run(game, ally,
        require("policy.catalog").get("monsters",
            monsters.MONS_ORC_WARRIOR), position, true)

    harness.truthy(consumed, "the marked death consumes the corpse")

    local raised = nil

    for _, entity in ipairs(ctx:query({ component.SUMMON_UNDEAD })) do
        local actor = ctx:get(entity, component.ACTOR)

        if actor.kind_id == monsters.MONS_SIMULACRUM then
            raised = entity
        end
    end

    harness.truthy(raised, "a marked ally rises as a simulacrum")
    harness.equal(ctx:get(raised, component.SUMMON_UNDEAD).base_kind_id,
        monsters.MONS_ORC_WARRIOR,
        "the simulacrum retains its base monster kind")
    harness.equal(ctx:get(raised, component.SUMMON).attitude,
        attitudes.HOSTILE,
        "the simulacrum takes the victim's attitude at death")
    harness.equal(ctx:get(raised, component.SUMMON).owner,
        game:player(),
        "the permanent simulacrum survives its original caster's death")

    ctx:add(game:player(), component.ACTOR, {
        kind_id = monsters.MONS_HUMAN,
        speed = 10,
    })

    local saved_ai = ctx:get(raised, component.AI)

    -- The host AI store supplies these zeros when decoding a real save;
    -- the focused Lua runner exposes only fields written by the spell.
    saved_ai.target_x = saved_ai.target_x or 0
    saved_ai.target_y = saved_ai.target_y or 0
    saved_ai.memory_until_aut = saved_ai.memory_until_aut or 0

    saved_summons.validate(game, raised,
        ctx:get(raised, component.ACTOR),
        ctx:get(raised, component.POSITION),
        saved_ai,
        ctx:get(raised, component.SUMMON), 0)
end

return test
