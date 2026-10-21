-- Pan lords carry a rolled spell list instead of a static monster book.
-- Pain brand must inspect that live list when deriving Necromancy skill.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local necromancy = require("policy.combat.brand_necromancy")
local pan_lord = require("policy.population.pan_lord")
local species = require("ids.species")
local spells = require("ids.spells")

local test = {}

-- Source MST_GHOST has no catalog row: it reads the lord's selected spells.
-- A Necromancy spell grants full HD as effective Pain skill.
function test.run(ctx)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 20, 20, 100)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 21, 20, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })

    local game = fixture.context(ctx, player)

    function game:random(_, bound)
        return bound - 1
    end

    local profile = pan_lord.roll(game, false)

    profile.spell_ids = {
        spells.SPELL_AGONY,
    }
    profile.frequencies = {
        10,
    }

    ctx:add(lord, component.PANDEMONIUM_LORD, profile)

    harness.equal(necromancy.monster_skill(game, lord), profile.hd,
        "live Pan Necromancy spell gives full Pain skill")

    -- A different live spell list uses source half-HD skill. The same
    -- MST_GHOST identity must still avoid a nonexistent static book row.
    profile.spell_ids = {
        spells.SPELL_BOLT_OF_FIRE,
    }
    ctx:set(lord, component.PANDEMONIUM_LORD, profile)

    harness.equal(necromancy.monster_skill(game, lord),
        math.floor(profile.hd / 2),
        "non-Necromancy Pan spells use half-HD Pain skill")
end

return test
