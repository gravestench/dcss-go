-- Chaos movement uses the same landing and teleport owners as other spells.
-- A player can resist teleportation, but source Blink has no saving throw.
local component = require("constants.component")
local flavours = require("constants.beam_flavours")
local harness = require("tests.harness")
local hex = require("policy.combat.monster_spells.hex")
local landing = require("policy.combat.monster_displacement.landing")
local movement = require("policy.combat.monster_area.chaos_movement")
local player_teleport = require("policy.magic.player_teleport")
local relocate = require("policy.combat.monster_displacement.relocate")
local monster_teleport = require("policy.magic.effects.zaps.teleport_other")

local test = {}
local caster = 11
local player = 22
local monster = 33

-- Exercise the two targets without manufacturing separate component schemas.
-- Stubs record ownership boundaries, then restore the actual production APIs.
function test.run()
    local old_resisted = hex.resisted
    local old_landing = landing.ordinary
    local old_move = relocate.move
    local old_can_move = relocate.can_move
    local old_toggle = player_teleport.toggle
    local old_schedule = monster_teleport.schedule
    local observed = {
        saves = 0,
        moves = 0,
        player_teleports = 0,
        monster_teleports = 0,
    }
    local ctx = {}

    -- Only the selected player has the player marker in this fixture.
    function ctx:has(target, id)
        return target == player and id == component.PLAYER
    end

    hex.resisted = function()
        observed.saves = observed.saves + 1

        return true
    end

    landing.ordinary = function()
        return 4, 5
    end

    relocate.move = function(_, target, x, y)
        observed.moves = observed.moves + 1
        harness.equal(target, player, "Blink moves the contacted player")
        harness.equal(x, 4, "Blink uses the shared landing selection")
        harness.equal(y, 5, "Blink uses the shared landing selection")

        return true
    end

    relocate.can_move = function()
        return true
    end

    player_teleport.toggle = function()
        observed.player_teleports = observed.player_teleports + 1
    end

    monster_teleport.schedule = function()
        observed.monster_teleports = observed.monster_teleports + 1
    end

    movement.apply(ctx, caster, player, flavours.BEAM_BLINK, 17)
    movement.apply(ctx, caster, player, flavours.BEAM_TELEPORT, 17)
    movement.apply(ctx, caster, monster, flavours.BEAM_TELEPORT, 8)

    harness.equal(observed.saves, 1,
        "only the player's teleportation rolls a saving throw")
    harness.equal(observed.moves, 1,
        "Blink moves immediately through the shared owner")
    harness.equal(observed.player_teleports, 0,
        "a resisted teleport does not schedule the player")
    harness.equal(observed.monster_teleports, 1,
        "Chaos bypasses monster willpower and schedules teleportation")

    hex.resisted = old_resisted
    landing.ordinary = old_landing
    relocate.move = old_move
    relocate.can_move = old_can_move
    player_teleport.toggle = old_toggle
    monster_teleport.schedule = old_schedule
end

return test
