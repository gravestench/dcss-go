-- Theory of operation: only an acting avatar with a saved song gets one
-- pulse, before its next AI choice. This keeps pull and summons tied to
-- caster actions and allows save/restore to resume the same song.
-- Example: a silenced avatar loses the song before choosing another spell.
local component = require("constants.component")
local song = require("policy.combat.monster_avatar_song")

local system = {}

-- Process one saved song before AI can cast again or move the singer.
function system.update(ctx, actor, elapsed_aut)
    song.tick(ctx, actor, elapsed_aut)
end

register.system({
    id = "combat.monster_avatar_song.tick",
    scope = "active",
    query = { component.MONSTER_AVATAR_SONG },
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
