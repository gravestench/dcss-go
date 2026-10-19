-- Siren and avatar casts share one audible song and player will contest.
-- The avatar alone keeps a continuing song that pulls and calls souls.
-- Source: mon-cast.cc:_siren_goodness and _siren_sing.
-- Example: songs.resolve(ctx, siren, player, plan, false) may add a
-- beholder; the avatar variant also starts its caster-owned song.
local avatar_song = require("policy.combat.monster_avatar_song")
local channels = require("constants.message_channels")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local hex = require("policy.combat.monster_spells.hex")
local mesmerism = require("policy.character.player_mesmerism")
local noise = require("policy.world.noise")
local rage = require("policy.character.rage")
local resistance = require("policy.combat.player_resistance")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")

local songs = {}
local SIGHT_RADIUS = 7
local POWER_PER_HD = 9
local MAX_ENCHANT_POWER = 200
local profile = {
    power_hd_factor = POWER_PER_HD,
    cap = MAX_ENCHANT_POWER,
    is_enchantment = true,
    rng_stream = streams.MONSTER_SPELL,
}

-- Source skips a new song half the time when player and singer can see each
-- other. Repeated luring songs remain available to refresh the beholder.
function songs.plan(ctx, caster, foe, avatar)
    if not foe or not ctx:has(foe, component.PLAYER) or
        not mesmerism.audible(ctx, foe, caster) or
        not avatar and rage.active(ctx, foe) then
        return nil
    end

    if not mesmerism.beheld_by(ctx, foe, caster) and
        senses.player_sees_actor(ctx, caster) and
        ctx:random(streams.MONSTER_SPELL, 2) == 0 then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Noise and the avatar's continuing status happen before the will check.
-- An unseen first singer is heard, but cannot establish a new beholder.
function songs.resolve(ctx, caster, foe, plan, avatar)
    target.require_entity(plan, foe)

    if not mesmerism.audible(ctx, foe, caster) then
        return
    end

    local position = ctx:get(caster, component.POSITION)
    local _, heard = noise.emit(ctx, position, SIGHT_RADIUS, caster)

    if avatar then
        avatar_song.start(ctx, caster, foe)
    end

    local familiar = mesmerism.beheld_by(ctx, foe, caster)
    local seen = senses.player_sees_actor(ctx, caster)

    if seen then
        ctx:emit(channels.SPELL,
            "The " .. display.name(ctx, caster) ..
                (familiar and " chants its luring song." or
                    " chants a haunting song."))
    elseif heard then
        ctx:emit(channels.SOUND,
            familiar and "You hear a luring song." or
                "You hear a haunting song.")
    end

    if not mesmerism.can_start(ctx, foe, caster, true, avatar) or
        not seen and not familiar then
        return
    end

    local resisted = hex.resisted(ctx, caster, foe, profile)
    local state = ctx:get(foe, component.PLAYER_MESMERISM)
    local immune = state and state.immune_aut > 0

    if immune or not familiar and
        (resisted or resistance.clarity(ctx, foe)) then
        ctx:emit(channels.SPELL,
            resistance.clarity(ctx, foe) and "You are unaffected." or
                "You resist the song.")
        return
    end

    mesmerism.apply(ctx, foe, caster)
end

return songs
