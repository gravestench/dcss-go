local component = require("constants.component")
local form_ids = require("constants.form_ids")
local beam_displacement = require(
    "policy.combat.monster_beams.displacement")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local landing = require("policy.combat.monster_displacement.landing")
local monsters = require("ids.monsters")
local species = require("ids.species")
local relocate = require("policy.combat.monster_displacement.relocate")
local effects = require("policy.combat.monster_spells")
local spells = require("ids.spells")

local test = {}

-- Harpoon Shot can hit the player, whose actor kind is a game identity rather
-- than a monster catalog key. Pulling must inspect the player component
-- before applying the monster-only stationary flag rule.
local function harpoon_pulls_player(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_SWAMP_WORM, 10, 10)
    local player = fixture.actor(ctx, "player", 13, 10)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    harness.truthy(beam_displacement.pull(game, caster, player, 5),
        "a landed harpoon pulls the player through open floor")
    harness.equal(ctx:get(player, component.POSITION).x, 11,
        "the player stops adjacent to the caster")

    game:move_actor(player, 1, 13, 10)
    ctx:add(player, component.PLAYER_FORM, {
        form_id = form_ids.TREE,
        remaining_aut = 10,
    })

    harness.falsy(beam_displacement.pull(game, caster, player, 5),
        "tree form resists the same harpoon pull")
    harness.equal(ctx:get(player, component.POSITION).x, 13,
        "rooted player retains the original cell")

    ctx:remove(player, component.PLAYER_FORM)
    game.random = function(_, _, bound)
        return bound - 1
    end

    harness.truthy(beam_displacement.push(game, caster, player, 5, 50),
        "a forceful beam pushes the unrooted player")
    harness.truthy(ctx:get(player, component.POSITION).x > 13,
        "the pushed player lands behind the original cell")
end

-- The book discovery path, not a private test registry, must find each
-- complete spell effect when a monster selects its slot.
local function complete_effects()
    for _, spell_id in ipairs({
        spells.SPELL_BLINK,
        spells.SPELL_BLINK_RANGE,
        spells.SPELL_BLINK_AWAY,
        spells.SPELL_BLINK_CLOSE,
        spells.SPELL_BLINK_OTHER,
        spells.SPELL_BLINK_OTHER_CLOSE,
        spells.SPELL_BLINK_ALLIES_AWAY,
        spells.SPELL_BLINK_ALLIES_ENCIRCLE,
        spells.SPELL_WORD_OF_RECALL,
    }) do
        local okay, effect = pcall(effects.effect, spell_id)

        harness.truthy(okay, spell_id .. " effect loads")
        harness.truthy(type(effect.plan) == "function",
            spell_id .. " has a plan")
        harness.truthy(type(effect.resolve) == "function",
            spell_id .. " has a resolver")
    end
end

-- A legal ordinary blink leaves the actor's cell and chooses a distant
-- visible spot from the source 13-by-13 square.
local function ordinary_blink(ctx, game)
    local mover = fixture.actor(ctx, monsters.MONS_ORC_WIZARD, 50, 50)

    game.random = function(_, stream, bound)
        harness.equal(stream, "monster_spell",
            "monster blink owns its random stream")
        harness.truthy(bound == 13 or bound == 3,
            "only blink offsets and cloud lifetime draw here")

        return 0
    end

    local x, y = landing.ordinary(game, mover)

    harness.equal(x, 44, "ordinary blink chooses source offset x")
    harness.equal(y, 44, "ordinary blink chooses source offset y")
    harness.truthy(relocate.move(game, mover, x, y, mover),
        "legal blink relocates its Akara actor")

    local position = ctx:get(mover, component.POSITION)

    harness.equal(position.x, 44, "new position is authoritative")
    harness.equal(position.y, 44, "new position is authoritative")
end

-- A source-legal nearby square may still be unsafe for the actor's habitat.
-- The landing helper must reject it before the ECS position changes.
local function wrong_habitat(ctx, game)
    local mover = fixture.actor(ctx, monsters.MONS_ORC_WIZARD, 70, 70)

    game.random = function()
        return 0
    end
    game.cells["64:64"] = "DNGN_DEEP_WATER"

    local x = landing.ordinary(game, mover)

    harness.falsy(x, "land monster cannot blink into deep water")
    harness.equal(ctx:get(mover, component.POSITION).x, 70,
        "failed landing keeps the original cell")
end

-- The real component status, rather than a test-only flag, forbids
-- relocation while Dimension Anchor has remaining time.
local function anchored_actor(ctx, game)
    local mover = fixture.actor(ctx, monsters.MONS_ORC_WIZARD, 90, 70)

    ctx:add(mover, component.HEX_STATUS, {
        anchor_aut = 20,
    })

    harness.falsy(relocate.can_move(game, mover),
        "Dimension Anchor prevents monster blink")
end

-- The live spell effect must cross the same plan/resolve boundary as a
-- monster book and then move its authoritative actor position.
local function monster_spell_blink(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_WIZARD, 120, 100)
    local effect = effects.effect(spells.SPELL_BLINK)
    local plan = effect.plan(game, caster, nil, nil)

    harness.truthy(plan, "mobile caster can prepare Blink")
    effect.resolve(game, caster, nil, nil, plan)

    harness.equal(ctx:get(caster, component.POSITION).x, 114,
        "Blink resolves through the real spell effect")

    ctx:add(caster, component.HEX_STATUS, {
        anchor_aut = 20,
    })

    harness.falsy(effect.plan(game, caster, nil, nil),
        "anchored caster cannot plan another Blink")
end

