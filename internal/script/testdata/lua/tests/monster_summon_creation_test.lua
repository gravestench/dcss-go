local attitude = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local summons = require("policy.magic.effects.summons.common")
local expiry = require("systems.magic_summon_expiry")
local terrain = require("constants.terrain")

local test = {}

-- A hostile monster's summons inherit its side, keep their caster as
-- owner, and need no player-style per-spell eviction cap.
local function monster_owner(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 20, 20)

    game.random = function(_, stream, bound)
        harness.falsy(stream == "spell",
            "monster placement must not perturb player spell RNG")

        return 0
    end

    local creature = summons.spawn(game, caster,
        spells.SPELL_SUMMON_SMALL_MAMMAL, monsters.MONS_RAT, 2, nil)

    harness.truthy(creature, "monster can create an ordinary creature")

    local state = ctx:get(creature, component.SUMMON)
    local position = ctx:get(creature, component.POSITION)

    harness.equal(state.owner, caster, "caster owns its summoned actor")
    harness.equal(state.attitude, attitude.HOSTILE,
        "summon inherits hostile caster attitude")
    harness.equal(state.expires_aut, 80,
        "zero fuzz draws give source degree-two lower duration bound")
    harness.equal(position.level_id, 1,
        "summon is placed on the caster's level")

    local next_creature = summons.spawn(game, caster,
        spells.SPELL_SUMMON_SMALL_MAMMAL, monsters.MONS_RAT, 2, nil)

    harness.truthy(ctx:has(creature, component.SUMMON) and
        ctx:has(next_creature, component.SUMMON),
        "uncapped monster summons do not evict one another")

    summons.expire(game, creature)

    harness.falsy(ctx:has(creature, component.ACTOR),
        "expiry removes the old summon actor")
    harness.truthy(ctx:has(next_creature, component.SUMMON),
        "expiry preserves another owned summon")

    game.random = nil
end

-- When all neighboring cells are blocked, no partial Akara actor or
-- summon component may survive the attempted source cast.
local function blocked_space(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 40, 40)
    local before = #ctx:query({ component.ACTOR })
    local messages = 0

    game.visible = function()
        return false
    end
    game.emit = function()
        messages = messages + 1
    end

    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(40 + dx) .. ":" .. (40 + dy)] = true
            end
        end
    end

    local creature = summons.spawn(game, caster,
        spells.SPELL_SUMMON_SMALL_MAMMAL, monsters.MONS_RAT, 2, nil)

    harness.falsy(creature, "blocked cast has no creature")
    harness.equal(#ctx:query({ component.ACTOR }), before,
        "blocked cast does not leave an orphan actor")
    harness.equal(messages, 0,
        "offscreen blocked monster cast prints no message")

    game.visible = nil
    game.emit = nil
end

-- Source monster death removes its owned summons before the owner entity is
-- deleted. Otherwise the saved summon would point at a missing Akara actor.
local function dead_caster(ctx, game, player)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 60, 40)
    local creature = summons.spawn(game, caster,
        spells.SPELL_SUMMON_SMALL_MAMMAL, monsters.MONS_RAT, 2, nil)
    local health = ctx:get(caster, component.HEALTH)

    harness.truthy(creature, "monster cast creates a summon before death")

    health.current = 0
    ctx:set(caster, component.HEALTH, health)
    expiry.update(game, player)

    harness.falsy(ctx:has(creature, component.ACTOR),
        "a dead monster caster cannot leave an orphan summon")
end

-- Neutral and friendly caster sides reach the real creation path and are
-- stored on the summon; they are not collapsed to a hostile boolean.
local function nonhostile_owner(ctx, game)
    local sides = {
        attitude.FRIENDLY,
        attitude.NEUTRAL,
    }

    for index, side in ipairs(sides) do
        local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST,
            100 + index * 10, 40)

        ctx:add(caster, component.VAULT_ACTOR_OVERRIDES, {
            attitude = side,
        })

        local creature = summons.spawn(game, caster,
            spells.SPELL_SUMMON_SMALL_MAMMAL, monsters.MONS_RAT, 2, nil)
        local state = ctx:get(creature, component.SUMMON)

        harness.equal(state.attitude, side,
            "summon preserves its caster's full source attitude")
    end
end

-- The grid calls water walkable for swimmers, but a land summon must reject
-- that terrain through the monster habitat policy before creating an actor.
local function wrong_habitat(ctx, game)
    local caster = fixture.actor(ctx, monsters.MONS_ORC_PRIEST, 80, 40)
    local before = #ctx:query({ component.ACTOR })

    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(80 + dx) .. ":" .. (40 + dy)] = true
            end
        end
    end

    game.walls["81:40"] = nil
    game.cells["81:40"] = terrain.DNGN_DEEP_WATER

    local creature = summons.spawn(game, caster,
        spells.SPELL_SUMMON_SMALL_MAMMAL, monsters.MONS_RAT, 2, nil)

    harness.falsy(creature, "land summon cannot enter deep water")
    harness.equal(#ctx:query({ component.ACTOR }), before,
        "habitat rejection leaves no partial actor")
end

-- The production summon schema and creator run against real Akara stores;
-- only the physical grid placement is supplied by this minimal fixture.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 3, 3)
    local game = fixture.context(ctx, player)

    monster_owner(ctx, game)
    blocked_space(ctx, game)
    dead_caster(ctx, game, player)
    wrong_habitat(ctx, game)
    nonhostile_owner(ctx, game)
end

return test
