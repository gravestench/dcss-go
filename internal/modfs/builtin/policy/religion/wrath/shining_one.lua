-- The Shining One calls permanent hostile angels, raises a saved Silence
-- field, blasts nearby actors with holy flame, or broadcasts a loud shout.
-- Divine flame has no actor source, as in the original game's KILL_MISC blast.
local component = require("constants.component")
local cleansing_flame = require("policy.combat.cleansing_flame")
local channels = require("constants.message_channels")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local noise = require("policy.world.noise")
local spells = require("ids.spells")
local statuses = require("policy.magic.effects.statuses.player")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")

local shining_one = {}

-- summon_holy_warrior(100, true) chooses Angel or Daeva uniformly. Each
-- attempted body has the Shining One's permanent hostile wrath source.
local function warriors(ctx, player)
    local level = ctx:get(player, component.PROGRESSION).level
    local fifth = math.floor(level / 5)
    local count = 1 + (fifth > 0 and
        ctx:random(streams.CARDS, fifth) or 0) +
        ctx:random(streams.CARDS, 3)
    local created = 0

    for _ = 1, count do
        local kind = ctx:random(streams.CARDS, 2) == 0 and
            monsters.MONS_ANGEL or monsters.MONS_DAEVA

        if summons.hostile(ctx, player, gods.SHINING_ONE, kind) then
            created = created + 1
        end
    end

    ctx:emit(channels.RELIGION, created > 0 and
        "The Shining One sends the divine host to punish you for your evil ways!" or
        "The Shining One's divine host fails to appear.")
end

-- Source cast_silence(25) runs the same status caster as the scroll, with
-- spell-stream duration rolls and the saved player aura.
local function squelch(ctx, player)
    ctx:emit(channels.RELIGION,
        "You feel the Shining One's silent rage upon you!")
    statuses.cast(ctx, player, spells.SPELL_SILENCE, 25)
end

-- The seven source slots give warriors three, cleansing flame two, and
-- shout and silence one each. The god blast uses no actor caster, matching
-- its KILL_MISC source while retaining the ordinary holy area rules.
function shining_one.apply(ctx, player)
    local choice = ctx:random(streams.CARDS, 7)

    if choice < 3 then
        warriors(ctx, player)
    elseif choice < 5 then
        local level = ctx:get(player, component.PROGRESSION).level
        local power = 5 + math.floor(level * 7 / 12)

        ctx:emit(channels.RELIGION,
            "The Shining One blasts you with cleansing flame!")
        cleansing_flame.blast(ctx,
            ctx:get(player, component.POSITION), power, nil)
    elseif choice == 5 then
        ctx:emit(channels.RELIGION,
            'The Shining One booms out: "Take the path of righteousness! REPENT!"')
        noise.emit(ctx, ctx:get(player, component.POSITION), 25, player)
    else
        squelch(ctx, player)
    end

    return true
end

return shining_one
