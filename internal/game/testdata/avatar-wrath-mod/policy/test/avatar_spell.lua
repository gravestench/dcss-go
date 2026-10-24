-- Exercise the production god-avatar policy through the ordinary game
-- transaction boundary. The test mod only chooses a spell; it does not
-- redefine the avatar schema or its lasting-status implementation.
local avatar = require("policy.religion.wrath.avatar")
local gods = require("constants.gods")
local spells = require("ids.spells")

local spell = {}

-- Sticky Flame is useful here because the source must outlive the cast.
function spell.cast(ctx)
    avatar.cast(ctx, ctx:player(), gods.MAKHLEB,
        spells.SPELL_STICKY_FLAME)

    return {}
end

-- The self spell creates real summoned actors, whose saved owner must be
-- the same inert god source used by lasting damage effects.
function spell.ball_lightning(ctx)
    avatar.cast(ctx, ctx:player(), gods.VEHUMET,
        spells.SPELL_CONJURE_BALL_LIGHTNING)

    return {}
end

register.policy({
    id = "test.avatar_spell",
    run = spell.cast,
})

register.policy({
    id = "test.avatar_ball_lightning",
    run = spell.ball_lightning,
})

return spell
