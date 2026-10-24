-- Dowan and Duvessa have linked consequences beyond their initial band.
-- These checks use the production death hooks, spellbook, and status owners
-- so the survivor's saved state drives ordinary monster actions.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local abyss = require("policy.world.abyss")
local behaviors = require("constants.ai_behaviors")
local boons = require("policy.combat.monster_support.boons")
local catalog = require("policy.catalog")
local component = require("constants.component")
local causes = require("constants.elven_twin")
local death_hooks = require("policy.combat.death_hooks")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local books = require("ids.monster_spellbooks")
local spellbook = require("policy.combat.monster_spellbook")
local spells = require("ids.spells")
local decision = require("systems.monster_decision")
local twins = require("policy.monsters.elven_twins")

local test = {}

-- Duvessa's death changes the living Dowan's first, second, and fourth
-- spell slots. The original shared catalog remains unchanged for others.
local function dowan_grieves(ctx)
    local game = fixture.observed_context(ctx)
    local duvessa = fixture.actor(ctx, monsters.MONS_DUVESSA,
        8, 8, 50)
    local dowan = fixture.actor(ctx, monsters.MONS_DOWAN,
        9, 8, 50)
    local definition = catalog.get("monsters", monsters.MONS_DUVESSA)

    death_hooks.run(game, duvessa, definition,
        game:get(duvessa, component.POSITION), true)

    local changed = spellbook.for_actor(game, dowan)

    harness.equal(changed.slots[1].spell_id, spells.SPELL_STONE_ARROW)
    harness.equal(changed.slots[2].spell_id, spells.SPELL_THROW_ICICLE)
    harness.equal(changed.slots[4].spell_id, spells.SPELL_BLINK)
    harness.equal(changed.id, books.MST_DOWAN)
    harness.equal(catalog.get("monster_spellbooks",
        books.MST_DOWAN).slots[1].spell_id,
        spells.SPELL_THROW_FLAME)
    harness.truthy(boons.hasted(game, dowan),
        "Dowan keeps source permanent Haste")
    boons.tick(game, dowan, 30000)
    harness.truthy(boons.hasted(game, dowan),
        "Dowan's Haste cannot time out")
    twins.validate(game)

    ctx:destroy(duvessa)
    ctx:destroy(dowan)
end

-- A monster outside the unique pair cannot carry a saved bereavement
-- record, even if its component fields otherwise look well formed.
local function reject_false_grief(ctx)
    local game = fixture.observed_context(ctx)
    local rat = fixture.actor(ctx, monsters.MONS_RAT,
        8, 13, 10)

    game:add(rat, component.MONSTER_ELVEN_TWIN, {
        grieved = true,
        pending = true,
        energized = false,
        can_climb = true,
        cause = causes.DEATH,
    })

    local valid = pcall(twins.validate, game)

    harness.falsy(valid, "non-twin carried grief through restore")
    ctx:destroy(rat)
end

-- Dowan's death grants Duvessa source Berserk without a normal expiry.
-- The same frenzy owner must scale HP and alter her future action speed.
local function duvessa_grieves(ctx)
    local game = fixture.observed_context(ctx)
    local duvessa = fixture.actor(ctx, monsters.MONS_DUVESSA,
        8, 9, 50)
    local dowan = fixture.actor(ctx, monsters.MONS_DOWAN,
        9, 9, 50)
    local definition = catalog.get("monsters", monsters.MONS_DOWAN)

    death_hooks.run(game, dowan, definition,
        game:get(dowan, component.POSITION), true)

    harness.truthy(allegiance.frenzied(game, duvessa))
    harness.truthy(game:get(duvessa, component.HEALTH).max > 100)
    allegiance.tick(game, duvessa, 30000)
    harness.truthy(allegiance.frenzied(game, duvessa),
        "Duvessa's grief cannot time out")

    ctx:destroy(duvessa)
    ctx:destroy(dowan)
end

