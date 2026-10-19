-- A Black Mark spell saves its recipient's timer, and the monster melee
-- consumer calls the same weak-status owner used by other enchantments.
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.fixtures.monster_status")
local harness = require("tests.harness")
local mark = require("policy.combat.monster_black_mark")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- An allied orc receives the mark; a subsequent surviving hit weakens an
-- unmarked goblin, and the timer ends after enough of the orc's action aut.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {})

    local caster = fixture.actor(ctx,
        monsters.MONS_DEEP_ELF_HIGH_PRIEST, 1, 1, 30)
    local ally = fixture.actor(ctx,
        monsters.MONS_ORC_WARRIOR, 2, 1, 25)
    local victim = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 3, 1, 10)
    local live = fixture.context(ctx, player, 100)
    local effect = effects.effect(spells.SPELL_BLACK_MARK)
    local plan = effect.plan(live, caster, player)

    harness.truthy(plan, "an unmarked melee ally makes the cast useful")

    effect.resolve(live, caster, player, nil, plan)

    local state = ctx:get(ally, component.MONSTER_BLACK_MARK)

    harness.truthy(state and state.remaining_aut > 0,
        "the ally owns a saved Black Mark timer")
    harness.falsy(ctx:has(caster, component.MONSTER_BLACK_MARK),
        "the caster does not mark itself")

    local zero_damage = setmetatable({}, { __index = live })

    -- A zero-damage contact must not draw an effect; the source calls the
    -- mark consumer only after actual melee damage.
    function zero_damage:random()
        error("zero-damage mark consumed a random effect draw")
    end

    mark.after_melee(zero_damage, ally, victim, 0)
    mark.after_melee(live, ally, victim, 5)

    local weak = ctx:get(victim, component.MONSTER_ENFEEBLE)

    harness.truthy(weak and weak.weak_aut > 0,
        "a marked monster can inflict shared Weakness")

    mark.tick(live, ally, state.remaining_aut)

    harness.falsy(mark.active(live, ally),
        "the saved proc stops when its timer expires")

    local hidden = setmetatable({}, { __index = live })

    -- This fixture has no player position, so no marked ally can be seen.
    -- The spell may still mark one without leaking a visual message.
    function hidden:emit()
        error("unseen Black Mark ally emitted a visual message")
    end

    effect.resolve(hidden, caster, player, nil, plan)
end

return test
