-- Brain Feed targets the player's mind without launching a beam. Its rare
-- successful cast uses the shared stat-loss owner so recovery survives saves.
-- Source: mon-cast.cc:SPELL_BRAIN_FEED and player-stats.cc:lose_stat.
local channels = require("constants.message_channels")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local spells = require("ids.spells")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")

local effect = {}

-- A monster foe has no player Intelligence to feed on. Save the visible
-- player handle before spending any random draw or changing an attribute.
function effect.plan(ctx, caster, foe)
    if not foe or not ctx:has(foe, component.PLAYER) then
        return nil
    end

    return direct.plan(ctx, caster, foe, spells.SPELL_BRAIN_FEED)
end

-- The source succeeds one time in three, then drains one to three points.
-- The stat-loss owner sets the independent XP recovery timer on first loss.
-- Example: a successful first cast leaves a saved Intelligence drain.
function effect.resolve(ctx, caster, foe, _, plan)
    direct.require(ctx, caster, foe, plan)

    if not ctx:has(foe, component.PLAYER) then
        return
    end

    if ctx:random(streams.MONSTER_SPELL, 3) ~= 0 then
        ctx:emit(channels.SPELL,
            "Something tries to feed on your intellect!")

        return
    end

    local amount = 1 + ctx:random(streams.MONSTER_SPELL, 3)

    stat_loss.drain(ctx, foe, stats.INTELLIGENCE, amount)
    ctx:emit(channels.SPELL, "Something feeds on your intellect!")
end

return effect
