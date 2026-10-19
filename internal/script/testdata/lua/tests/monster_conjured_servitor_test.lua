-- Frederick's servitor copies his eligible spellbook slots at creation.
-- The saved ordered list belongs to the summoned actor, so later caster
-- changes cannot silently rewrite its attacks.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local servitor = require("policy.magic.effects.summons.spellforged_servitor")
local spellbook = require("policy.combat.monster_spellbook")
local spells = require("ids.spells")

local test = {}

-- Frederick's source book has Iron Shot, Bolt of Cold, and Force Lance in
-- servitor priority order. Power 126 yields HD 18 and minimum-roll HP 67.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 8, 5, 100)
    local caster = fixture.actor(ctx, monsters.MONS_FREDERICK,
        5, 5, 30)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})

    function game:random()
        return 0
    end

    local creature = servitor.spawn_monster(game, caster, 126)

    harness.truthy(creature,
        "monster Spellforged Servitor creates an actor")

    local state = ctx:get(creature, component.SUMMON_SERVITOR)
    local summon = ctx:get(creature, component.SUMMON)
    local health = ctx:get(creature, component.HEALTH)
    local stats = ctx:get(creature, component.SUMMON_STATS)

    harness.equal(summon.owner, caster,
        "servitor keeps Frederick as its saved owner")
    harness.equal(stats.hd, 18,
        "source power gives saved servitor HD")
    harness.equal(health.max, 67,
        "source 60 plus seven minimum five-sided rolls gives HP")
    harness.equal(#state.spell_ids, 3,
        "servitor snapshots every eligible Frederick spell")
    harness.equal(state.spell_ids[1], spells.SPELL_IRON_SHOT,
        "source priority starts with Iron Shot")
    harness.equal(state.spell_ids[2], spells.SPELL_BOLT_OF_COLD,
        "Bolt of Cold follows Iron Shot")
    harness.equal(state.spell_ids[3], spells.SPELL_FORCE_LANCE,
        "Force Lance remains in the custom book")

    local book = spellbook.for_actor(game, creature)

    harness.equal(book.slots[1].spell_id,
        spells.SPELL_IRON_SHOT,
        "generic monster AI sees the saved first slot")
    harness.equal(book.slots[1].frequency,
        state.frequencies[1],
        "AI reads the saved source frequency")
    harness.equal(book.slots[3].frequency,
        state.frequencies[3],
        "the last slot retains its own frequency")

    -- A Lich's Orb of Destruction is now castable by the shared homing orb
    -- owner, so its servitor inherits both that spell and Bolt of Cold.
    local lich = fixture.actor(ctx, monsters.MONS_LICH, 5, 8, 30)
    local lich_servitor = servitor.spawn_monster(game, lich, 126)
    local lich_book = spellbook.for_actor(game, lich_servitor)

    harness.equal(#lich_book.slots, 2,
        "servitor keeps both castable inherited slots")
    harness.equal(lich_book.slots[1].spell_id,
        spells.SPELL_IOOD,
        "the source priority gives the Lich's orb first place")
    harness.equal(lich_book.slots[2].spell_id,
        spells.SPELL_BOLT_OF_COLD,
        "the supported cold bolt follows the orb")
end

return test
