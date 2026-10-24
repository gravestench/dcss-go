-- Credited monster defeats grant XP through one player owner. Death and
-- Elyvilon pacification use the same progression, training, Abyss exit,
-- evoker recharge, mutation, stat, and HP-drain recovery clocks.
local abyss_exits = require("policy.world.abyss.exits")
local component = require("constants.component")
local draining = require("policy.combat.brands.draining")
local evokers = require("policy.inventory.evokers")
local evolution = require("policy.mutations.evolution")
local stat_loss = require("policy.character.stat_loss")
local temporary_mutations = require("policy.mutations.temporary")

local awards = {}

-- Add credited XP once. Callers decide whether a defeated monster is
-- eligible; this owner ensures all XP-driven player systems see one award.
function awards.monster(ctx, player, xp)
    local progress = ctx:get(player, component.PROGRESSION)
    local training = ctx:get(player, component.SKILL_TRAINING)

    if not progress or not training or progress.total_xp < 0 or
        xp < 0 then
        error("invalid credited monster experience")
    end

    progress.total_xp = progress.total_xp + xp
    training.available_xp = training.available_xp + 10 * xp
    ctx:set(player, component.PROGRESSION, progress)
    ctx:set(player, component.SKILL_TRAINING, training)
    abyss_exits.award(ctx, player, xp)
    evokers.award_xp(ctx, player, xp)
    temporary_mutations.gain_experience(ctx, player, xp)
    evolution.gain_experience(ctx, player, xp)
    stat_loss.gain_experience(ctx, player, xp, training.cost_level)
    draining.recover(ctx, player, xp)
end

return awards
