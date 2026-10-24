-- The Horn of Geryon calls temporary Hell Beasts. Its howl and evil
-- conduct happen even when surrounding terrain leaves no spawn cell.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local conduct = require("policy.religion.conduct")
local conduct_ids = require("constants.religion_conduct")
local effects = require("policy.inventory.evokers.effects")
local items = require("ids.items")
local monsters = require("ids.monsters")
local noise = require("policy.world.noise")
local power = require("policy.magic.power")
local silence = require("policy.world.silence")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")

local horn = {}
horn.summon_kind_id = monsters.MONS_HELL_BEAST

-- Source evoke.cc rolls three independent thresholds. The argument is
-- Evocations at scale ten, not the level shown in the skill menu.
function horn.count(ctx, adjusted_power)
    local count = 1

    for _, threshold in ipairs({ 130, 180, 230 }) do
        if adjusted_power + ctx:random(streams.EVOKER, 90) > threshold then
            count = count + 1
        end
    end

    return count
end

-- Silence cancels before spending a turn or charge; a horn cannot make
-- noise through even a neighboring monster's silence field.
function horn.prepare(ctx, player)
    if silence.actor(ctx, player) then
        return "You can't produce a sound!"
    end
end

-- The source rolls allegiance separately for each beast. No available
-- spawn square still counts as a successful horn use and spends its charge.
function horn.resolve(ctx, player)
    local position = ctx:get(player, component.POSITION)
    local adjusted_power = power.training(ctx, player,
        skills.SK_EVOCATIONS, 10)
    local created = false

    ctx:emit(channels.SOUND, "You produce a hideous howling noise!")
    noise.emit(ctx, position, 15, player)
    conduct.record(ctx, {
        id = conduct_ids.EVIL,
        level = 3,
        known = true,
    })

    for _ = 1, horn.count(ctx, adjusted_power) do
        local friendly = adjusted_power > 0 and
            ctx:random(streams.EVOKER, adjusted_power) > 7
        local attitude = friendly and attitudes.FRIENDLY or
            attitudes.HOSTILE
        local beast = summons.spawn(ctx, player,
            items.MISC_HORN_OF_GERYON, monsters.MONS_HELL_BEAST,
            3, nil, {
                attitude = attitude,
                source_category = categories.ITEMS,
                stream = streams.EVOKER,
                silent_failure = true,
            })

        created = beast ~= nil or created
    end

    if not created then
        ctx:emit(channels.SOUND, "Nothing answers your call.")
    end

    return {
        charge = true,
        practice = 3,
    }
end

effects.add(items.MISC_HORN_OF_GERYON, horn)

return horn
