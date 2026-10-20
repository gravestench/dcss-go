-- Theory of operation: Makhleb's blood cavern flips once between a fresh
-- human corpse beside a hound and a necrophage beside a hound skeleton.
-- The corpse must remain a delayed-decay effect tied to source glyph 1.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")

local handler = {}

-- Draw exactly one source coin flip before emitting either complete scene.
local function choose_blood_scene(api)
    if api:coinflip() then
        api:record(effects.DELAYED_DECAY, {
            glyph = "1",
            alternatives = "human corpse",
        })
        api:emit(directives.KMONS, "2 = hound")
    else
        api:emit(directives.KMONS, "1 = necrophage")
        api:emit(directives.KMONS, "2 = hound skeleton")
    end
end

handler.choose_blood_scene = choose_blood_scene

return handler
