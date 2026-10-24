-- Xom forces a normal Lua spell at event severity, without memorisation
-- or MP cost. Spell IDs and resolvers come from production catalogs.
local component = require("constants.component")
local events = require("ids.xom_events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local spells = require("ids.spells")
local xom_spell = require("policy.religion.xom.effects.spell")

local test = {}

-- Severity one exposes only the first source spell. Repeating the chooser
-- for application must not cache a spell selected by an earlier probe.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    local owner = fixture.context(ctx, player)

    harness.equal(xom_spell.choose(owner, player, 1),
        spells.SPELL_SUMMON_SMALL_MAMMAL)

    local selected = xom_spell.apply(owner, player,
        events.GOOD_SPELL, 1)

    harness.equal(selected, spells.SPELL_SUMMON_SMALL_MAMMAL)
    harness.equal(#ctx:query({ component.SUMMON }), 1)
end

return test