-- A self blink aimed relative to a foe must use the committed cell, even
-- if that foe moves before the action reaches the spell resolver.
local function planned_foe_cell(ctx, game, player)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_WIZARD,
        180, 100)
    local effect = effects.effect(spells.SPELL_BLINK_RANGE)

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 183,
        y = 100,
    })

    local plan = effect.plan(game, caster, player, nil)

    harness.equal(plan.x, 183, "cast saves the foe's cell")

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 200,
        y = 100,
    })

    effect.resolve(game, caster, nil, nil, plan)
    harness.truthy(ctx:get(caster, component.POSITION).x ~= 180,
        "saved plan resolves without reading the moved foe")
end

-- Encircle chooses aligned actors near its caster and moves them next to
-- the planned victim without creating a new summon or replacing its state.
local function ally_encirclement(ctx, game, player)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_WIZARD,
        150, 100)
    local ally = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        151, 100)

    game.random = function()
        return 0
    end
    ctx:add(ally, component.MONSTER_ENERGY, {
        points = 0,
    })

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 154,
        y = 100,
    })

    local effect = effects.effect(spells.SPELL_BLINK_ALLIES_ENCIRCLE)
    local plan = effect.plan(game, caster, player, nil)

    harness.truthy(plan, "aligned distant ally permits Encircle")
    effect.resolve(game, caster, player, nil, plan)

    local position = ctx:get(ally, component.POSITION)

    harness.truthy(math.max(math.abs(position.x - 154),
        math.abs(position.y - 100)) <= 1,
        "Encircle moves an existing ally beside the planned victim")
    harness.equal(ctx:get(ally, component.MONSTER_ENERGY).points,
        0, "idle ally incurs no energy debt")

    ctx:set(ally, component.POSITION, {
        level_id = 1,
        x = 151,
        y = 100,
    })
    ctx:set(ally, component.MONSTER_ENERGY, {
        points = 80,
    })

    effect.resolve(game, caster, player, nil, plan)
    harness.equal(ctx:get(ally, component.MONSTER_ENERGY).points,
        79, "ready ally loses its source action opportunity")
end

-- Near placement cannot route a follower through an opaque wall even if
-- the destination itself is habitable and empty.
local function wall_blocked_landing(ctx, game)
    local mover = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        240, 100)
    local visible = game.visible

    game.visible = function()
        return false
    end

    local x = landing.near(game, mover, {
        level_id = 1,
        x = 245,
        y = 100,
    }, 3)

    harness.falsy(x, "opaque wall forbids a near landing")
    game.visible = visible
end

-- An adjacent-only square is a source fallback for Blink Other on the
-- player; a monster's ordinary Blink still excludes adjacent cells.
local function adjacent_player_fallback(ctx, game)
    local mover = fixture.actor(ctx, monsters.MONS_HUMAN,
        270, 100)
    local visible = game.visible

    game.visible = function(_, _, from_x, from_y, _, x, y)
        return math.max(math.abs(x - from_x),
            math.abs(y - from_y)) <= 1
    end

    harness.falsy(landing.ordinary(game, mover),
        "ordinary Blink has no distant visible square")

    local x, y = landing.ordinary(game, mover, true)

    harness.equal(x, 269, "player fallback reaches adjacent x")
    harness.equal(y, 99, "player fallback reaches adjacent y")
    game.visible = visible
end

-- A held monster still plans Blink and attempts source escape when it
-- resolves. A successful escape releases the saved player grip first.
local function held_monster_escape(ctx, game, player)
    local mover = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        300, 100)

    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(mover, component.PLAYER_CONSTRICTION, {
        by = player,
        held_aut = 0,
        escape_attempts = 0,
    })

    game.random = function()
        return 0
    end

    harness.truthy(relocate.can_move(game, mover),
        "held monster may attempt a Blink escape")
    harness.truthy(relocate.move(game, mover, 305, 100,
        mover), "source escape permits relocation")
    harness.falsy(ctx:has(mover, component.PLAYER_CONSTRICTION),
        "successful Blink releases the grip")
end

-- A visible move announces the existing actor. Unseen movement must not
-- reveal a remote monster merely because its origin cloud was created.
local function visible_blink_message(ctx, game, player)
    local mover = fixture.actor(ctx, monsters.MONS_ORC_WARRIOR,
        340, 100)
    local messages = {}
    local visible = game.visible

    game.visible = function(_, _, from_x, from_y, radius, x, y)
        return math.max(math.abs(x - from_x),
            math.abs(y - from_y)) <= radius
    end

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 341,
        y = 100,
    })
    game.emit = function(_, _, message)
        messages[#messages + 1] = message
    end

    harness.truthy(relocate.move(game, mover, 345, 100, mover),
        "visible monster blinks")
    harness.truthy(messages[1]:find("blinks", 1, true),
        "visible movement is announced")

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 0,
        y = 0,
    })
    messages = {}

    harness.truthy(relocate.move(game, mover, 350, 100, mover),
        "remote monster blinks")
    harness.equal(#messages, 0,
        "unseen movement does not announce itself")
    game.visible = visible
end

-- Run against the real component schema and catalog in the script VM.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 0, 0)
    local game = fixture.context(ctx, player)

    ordinary_blink(ctx, game)
    wrong_habitat(ctx, game)
    anchored_actor(ctx, game)
    monster_spell_blink(ctx, game)
    planned_foe_cell(ctx, game, player)
    complete_effects()
    ally_encirclement(ctx, game, player)
    wall_blocked_landing(ctx, game)
    adjacent_player_fallback(ctx, game)
    held_monster_escape(ctx, game, player)
    visible_blink_message(ctx, game, player)
    harpoon_pulls_player(ctx)
end

return test
