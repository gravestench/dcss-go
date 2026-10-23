-- Theory of operation: Trog punishes voluntary spell study, casting, and
-- wizardly items. Kill appreciation is declared separately from these
-- peeves so the common conduct owner can retain dislike-then-like order.
local kinds = require("constants.religion_conduct")
local common = require("policy.religion.conduct.common")
local distributed = require("policy.character.distributed_training")

local likes = common.kills()

-- Gnoll magic training is involuntary under Distributed Training. The
-- source skips Trog's practice peeve rather than docking accidental piety.
local function voluntary_practice(ctx, player, event)
    if event.id == kinds.SPELL_PRACTISE and
        distributed.active(ctx, player) then
        return false
    end

    return true
end

likes[kinds.KILL_WIZARD] = {
    description = "you kill wizards and other users of magic",
    bonus = -6,
    denom_bonus = 10,
    xl_denom = 0,
    message = " appreciates your killing of a magic user.",
}

local trog = {
    before = voluntary_practice,
    likes = likes,
    dislikes = {
        [kinds.SPELL_MEMORISE] = {
            description = "you memorise spells",
            loss_factor = 10,
            penance_factor = 10,
        },

        [kinds.SPELL_CASTING] = {
            description = "you attempt to cast spells",
            loss_factor = 1,
            penance_factor = 5,
        },

        [kinds.SPELL_PRACTISE] = {
            description = "you train magic skills",
            loss_factor = 1,
            penance_factor = 0,
            message = " does not appreciate your training of magic skills!",
        },

        [kinds.WIZARDLY_ITEM] = {
            description = "you use magical staves or pain-branded weapons",
            loss_factor = 1,
            penance_factor = 0,
            message = " does not appreciate your use of wizardly items!",
        },
    },
}

return trog
