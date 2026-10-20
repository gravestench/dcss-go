-- Theory of operation: Okawaru and Trog's shared altar stages a skirmish.
-- At absolute depth eight, the source replaces early gnolls and orcs with
-- equipped orc warriors while preserving their berserk-rage potion theme.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit one MONS slot so its alternatives remain one weighted source choice.
local function choose_warriors(api)
    if api:absolute_depth() < 8 then
        api:emit(directives.MONS,
            "gnoll ; club | spear | nothing . potion of berserk rage / " ..
            "orc ; club | hand axe | short sword . " ..
            "leather armour | nothing . potion of berserk rage")
    else
        api:emit(directives.MONS,
            "orc warrior ; club | hand axe | short sword . " ..
            "leather armour | ring mail . potion of berserk rage")
    end
end

handler.choose_warriors = choose_warriors

return handler