-- An unseen Dowan records grief immediately so his spellbook changes,
-- but his Haste waits until the player becomes visible on a later turn.
local function delayed_dowan(ctx)
    local game = fixture.observed_context(ctx)
    local duvessa = fixture.actor(ctx, monsters.MONS_DUVESSA,
        8, 10, 50)
    local dowan = fixture.actor(ctx, monsters.MONS_DOWAN,
        9, 10, 50)
    local definition = catalog.get("monsters", monsters.MONS_DUVESSA)

    game:add(dowan, component.AI, {
        behavior = behaviors.SEEK,
        target_x = 7,
        target_y = 7,
        memory_until_aut = 250,
        bat_retreat_actions = 0,
    })

    function game:visible()
        return false
    end

    death_hooks.run(game, duvessa, definition,
        game:get(duvessa, component.POSITION), true)

    local grief = game:get(dowan, component.MONSTER_ELVEN_TWIN)

    harness.truthy(grief.pending)
    harness.falsy(boons.hasted(game, dowan))
    harness.equal(spellbook.for_actor(game, dowan).slots[1].spell_id,
        spells.SPELL_STONE_ARROW)

    function game:visible()
        return true
    end

    decision.update(game, dowan)
    harness.truthy(boons.hasted(game, dowan))
    harness.falsy(game:get(dowan, component.MONSTER_ELVEN_TWIN).pending)

    ctx:destroy(duvessa)
    ctx:destroy(dowan)
end

-- Original identity links a polymorphed Dowan to Duvessa, while the
-- polymorphed body's current spellbook must remain its own.
local function polymorphed_dowan(ctx)
    local game = fixture.observed_context(ctx)
    local duvessa = fixture.actor(ctx, monsters.MONS_DUVESSA,
        8, 11, 50)
    local dowan = fixture.actor(ctx, monsters.MONS_DOWAN,
        9, 11, 50)
    local changed = game:get(dowan, component.ACTOR)

    changed.kind_id = monsters.MONS_ORC_WIZARD
    game:set(dowan, component.ACTOR, changed)
    game:add(dowan, component.MONSTER_POLYMORPH, {
        original_kind_id = monsters.MONS_DOWAN,
    })

    local before = spellbook.for_actor(game, dowan)
    local definition = catalog.get("monsters", monsters.MONS_DUVESSA)

    death_hooks.run(game, duvessa, definition,
        game:get(duvessa, component.POSITION), true)

    harness.equal(spellbook.for_actor(game, dowan).slots[1].spell_id,
        before.slots[1].spell_id)
    harness.truthy(boons.hasted(game, dowan))

    ctx:destroy(duvessa)
    ctx:destroy(dowan)
end

-- Banishment uses the same separation rule while the banished actor
-- remains alive in the Abyss. The source cause is saved on the survivor.
local function banished_dowan(ctx)
    local game = fixture.observed_context(ctx)
    local duvessa = fixture.actor(ctx, monsters.MONS_DUVESSA,
        8, 12, 50)
    local dowan = fixture.actor(ctx, monsters.MONS_DOWAN,
        9, 12, 50)
    local definition = catalog.get("monsters", monsters.MONS_DOWAN)

    harness.truthy(abyss.banish_monster(game, dowan, definition))
    harness.equal(game:get(dowan, component.POSITION).level_id,
        abyss.level_id)
    harness.truthy(game:get(duvessa, component.MONSTER_ELVEN_TWIN).grieved)

    ctx:destroy(duvessa)
    ctx:destroy(dowan)
end

-- An Arena challenge likewise separates the twins on the outside floor;
-- the saved cause distinguishes that transition from an actual death.
local function dueled_dowan(ctx)
    local game = fixture.observed_context(ctx)
    local duvessa = fixture.actor(ctx, monsters.MONS_DUVESSA,
        8, 14, 50)
    local dowan = fixture.actor(ctx, monsters.MONS_DOWAN,
        9, 14, 50)

    harness.truthy(twins.grieve(game, duvessa, nil,
        game:get(duvessa, component.POSITION), causes.DUEL))
    harness.equal(game:get(dowan, component.MONSTER_ELVEN_TWIN).cause,
        causes.DUEL)

    ctx:destroy(duvessa)
    ctx:destroy(dowan)
end

-- Each pair is retired before the next so the unique lookup cannot
-- mistake an earlier synthetic survivor for the current one.
function test.run(ctx)
    dowan_grieves(ctx)
    duvessa_grieves(ctx)
    delayed_dowan(ctx)
    polymorphed_dowan(ctx)
    banished_dowan(ctx)
    dueled_dowan(ctx)
    reject_false_grief(ctx)
end

return test
