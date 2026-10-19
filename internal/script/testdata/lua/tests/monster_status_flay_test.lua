-- Flay tests the production spell, health, saved wound, and release owners
-- together so expiry cannot accidentally heal a raw, unmitigated roll.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.fixtures.monster_status")
local flay = require("policy.combat.monster_flay")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- A hostile ghost flays a natural friendly monster. Hidden expiry and
-- ghost death both restore no more than the actually missing HP.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {})

    local ghost = fixture.actor(ctx,
        monsters.MONS_FLAYED_GHOST, 1, 1, 30)
    local victim = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 2, 1, 20)

    ctx:add(victim, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 200,
    })

    local live = fixture.context(ctx, player, 0)
    local effect = effects.effect(spells.SPELL_FLAY)
    local plan = effect.plan(live, ghost, victim)

    harness.truthy(plan, "a natural foe can be flayed")

    effect.resolve(live, ghost, victim, nil, plan)

    local wound = ctx:get(victim, component.MONSTER_FLAYED)

    harness.equal(wound.recoverable_hp, 4,
        "the first cast stores four points of actual HP loss")
    harness.equal(ctx:get(victim, component.HEALTH).current, 16,
        "the ordinary health owner receives the flay hit")

    local saved_aut = wound.remaining_aut

    flay.tick(live, victim, 10)

    harness.equal(ctx:get(victim,
        component.MONSTER_FLAYED).remaining_aut, saved_aut,
        "a visible hostile ghost suspends wound decay")

    local hidden = setmetatable({}, { __index = live })

    -- The spell plan used ordinary sight; this later turn has no ghost in
    -- sight, so the same saved wound can expire without a new cast.
    function hidden:visible()
        return false
    end

    flay.tick(hidden, victim, saved_aut)

    harness.falsy(ctx:has(victim, component.MONSTER_FLAYED),
        "expiry removes the saved condition")
    harness.equal(ctx:get(victim, component.HEALTH).current, 20,
        "expiry returns the four lost points")

    effect.resolve(live, ghost, victim, nil, plan)

    local health = ctx:get(victim, component.HEALTH)

    health.current = 19
    ctx:set(victim, component.HEALTH, health)

    flay.release_for_ghost(live, ghost)

    harness.falsy(ctx:has(victim, component.MONSTER_FLAYED),
        "ghost death releases a nonaligned victim")
    harness.equal(ctx:get(victim, component.HEALTH).current, 20,
        "later ordinary healing caps the flay recovery")
end

return test
