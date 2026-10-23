-- Theory of operation: Zin values purging unclean and chaotic foes while
-- punishing evil, chaos, deliberate mutation, and harm to protected beings.
-- Offenses use source factors; accidental acts with an explicit pardon
-- stop before piety, penance, or Faith RNG changes.
local common = require("policy.religion.conduct.common")
local channels = require("constants.message_channels")
local component = require("constants.component")
local kinds = require("constants.religion_conduct")

local zin = {
    likes = {
        [kinds.KILL_UNCLEAN] = common.kill(
            "you kill unclean or chaotic beings", -4, true),

        [kinds.KILL_CHAOTIC] = common.kill(nil, -4, true),
    },

    dislikes = {
        [kinds.ATTACK_HOLY] = common.peeve(
            "you attack non-hostile holy beings", 1, 1,
            nil, common.holy_matters),

        [kinds.KILL_HOLY] = common.kill_holy_peeve(),

        [kinds.EVIL] = common.peeve(
            "you use evil magic or items", 1, 1,
            " forgives your inadvertent evil act, just this once."),

        [kinds.ATTACK_FRIEND] = common.attack_friend(
            "you attack allies"),

        [kinds.ATTACK_NEUTRAL] = common.peeve(
            "you attack neutral beings", 1, 0,
            " forgives your inadvertent attack on a neutral, just this once."),

        [kinds.ATTACK_IN_SANCTUARY] = common.peeve(
            "you attack monsters in a sanctuary", 1, 1),

        [kinds.UNCLEAN] = common.peeve(
            "you use unclean or chaotic magic or items", 1, 1,
            " forgives your inadvertent unclean act, just this once."),

        [kinds.CHAOS] = common.peeve(
            "you polymorph monsters", 1, 1,
            " forgives your inadvertent chaotic act, just this once."),

        [kinds.DELIBERATE_MUTATING] = common.peeve(
            "you deliberately mutate or transform yourself", 1, 0,
            " forgives your inadvertent chaotic act, just this once."),

        [kinds.CAUSE_GLOWING] = common.peeve(nil, 1, 0),
    },
}

-- The source gives a warning on the first severe glow, then lectures once
-- per action when the player knowingly adds more. Time is saved on the
-- player because Lua modules are shared code, never run-specific storage.
function zin.before(ctx, player, event)
    if event.id ~= kinds.CAUSE_GLOWING then
        return true
    end

    if event.level == 0 then
        ctx:emit(channels.RELIGION,
            "Zin is not enthusiastic about the mutagenic glow surrounding you.")

        return true
    end

    local now = ctx:aut()
    local lecture = ctx:get(player, component.RELIGION_ZIN_GLOW_LECTURE)

    if lecture and lecture.last_aut == now then
        return true
    end

    ctx:emit(channels.RELIGION,
        "Zin does not appreciate the extra mutagenic glow surrounding you!")

    if lecture then
        lecture.last_aut = now
        ctx:set(player, component.RELIGION_ZIN_GLOW_LECTURE, lecture)
    else
        ctx:add(player, component.RELIGION_ZIN_GLOW_LECTURE, {
            last_aut = now,
        })
    end

    return true
end

return zin
