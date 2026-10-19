local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local recall = require("policy.combat.monster_displacement.recall")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")

local test = {}

-- The source spell waits three ordinary actions before moving distant,
-- intelligent allies. The saved component must own both waiting phases.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 0, 0)
    local game = fixture.context(ctx, player)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_SORCERER,
        100, 100)
    local followers = {}

    for index = 1, 3 do
        followers[index] = fixture.actor(ctx,
            monsters.MONS_ORC_WARRIOR, 130 + index, 100)
    end

    ctx:add(followers[1], component.AI, {
        behavior = "wander",
    })

    game.visible = function(_, _, from_x, from_y, _, x, y)
        return math.max(math.abs(x - from_x),
            math.abs(y - from_y)) <= 7
    end
    game.random = function(_, _, bound)
        return 0
    end

    harness.equal(#recall.candidates(game, caster), 3,
        "distant intelligent allies can answer")

    local effect = effects.effect(spells.SPELL_WORD_OF_RECALL)
    local plan = effect.plan(game, caster, player, nil)

    harness.truthy(plan, "three distant allies justify the cast")
    effect.resolve(game, caster, player, nil, plan)

    local state = ctx:get(caster, component.MONSTER_RECALL)

    harness.equal(state.chant_aut, 30, "chant is saved on caster")
    harness.equal(state.foe, player,
        "the selected foe survives the chant boundary")
    recall.tick(game, caster, 20)
    harness.equal(ctx:get(caster, component.MONSTER_RECALL).chant_aut,
        10, "chant counts elapsed aut")
    harness.equal(ctx:get(followers[1], component.POSITION).x,
        131, "followers wait for the full chant")

    recall.tick(game, caster, 10)

    state = ctx:get(caster, component.MONSTER_RECALL)
    harness.equal(state.chant_aut, 0, "chant completes")
    harness.equal(state.breath_aut, 40, "source minimum breath cooldown")

    for _, follower in ipairs(followers) do
        local position = ctx:get(follower, component.POSITION)

        harness.truthy(math.max(math.abs(position.x - 100),
            math.abs(position.y - 100)) <= 3,
            "follower moved beside caster")
    end

    local ai = ctx:get(followers[1], component.AI)

    harness.equal(ai.behavior, "seek",
        "recalled ally resumes pursuit")
    harness.equal(ai.target_x, 0,
        "recalled ally seeks the caster's foe")

    harness.falsy(effect.plan(game, caster, player, nil),
        "cooldown prevents another chant")
    recall.tick(game, caster, 40)
    harness.truthy(effect.plan(game, caster, player, nil) == nil,
        "nearby followers make recall unnecessary")

    -- A fresh eligible cast interrupted by silence leaves no pending
    -- recall, so save/restore cannot revive an obsolete chant.
    for index, follower in ipairs(followers) do
        ctx:set(follower, component.POSITION, {
            level_id = 1,
            x = 140 + index,
            y = 100,
        })
    end

    harness.truthy(effect.plan(game, caster, player, nil),
        "followers are distant again")
    effect.resolve(game, caster, player, nil, plan)
    ctx:add(caster, component.MONSTER_MUTE, {
        remaining_aut = 20,
    })

    local messages = {}

    game.emit = function(_, _, message)
        messages[#messages + 1] = message
    end

    recall.tick(game, caster, 10)
    harness.falsy(ctx:has(caster, component.MONSTER_RECALL),
        "silence interrupts and clears saved chant")
    harness.equal(#messages, 0,
        "an unseen interruption does not reveal the caster")
end

return test
