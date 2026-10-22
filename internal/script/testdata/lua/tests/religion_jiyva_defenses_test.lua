-- Jiyva's defensive passives read the same saved worship and terrain state
-- used by ordinary prayer, regeneration, acid damage, and map generation.
-- These cases import production schemas and IDs rather than redefining them.
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local gods = require("constants.gods")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local resistance = require("constants.resistance_ids")
local terrain = require("constants.terrain")
local defenses = require("policy.religion.jiyva.defenses")
local damage = require("policy.magic.damage")
local corrosion = require("policy.combat.player_corrosion")
local regeneration = require("policy.character.regeneration")
local walls = require("policy.world.slime_walls")

local test = {}

-- The current worship component is the only rank source. A pending debt or
-- a departed god must disable every benefit without a stale copied flag.
local function rank_and_recovery(ctx)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.JIYVA,
        piety = 0,
    })

    harness.truthy(defenses.active(ctx, player, 0))
    harness.falsy(defenses.active(ctx, player, 1))

    local base_hp, base_mp = regeneration.rates(ctx, player, 30, 4)

    harness.equal(base_hp, 10)
    harness.equal(base_mp, 9)

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    state.piety = 30
    ctx:set(player, component.RELIGION_WORSHIP, state)

    local one_hp, one_mp = regeneration.rates(ctx, player, 30, 4)

    harness.equal(one_hp, 90)
    harness.equal(one_mp, 34)

    records.grant_acquired(ctx, player,
        mutations.MUT_NO_REGENERATION, 1)

    harness.falsy(regeneration.hp_allowed(ctx, player),
        "natural healing is still blocked")
    harness.equal(regeneration.effective_hp_rate(ctx, player, one_hp),
        80, "Jiyva's HP pip survives the natural block")

    state.piety = 160
    ctx:set(player, component.RELIGION_WORSHIP, state)

    local six_hp, six_mp = regeneration.rates(ctx, player, 30, 4)

    harness.equal(six_hp, 170)
    harness.equal(six_mp, 59)

    state.penance[gods.JIYVA] = 1
    ctx:set(player, component.RELIGION_WORSHIP, state)

    harness.falsy(defenses.active(ctx, player, 0))
    harness.equal(defenses.hp_bonus(ctx, player), 0)

    state.penance[gods.JIYVA] = 0
    state.god_id = gods.NO_GOD
    ctx:set(player, component.RELIGION_WORSHIP, state)

    harness.falsy(defenses.active(ctx, player, 0))
    harness.equal(defenses.mp_bonus(ctx, player), 0)
end

-- The source two-star rCorr is one acid-resistance level. Existing rCorr
-- gear still caps at one, and penance returns to the unaided acid rule.
local function corrosion_resistance(ctx)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.JIYVA,
        piety = 49,
    })

    harness.equal(damage.player_resistance(ctx, player,
        resistance.ACID), 0)

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    state.piety = 50
    ctx:set(player, component.RELIGION_WORSHIP, state)

    harness.equal(damage.player_resistance(ctx, player,
        resistance.ACID), 1)
    harness.equal(damage.player_elemental(ctx, player, 9,
        resistance.ACID), 4)

    state.penance[gods.JIYVA] = 1
    ctx:set(player, component.RELIGION_WORSHIP, state)

    harness.equal(damage.player_resistance(ctx, player,
        resistance.ACID), 0)
end

-- An actual slimy-wall cell threatens each adjacent actor after its action.
-- Jiyva protects the player at zero stars; slime genus protects monsters
-- regardless of the player's current patron.
local function wall_exposure(ctx)
    local game = fixture.observed_context(ctx)
    local player = game:player()

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 20,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.JIYVA,
        piety = 0,
    })
    game.cells["8:7"] = terrain.DNGN_SLIMY_WALL

    function game:random(_, bound)
        return 0
    end

    harness.equal(walls.adjacent(game, 1, 7, 7), 1)
    harness.equal(walls.expose(game, player, 10), 0)
    harness.equal(game:get(player, component.HEALTH).current, 20)

    local state = game:get(player, component.RELIGION_WORSHIP)

    state.god_id = gods.NO_GOD
    game:set(player, component.RELIGION_WORSHIP, state)

    harness.equal(walls.expose(game, player, 10), 4)
    harness.equal(game:get(player, component.HEALTH).current, 16)

    local jelly = fixture.actor(ctx, monsters.MONS_JELLY, 7, 6, 20)
    local goblin = fixture.actor(ctx, monsters.MONS_GOBLIN, 8, 6, 20)
    local oklob = fixture.actor(ctx, monsters.MONS_OKLOB_PLANT,
        8, 8, 20)

    harness.equal(walls.expose(game, jelly, 10), 0)
    harness.equal(walls.expose(game, goblin, 10), 2)
    harness.equal(game:get(goblin, component.HEALTH).current, 18)
    harness.equal(walls.expose(game, oklob, 10), 0)
    harness.equal(game:get(oklob, component.HEALTH).current, 20)

    -- The source does not hurt a monster through opaque sight. This also
    -- prevents an unseen creature from dying to a wall offscreen.
    game.visible_no_trans = function()
        return false
    end

    harness.equal(walls.expose(game, goblin, 10), 0)
    harness.equal(game:get(goblin, component.HEALTH).current, 18)

    -- A temporary resistance enchantment belongs to the live monster,
    -- so wall damage must use its projected profile rather than the
    -- immutable acid-dragon catalog row.
    game.visible_no_trans = function()
        return true
    end

    local dragon = fixture.actor(ctx, monsters.MONS_ACID_DRAGON,
        9, 7, 20)

    ctx:add(dragon, constructs.RESISTANCE, {
        remaining_aut = 10,
    })

    harness.equal(damage.monster_resistance(game, dragon,
        resistance.ACID), 2)

    function game:random(_, bound)
        return bound - 1
    end

    harness.equal(walls.expose(game, dragon, 10), 1)
    harness.equal(game:get(dragon, component.HEALTH).current, 19)

    -- One diagonal wall counts alongside the cardinal wall. At seven aut,
    -- one wall first samples the fractional strength, then four dice.
    game.cells["8:8"] = terrain.DNGN_SLIMY_WALL
    harness.equal(walls.adjacent(game, 1, 7, 7), 2)
    game.cells["8:8"] = nil

    local bounds = {}

    function game:random(_, bound)
        bounds[#bounds + 1] = bound

        return 0
    end

    harness.equal(walls.expose(game, player, 7), 4)
    harness.equal(bounds[1], 10)

    for die = 2, 5 do
        harness.equal(bounds[die], 3)
    end

    -- The ordinary corrosion owner reads the same acid resistance. A
    -- zero roll guarantees protection at two stars, then corrosion after
    -- desertion, without a Jiyva-specific branch inside that owner.
    state.god_id = gods.JIYVA
    state.piety = 50
    game:set(player, component.RELIGION_WORSHIP, state)

    harness.falsy(corrosion.corrode_equipment(game, player))

    state.god_id = gods.NO_GOD
    game:set(player, component.RELIGION_WORSHIP, state)

    harness.truthy(corrosion.corrode_equipment(game, player))
end

-- Keep the three consumers in one category test so a rank query change
-- cannot silently fix regeneration while leaving acid or terrain wrong.
function test.run(ctx)
    rank_and_recovery(ctx)
    corrosion_resistance(ctx)
    wall_exposure(ctx)
end

return test
