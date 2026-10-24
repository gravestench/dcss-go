-- Xom's status-side actions share one effect owner while their durable
-- consequences still live in the ordinary noise and character owners.
local channels = require("constants.message_channels")
local component = require("constants.component")
local events = require("ids.xom_events")
local attributes = require("policy.character.attributes")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local xom_state = require("policy.religion.xom.state")
local noise = require("policy.world.noise")
local player_drain = require("policy.combat.player_drain")
local pseudo_miscast = require("policy.religion.xom.pseudo_miscast")
local streams = require("constants.rng_streams")
local confusion = require("policy.religion.xom.confusion")
local player_confusion = require("policy.magic.player_confusion")
local player_resistance = require("policy.combat.player_resistance")

local effect = {}

-- Source fake_noisy ranges from a shout to Shatter loudness. It ignores
-- Silence at the origin so this is a real monster-hearing action even when
-- the player has silenced their own square.
local function make_noise(ctx, player, stream)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return nil
    end

    local loudness = 12 + ctx:random(stream, 19)

    ctx:emit(channels.RELIGION, "Xom makes a tremendous noise!")
    noise.emit(ctx, position, loudness, player, true)

    return loudness
end

-- A safe action drains only when the selected current stat stays above
-- zero. Penance or boredom allows the source's one-to-three-point loss.
local function lose_stat(ctx, player, stream)
    local field = stats.ORDER[ctx:random(stream, #stats.ORDER) + 1]
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local nasty = xom_state.feels_nasty(worship)
    local amount = nasty and 1 + ctx:random(stream, 3) or 1
    local current = attributes.current(ctx, player)[field]

    if not nasty and current <= amount then
        return nil
    end

    stat_loss.drain(ctx, player, field, amount)
    ctx:emit(channels.RELIGION, "Xom weakens your " .. field .. "!")

    return amount
end

-- Xom gives the player five to seven turns of the ordinary confusion
-- status. At low severity he may also confuse nearby creatures, including
-- allies, exactly as the source's secondary loop allows.
local function confuse_player(ctx, player, severity, stream)
    if player_resistance.clarity(ctx, player) then
        return false
    end

    local already = player_confusion.active(ctx, player)
    local turns = 5 + ctx:random(stream, 3)

    player_confusion.extend(ctx, player, turns)
    ctx:emit(channels.RELIGION,
        already and "Xom makes you more confused!" or
        "Xom confuses you!")

    if ctx:random(stream, math.max(1, severity)) < 30 then
        for _, monster in ipairs(confusion.nearby(ctx, player)) do
            if ctx:random(stream, math.max(1, severity)) <= 30 then
                confusion.monster(ctx, monster, severity, stream)
            end
        end
    end

    return true
end

-- Event IDs, not effect-module names, choose the source behavior. Unknown
-- IDs fail loudly rather than being reported as a harmless Xom action.
function effect.apply(ctx, player, event_id, _severity, request)
    local stream = request and request.stream or streams.RELIGION

    if event_id == events.BAD_NOISE then
        return make_noise(ctx, player, stream)
    end

    if event_id == events.BAD_MISCAST_PSEUDO then
        local message = pseudo_miscast.message(ctx, player, stream)

        ctx:emit(channels.RELIGION, message)

        return message
    end

    if event_id == events.BAD_STATLOSS then
        return lose_stat(ctx, player, stream)
    end

    if event_id == events.BAD_DRAINING then
        ctx:emit(channels.RELIGION, "Xom drains your vitality!")

        return player_drain.apply(ctx, player, 100, stream)
    end

    if event_id == events.BAD_CONFUSION then
        return confuse_player(ctx, player, _severity, stream)
    end

    error("status effect received another Xom event")
end

return effect
