-- Awaken Vines uses production summon, tree, and ECS schemas. This test
-- supplies only the physical level services absent from the rule host.
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local terrain = require("constants.terrain")
local vines = require("policy.combat.monster_plants.vines")
local chain = require("policy.combat.monster_plants.vine_chain")

local test = {}

-- A dryad awakens a real tree's adjacent cell, keeping both the caster
-- owner and the vine's anchor through the ordinary ECS query path.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 6, 2, 40)
    local caster = fixture.actor(ctx, monsters.MONS_DRYAD, 1, 1, 40)
    local game = fixture.context(ctx, player)
    local effect = effects.effect(spells.SPELL_AWAKEN_VINES)

    ctx:add(player, component.PLAYER, {})
    game.cells["4:2"] = terrain.DNGN_TREE

    function game:visible_no_trans()
        return true
    end

    function game:random(_, bound)
        return 0
    end

    local plan = effect.plan(game, caster, player)

    harness.truthy(plan, "a visible foe beside a tree makes vines legal")
    effect.resolve(game, caster, player, nil, plan)

    harness.equal(vines.count(game, caster), 1,
        "source roll of zero creates one vine")

    local head = ctx:query({ component.MONSTER_VINE })[1]
    local summon = ctx:get(head, component.SUMMON)
    local anchor = ctx:get(head, component.MONSTER_VINE)
    local position = ctx:get(head, component.POSITION)

    harness.equal(summon.owner, caster, "the dryad owns the head")
    harness.equal(anchor.target, player, "the head keeps its foe")
    harness.equal(anchor.anchor_x, position.x,
        "the head saves its tree anchor")
    harness.equal(ctx:get(caster,
        component.MONSTER_AWAKE_VINES).remaining_aut, 200,
        "the dryad owns the shared source duration")

    -- A moved head keeps a connected physical chain back to its tree.
    game:move_actor(head, position.level_id,
        position.x, position.y + 2)
    chain.refresh(game, head)

    local segment = ctx:query({ component.MONSTER_VINE_SEGMENT })[1]

    harness.truthy(segment, "a stretched head creates a physical connector")
    harness.equal(ctx:get(segment,
        component.MONSTER_VINE_SEGMENT).head, head,
        "the connector keeps its head through save state")

    vines.tick(game, caster, 10)

    harness.equal(ctx:get(caster,
        component.MONSTER_AWAKE_VINES).remaining_aut, 190,
        "the dryad's action ages the shared enchant")

    vines.tick(game, caster, 190)
    chain.clean_orphans(game)

    harness.equal(vines.count(game, caster), 0,
        "expired enchant releases every live head")
    harness.falsy(ctx:has(caster, component.MONSTER_AWAKE_VINES),
        "the owner timer is removed with the vines")
    harness.falsy(ctx:has(segment, component.ACTOR),
        "a released head cannot leave an orphan segment")
end

return test
