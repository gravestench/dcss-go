-- A monster cast creates three independent balls with the source monster-HD
-- reduction. Each ball keeps its caster so later movement and explosions
-- use the same allegiance and save identity as other summoned actors.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local fighter = require("policy.combat.fighter")
local harness = require("tests.harness")
local lightning = require("policy.magic.effects.summons.ball_lightning")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- At power 60, source divides by six, subtracts six, then halves monster
-- ball HD: (10 - 6) / 2 gives two hit dice for each created actor.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 9, 5, 100)
    local caster = fixture.actor(ctx, monsters.MONS_LOM_LOBON,
        5, 5, 30)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})

    local streams = {}

    function game:random(stream)
        streams[#streams + 1] = stream

        return 0
    end

    local created = lightning.spawn(game, caster, 60)

    harness.equal(created, 3,
        "monster Conjure Ball Lightning creates three actors")

    local first_ball

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        first_ball = first_ball or entity
        local summon = ctx:get(entity, component.SUMMON)
        local stats = ctx:get(entity, component.SUMMON_STATS)
        local actor = ctx:get(entity, component.ACTOR)

        harness.equal(summon.owner, caster,
            "the monster caster owns each ball")
        harness.equal(summon.source_id,
            spells.SPELL_CONJURE_BALL_LIGHTNING,
            "the saved source names Conjure Ball Lightning")
        harness.equal(actor.kind_id, monsters.MONS_BALL_LIGHTNING,
            "the summon has the ball-lightning actor profile")
        harness.equal(stats.hd, 2,
            "the source monster-HD reduction is saved per ball")
    end

    local monster_draws = 0

    for _, stream in ipairs(streams) do
        harness.falsy(stream == "spell",
            "monster casting never draws from the player spell stream")

        if stream == "monster_spell" then
            monster_draws = monster_draws + 1
        end
    end

    harness.truthy(monster_draws >= 3,
        "placement draws use the monster-spell stream")

    -- A monster ball's saved HD controls the later explosion. Move the
    -- player into that footprint and capture the ordinary AC draw.
    local origin = ctx:get(first_ball, component.POSITION)

    ctx:set(player, component.POSITION, {
        level_id = origin.level_id,
        x = origin.x + 2,
        y = origin.y + 2,
    })

    local previous_defense = fighter.defense
    local explosion_draws = {}

    fighter.defense = function()
        return { ac = 5 }
    end

    function game:random(stream, bound)
        explosion_draws[#explosion_draws + 1] = {
            stream = stream,
            bound = bound,
        }

        return 0
    end

    lightning.explode(game, first_ball)

    fighter.defense = previous_defense

    harness.truthy(ctx:get(player, component.HEALTH).current < 100,
        "monster ball lightning reaches the player")

    local armour_draw = false

    for _, draw in ipairs(explosion_draws) do
        harness.equal(draw.stream, "monster_spell",
            "explosion damage and armour use monster spell RNG")

        if draw.bound == 6 then
            armour_draw = true
        end
    end

    harness.truthy(armour_draw,
        "explosion contact checks the player's five armour")

    -- Source rolls HD for each attempted summon. Power 71 can round to
    -- either two or three effective HD after the monster reduction.
    local varied = {}
    local rounding = 0

    function game:random(_, bound)
        if bound == 6 then
            rounding = rounding + 1

            return rounding % 2 == 1 and 0 or 5
        end

        return 0
    end

    lightning.spawn(game, caster, 71)

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON_CONSTRUCT)

        if state and state.power == 71 then
            local stats = ctx:get(entity, component.SUMMON_STATS)

            varied[#varied + 1] = stats.hd
        end
    end

    harness.equal(rounding, 3,
        "each ball has its own stochastic HD round")
    harness.equal(varied[1], 3,
        "first ball takes the high rounding result")
    harness.equal(varied[2], 2,
        "second ball takes the low rounding result")
    harness.equal(varied[3], 3,
        "third ball rounds independently again")

    -- A weak caster can create a raw HD-zero ball. Source monster::get_hit_dice
    -- exposes it as HD one when the later explosion rolls its damage.
    local low_ball

    lightning.spawn(game, caster, 0)

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON_CONSTRUCT)

        if state and state.power == 0 then
            low_ball = entity

            break
        end
    end

    harness.truthy(low_ball, "weak caster still creates ball lightning")

    local low_position = ctx:get(low_ball, component.POSITION)

    ctx:set(player, component.POSITION, {
        level_id = low_position.level_id,
        x = low_position.x + 2,
        y = low_position.y + 2,
    })

    local damage_sides = {}

    function game:random(_, bound)
        damage_sides[bound] = (damage_sides[bound] or 0) + 1

        return 0
    end

    fighter.defense = function()
        return { ac = 0 }
    end

    lightning.explode(game, low_ball)

    fighter.defense = previous_defense

    harness.truthy(damage_sides[6],
        "raw HD zero uses effective HD one for explosion damage")
end

return test
