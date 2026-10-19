-- Siren Song asks the shared song owner to sing without an avatar's
-- continuing pull or drowned-soul call.
local songs = require("policy.combat.monster_songs")

local effect = {}

-- Target the selected player only while the siren can be heard.
function effect.plan(ctx, caster, foe)
    return songs.plan(ctx, caster, foe, false)
end

-- Keep the saved target and let the song owner decide whether will,
-- clarity, visibility, or existing mesmerism permits a new beholder.
function effect.resolve(ctx, caster, foe, _, plan)
    songs.resolve(ctx, caster, foe, plan, false)
end

return effect
