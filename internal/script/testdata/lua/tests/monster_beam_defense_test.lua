local catalog = require("policy.catalog")
local defense = require("policy.combat.monster_beams.defense")
local harness = require("tests.harness")
local spells = require("ids.spells")

local test = {}

local function context(draws)
    local ctx = {
        draws = draws,
        next_draw = 1,
    }

    function ctx:random(_, bound)
        local value = self.draws[self.next_draw]

        if value == nil or value >= bound then
            error("invalid scripted beam defense roll")
        end

        self.next_draw = self.next_draw + 1

        return value
    end

    return ctx
end

function test.run()
    local arrow = catalog.get("monster_beams", spells.SPELL_STONE_ARROW)
    local lightning = catalog.get("monster_beams",
        spells.SPELL_LIGHTNING_BOLT)
    local shield = {
        ev = 10,
        shield_class = 20,
        shield_blocks = 0,
        reflects = true,
    }

    local blocked = defense.roll(context({ 0, 39, 40 }), shield, 14, arrow)

    harness.equal(blocked.kind, "reflect",
        "a shield can reflect a blocked Stone Arrow")

    local piercing = defense.roll(context({ 0, 0, 0 }), shield, 21,
        lightning)

    harness.equal(piercing.kind, "hit",
        "a penetrating Lightning Bolt bypasses the shield")

    local unshielded = {
        ev = 20,
        shield_class = 0,
    }
    local missed = defense.roll(context({ 0, 19, 20 }),
        unshielded, 14, arrow)

    harness.equal(missed.kind, "miss",
        "Stone Arrow can miss an evading actor")

    local repelled = {
        ev = 10,
        shield_class = 0,
        missile_repulsion = true,
    }
    local bolt = defense.roll(context({ 15, 5, 5, 1, 0, 5, 5 }),
        repelled, 20, arrow)

    harness.equal(bolt.kind, "repel",
        "repulsion can stop a bolt after its ordinary hit roll")

    local beam_hit = defense.roll(context({ 15, 5, 5, 0, 0, 5, 5 }),
        repelled, 20, lightning)

    harness.equal(beam_hit.kind, "repel",
        "repulsion can stop a penetrating beam")
end

return test
