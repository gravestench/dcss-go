-- Monster spell effects may act outside the player's field of view.
-- Rules still resolve, but messages must describe only observed actors.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local smiting = require("policy.combat.monster_spells.smiting")
local sprint = require("policy.combat.monster_spells.sprint")
local invisibility = require("policy.combat.monster_spells.invisibility")
local target_kind = require("constants.target_kind")
local repulsion = require("policy.combat.monster_support.repulsion")
local flash_freeze = require("policy.combat.monster_beams.flash_freeze")
local monster_slow = require("policy.combat.monster_slow")
local paralysis = require("policy.magic.effects.zaps.paralysis")
local catalog = require("policy.catalog")

local test = {}

-- A planned direct strike can resolve after the player loses sight. Its HP
-- change remains real while the log has no message about the unseen foe.
local function unseen_direct_strike(ctx, game, caster, foe, messages)
    local plan = smiting.plan(game, caster, foe)
    local health = ctx:get(foe, component.HEALTH)
    local before = health.current

    harness.truthy(plan, "Smiting plans a visible enemy")
    game.seen = false
    smiting.resolve(game, caster, foe, nil, plan)

    harness.truthy(ctx:get(foe, component.HEALTH).current < before,
        "unseen Smiting still changes the foe's HP")
    harness.equal(#messages, 0,
        "unseen direct strike reveals no result")
end

-- A self buff must not name its hidden caster merely because a spell slot
-- resolved. The saved boon should still be present for later actions.
local function unseen_self_buff(ctx, game, caster, messages)
    local plan = {
        kind = target_kind.ENTITY,
        entity = caster,
    }

    sprint.resolve(game, caster, nil, nil, plan)

    local boon = ctx:get(caster, component.MONSTER_BOONS)

    harness.truthy(boon and boon.swift_aut > 0,
        "unseen Swift remains on the caster")
    harness.equal(#messages, 0,
        "unseen self buff reveals no caster")
end

-- Invisibility has to sample sight before applying its own enchantment.
-- An observed disappearance is reported, while an unseen one stays quiet.
local function observed_disappearance(ctx, game, messages)
    local visible = fixture.actor(ctx, monsters.MONS_RAT, 2, 1, 40)
    local hidden = fixture.actor(ctx, monsters.MONS_RAT, 3, 1, 40)

    game.seen = true
    invisibility.resolve(game, visible, nil, nil, {
        kind = target_kind.ENTITY,
        entity = visible,
    })

    harness.equal(#messages, 1,
        "observed monster disappearance is reported")

    game.seen = false
    invisibility.resolve(game, hidden, nil, nil, {
        kind = target_kind.ENTITY,
        entity = hidden,
    })

    harness.equal(#messages, 1,
        "unseen disappearance adds no message")
end

-- Shared support and beam hooks write statuses independently of whether
-- their monster recipient can be identified by the player.
local function unseen_shared_effects(ctx, game, messages)
    local supported = fixture.actor(ctx, monsters.MONS_RAT, 4, 1, 40)
    local frozen = fixture.actor(ctx, monsters.MONS_RAT, 5, 1, 40)

    game.seen = false
    repulsion.apply(game, supported)
    flash_freeze.after_hit(game, nil, frozen)

    harness.truthy(repulsion.active(game, supported),
        "offscreen repulsion remains active")
    harness.truthy(ctx:has(frozen, component.FLASH_FROZEN),
        "offscreen flash freeze remains active")
    harness.equal(#messages, 1,
        "offscreen shared effects do not add messages")
end

-- Geometry can expose a cell without exposing an enchanted invisible
-- monster in it. A support effect must not disclose that monster's name.
local function invisible_shared_effect(ctx, game, messages)
    local hidden = fixture.actor(ctx, monsters.MONS_RAT, 4, 2, 40)

    ctx:add(hidden, component.MONSTER_ENCHANT, {
        invisible_aut = 30,
    })

    game.seen = true
    repulsion.apply(game, hidden)

    harness.truthy(repulsion.active(game, hidden),
        "invisible monster still receives repulsion")
    harness.equal(#messages, 1,
        "visible cell does not disclose invisible recipient")
end

-- Monster hexes and shared status owners must persist offscreen effects
-- without narrating a recipient the player cannot currently identify.
local function unseen_hex_statuses(ctx, game, messages)
    local slowed = fixture.actor(ctx, monsters.MONS_RAT, 3, 2, 40)
    local stopped = fixture.actor(ctx, monsters.MONS_RAT, 4, 2, 40)
    local definition = catalog.get("monsters", monsters.MONS_RAT)

    game.seen = false
    monster_slow.apply(game, slowed, definition)
    paralysis.apply_unresisted(game, stopped, definition, 50)

    harness.truthy(ctx:has(slowed, component.PROJECTILE_SLOW),
        "offscreen Slow remains on its recipient")
    harness.truthy(ctx:has(stopped, component.PARALYSIS),
        "offscreen Paralysis remains on its recipient")
    harness.equal(#messages, 1,
        "offscreen hex statuses add no message")
end

-- Build one production-schema world and vary only the observer's sight.
function test.run(ctx)
    local player = ctx:create()
    local caster = fixture.actor(ctx, monsters.MONS_ENDOPLASM, 1, 1, 40)
    local foe = fixture.actor(ctx, monsters.MONS_ADDER, 2, 1, 40)
    local game = fixture.context(ctx, player)
    local messages = {}

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    -- A test-controlled sight change models the player leaving this fight's
    -- view between plan and resolution without replacing any spell policy.
    function game:visible()
        return self.seen ~= false
    end

    -- Source minimum draws are sufficient to prove state changes.
    function game:random()
        return 0
    end

    -- Capture the user-facing log while production rules own the effects.
    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    unseen_direct_strike(ctx, game, caster, foe, messages)
    unseen_self_buff(ctx, game, caster, messages)
    observed_disappearance(ctx, game, messages)
    unseen_shared_effects(ctx, game, messages)
    invisible_shared_effect(ctx, game, messages)
    unseen_hex_statuses(ctx, game, messages)
end

return test
