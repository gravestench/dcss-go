-- Monster Battlesphere belongs to its caster and reacts to later
-- conjurations. Saved HD and charge make a restored shot behave like one
-- from the original run, with no hidden module-local combat state.
local component = require("constants.component")
local fighter = require("policy.combat.fighter")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local sphere = require("policy.magic.effects.summons.battlesphere")
local spells = require("ids.spells")

local test = {}

-- Power 55 has an exact source division by eleven, giving six HD. A
-- monster-owned sphere must attack the player without awarding player XP.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 7, 5, 100)
    local caster = fixture.actor(ctx,
        monsters.MONS_TENGU_CONJURER, 5, 5, 30)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})

    local draws = {}

    function game:random(stream)
        draws[#draws + 1] = stream

        return 0
    end

    function game:projectile_clear()
        return true
    end

    local created = sphere.spawn(game, caster, 55)

    harness.truthy(created,
        "monster Battlesphere creates a physical actor")
    harness.equal(ctx:get(created, component.SUMMON).owner, caster,
        "the caster owns its saved sphere")
    harness.equal(ctx:get(created, component.SUMMON).source_id,
        spells.SPELL_BATTLESPHERE,
        "sphere source identity survives restore")
    harness.equal(ctx:get(created, component.SUMMON_STATS).hd, 6,
        "source HD is rolled once and saved")

    local initial = ctx:get(created,
        component.SUMMON_BATTLESPHERE).charge
    local previous_defense = fighter.defense

    fighter.defense = function()
        return { ac = 0 }
    end

    sphere.fire(game, caster)

    fighter.defense = previous_defense

    harness.equal(ctx:get(created,
        component.SUMMON_BATTLESPHERE).charge, initial - 1,
        "a matching caster conjuration spends one sphere charge")
    harness.truthy(ctx:get(player, component.HEALTH).current < 100,
        "a monster-owned sphere damages its enemy")

    for _, stream in ipairs(draws) do
        harness.falsy(stream == "spell",
            "monster sphere never consumes the player spell stream")
    end
end

return test
