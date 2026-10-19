local anchor = require("policy.combat.monster_hexes.dimension_anchor")
local component = require("constants.component")
local corona = require("policy.combat.monster_hexes.corona")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local harness = require("tests.harness")
local invisibility = require("policy.potions.invisibility")
local monster_poison = require("policy.combat.monster_poison")
local monster_teleport = require(
    "policy.magic.effects.zaps.teleport_other")
local sap = require("policy.combat.monster_hexes.sap_magic")
local status = require("policy.combat.monster_hexes.status")
local translocation = require("policy.scrolls.translocation")

local test = {}

function test.run()
    local player = 101
    local monster = 202
    local values = {
        [player] = {
            [component.PLAYER] = {},
            [component.PLAYER_TELEPORT] = {
                remaining_aut = 30,
            },
        },
        [monster] = {},
    }
    local ctx = {}

    function ctx:get(actor, id)
        return values[actor][id]
    end

    function ctx:has(actor, id)
        return self:get(actor, id) ~= nil
    end

    function ctx:add(actor, id, value)
        values[actor][id] = value
    end

    function ctx:set(actor, id, value)
        values[actor][id] = value
    end

    function ctx:remove(actor, id)
        values[actor][id] = nil
    end

    function ctx:random()
        return 0
    end

    function ctx:emit()
    end

    anchor.apply(ctx, monster, player)

    harness.falsy(ctx:has(player, component.PLAYER_TELEPORT),
        "Dimension Anchor cancels an already pending teleport")
    harness.truthy(translocation.restriction(ctx, player),
        "Dimension Anchor blocks a new teleport")
    harness.falsy(translocation.can_blink(ctx, player, {}, 1, 1),
        "Dimension Anchor blocks player blinks before aim checks")

    anchor.apply(ctx, player, monster)

    harness.truthy(monster_teleport.no_tele({}, {}, ctx, monster),
        "Dimension Anchor blocks monster translocation")

    corona.apply(ctx, monster, player)

    harness.truthy(invisibility.backlit(ctx, player),
        "Corona makes invisible actors visible")
    harness.falsy(corona.viable(ctx, monster, player),
        "Corona does not waste another cast on an already lit player")

    corona.apply(ctx, player, monster)

    harness.falsy(corona.viable(ctx, player, monster),
        "Corona also avoids an already lit monster")

    status.poison_vulnerability(ctx, monster, 100)

    local definition = {
        resistances = {},
        holiness = {},
    }

    harness.equal(monster_poison.effective_resistance(
        ctx, monster, definition), -1,
        "Virulence lowers nonimmune monster poison resistance")

    definition.resistances = {
        {
            id = "MR_RES_POISON",
            level = 3,
        },
    }

    harness.equal(monster_poison.effective_resistance(
        ctx, monster, definition), 3,
        "Virulence does not break full poison immunity")

    sap.apply(ctx, monster, player)

    harness.truthy(status.sapped(ctx, player),
        "Sap Magic records a saved spellcasting consequence")

    enfeeble.apply_sap_antimagic(ctx, monster)

    harness.equal(ctx:get(monster,
        component.MONSTER_ENFEEBLE).antimagic_aut, 60,
        "Sap Magic can impose six turns of saved monster antimagic")
end

return test
