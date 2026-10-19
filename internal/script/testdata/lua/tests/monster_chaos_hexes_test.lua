-- Chaos enchantments keep the beam's current attenuated power. The player
-- receives a willpower contest; monster targets skip it as in source DCSS.
local component = require("constants.component")
local confuse = require("policy.combat.monster_hexes.confuse")
local flavours = require("constants.beam_flavours")
local harness = require("tests.harness")
local hex = require("policy.combat.monster_spells.hex")
local hexes = require("policy.combat.monster_area.chaos_hexes")

local test = {}
local caster = 11
local player = 22
local monster = 33

-- Resisting a player arc must consume no status application. A second arc
-- reaching a monster uses its reduced power without a monster will roll.
function test.run()
    local old_resisted = hex.resisted
    local old_apply = confuse.apply
    local observed = {
        saves = {},
        applications = {},
    }
    local ctx = {}

    -- Only the player path may ask the willpower owner for a save.
    function ctx:has(target, id)
        return target == player and id == component.PLAYER
    end

    hex.resisted = function(_, _, target, _, power)
        observed.saves[#observed.saves + 1] = {
            target = target,
            power = power,
        }

        return true
    end

    confuse.apply = function(_, _, target, _, power)
        observed.applications[#observed.applications + 1] = {
            target = target,
            power = power,
        }
    end

    local resisted = hexes.apply(ctx, caster, player,
        flavours.BEAM_CONFUSION, 17)
    local affected = hexes.apply(ctx, caster, monster,
        flavours.BEAM_CONFUSION, 8)

    harness.equal(resisted, false,
        "a player will save rejects the chaos status")
    harness.equal(affected, true,
        "monster chaos enchantments bypass their will save")
    harness.equal(#observed.saves, 1,
        "only the player rolls a will save")
    harness.equal(observed.saves[1].power, 17,
        "the player save uses this arc's power")
    harness.equal(observed.applications[1].target, monster,
        "the unresisted monster receives the effect")
    harness.equal(observed.applications[1].power, 8,
        "the returning arc uses attenuated power")

    local enchant_profile = {
        is_enchantment = true,
        cap = 200,
    }

    harness.equal(hex.enchantment_power(ctx, caster,
        enchant_profile, 8), 8,
        "an explicit arc power bypasses initial caster-HD calculation")

    hex.resisted = old_resisted
    confuse.apply = old_apply
end

return test
