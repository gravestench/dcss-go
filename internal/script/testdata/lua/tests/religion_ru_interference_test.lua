-- Ru's one-star aura acts before contact or spell planning. These cases
-- use production monster definitions and ECS schemas with a sparse floor.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local interference = require("policy.religion.ru.interference")
local kinds = require("constants.ru_interference")
local monsters = require("ids.monsters")
local spell = require("policy.ai.spell")
local intents = require("constants.intent")
local targets = require("policy.ai.targets")

local test = {}

-- Give the policy a player, an adjacent hostile attacker, and real
-- worship state; each test changes only the condition it needs to pin.
local function case_at(ctx, x, piety, kind_id)
    local player = ctx:create()
    local game = fixture.context(ctx, player)
    local attacker = fixture.actor(ctx,
        kind_id or monsters.MONS_ORC, x + 1, 5, 100)

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = x,
        y = 5,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = piety,
    })

    return game, player, attacker
end

-- Record only the bounds that the source would actually draw. A failed
-- eligibility check must leave the religion stream untouched.
local function record(game, values)
    local bounds = {}

    function game:random(_, bound)
        bounds[#bounds + 1] = bound

        return values[#bounds] or 0
    end

    return bounds
end

-- Pin the block and redirect thresholds, source candidate order, and
-- live passive gates before any combat owner invokes this policy.
function test.run(ctx)
    local blocked, _, blocker = case_at(ctx, 5, 160)
    local blocked_bounds = record(blocked, {0})
    local result = interference.choose(blocked, blocker, kinds.MELEE)

    harness.equal(result.kind, kinds.BLOCK)
    harness.equal(#blocked_bounds, 1)
    harness.equal(blocked_bounds[1], 100)

    local redirected, _, attacker = case_at(ctx, 12, 160)
    local target = fixture.actor(ctx,
        monsters.MONS_ORC, 13, 6, 100)
    local redirect_bounds = record(redirected, {12, 0})

    result = interference.choose(redirected, attacker, kinds.MELEE)
    harness.equal(result.kind, kinds.REDIRECT)
    harness.equal(result.target, target)
    harness.equal(#redirect_bounds, 2)
    harness.equal(redirect_bounds[1], 100)
    harness.equal(redirect_bounds[2], 2)
    harness.truthy(not targets.enemy(redirected, attacker, target))

    interference.force_target(ctx, attacker, target)
    harness.truthy(targets.enemy(redirected, attacker, target))
    interference.clear_target(ctx, attacker)
    harness.truthy(not targets.enemy(redirected, attacker, target))

    -- The source's adjacent iterator includes the attacker itself. With
    -- no other monster, a redirected melee action strikes its own body.
    local self, _, self_attacker = case_at(ctx, 20, 160)
    record(self, {12})

    result = interference.choose(self, self_attacker, kinds.MELEE)
    harness.equal(result.target, self_attacker)

    interference.force_target(ctx, self_attacker, self_attacker)
    harness.truthy(targets.enemy(self, self_attacker, self_attacker))
    interference.clear_target(ctx, self_attacker)

    -- The first chance rounding draw precedes the half-chance rounding;
    -- neither is drawn on a successful block.
    local rounded, _, rounded_attacker = case_at(ctx, 28, 143)
    local rounded_bounds = record(rounded, {12, 0, 0})

    result = interference.choose(rounded,
        rounded_attacker, kinds.MELEE)
    harness.equal(result.kind, kinds.REDIRECT)
    harness.equal(rounded_bounds[1], 100)
    harness.equal(rounded_bounds[2], 16)
    harness.equal(rounded_bounds[3], 2)

    -- Transparent-wall sight and current penance both remove the passive
    -- before any roll, even when an attack intent already exists.
    local gated, player, gated_attacker = case_at(ctx, 36, 160)
    local gated_bounds = record(gated, {})

    function gated:visible_no_trans()
        return false
    end

    result = interference.choose(gated,
        gated_attacker, kinds.MELEE)
    harness.equal(result.kind, kinds.NONE)
    harness.equal(#gated_bounds, 0)

    function gated:visible_no_trans()
        return true
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.penance[gods.RU] = 1
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    result = interference.choose(gated,
        gated_attacker, kinds.MELEE)
    harness.equal(result.kind, kinds.NONE)
    harness.equal(#gated_bounds, 0)

    worship.penance[gods.RU] = 0
    worship.piety = 29
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    result = interference.choose(gated,
        gated_attacker, kinds.MELEE)
    harness.equal(result.kind, kinds.NONE)
    harness.equal(#gated_bounds, 0)

    -- A friendly attacker is ineligible even if another source assigned
    -- it a hostile-looking attack intent against the player.
    local friendly, _, ally = case_at(ctx, 44, 160)
    local friendly_bounds = record(friendly, {})

    ctx:add(ally, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    result = interference.choose(friendly, ally, kinds.MELEE)
    harness.equal(result.kind, kinds.NONE)
    harness.equal(#friendly_bounds, 0)

    -- A submerged attacker and inert bodies never draw from Ru's stream.
    -- These exclusions apply before a candidate scan or attack message.
    local submerged, _, swimmer = case_at(ctx, 48, 160)
    local submerged_bounds = record(submerged, {})

    ctx:add(swimmer, component.MONSTER_SUBMERGED, {
        active = true,
    })

    result = interference.choose(submerged, swimmer, kinds.MELEE)
    harness.equal(result.kind, kinds.NONE)
    harness.equal(#submerged_bounds, 0)

    for _, kind_id in ipairs({
        monsters.MONS_TOADSTOOL,
        monsters.MONS_ORB_OF_DESTRUCTION,
    }) do
        local inert, _, body = case_at(ctx, 56, 160, kind_id)
        local inert_bounds = record(inert, {})

        result = interference.choose(inert, body, kinds.MELEE)
        harness.equal(result.kind, kinds.NONE)
        harness.equal(#inert_bounds, 0)
    end

    -- A blocked spell is still a spell intent so monster energy charges
    -- the cast cost while the resolver performs no effect.
    local casting, caster_player, caster = case_at(ctx,
        52, 160, monsters.MONS_ORC_WIZARD)
    local casting_bounds = record(casting, {0})
    local cast = spell.choose(casting, caster, caster_player, false)

    harness.equal(cast.kind, intents.SPELL)
    harness.truthy(cast.interrupted)
    harness.equal(#casting_bounds, 1)
    harness.equal(casting_bounds[1], 100)
end

return test
