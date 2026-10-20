-- Theory of operation: Trog's butcher uses an orc and a potential animal
-- victim. At absolute depth six, the orc becomes a warrior and the animal
-- pool changes. Its separate shaft rule still runs through depth_rules.
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the two source MONS slots in order for either depth tier.
local function choose_butcher(api)
    if api:absolute_depth() < 6 then
        api:emit(directives.MONS, "orc ; hand axe . animal skin")
        api:emit(directives.MONS,
            "rat / frilled lizard / quokka w:20")
    else
        api:emit(directives.MONS,
            "orc warrior ; war axe . animal skin")
        api:emit(directives.MONS, "iguana / scorpion")
    end
end

handler.choose_butcher = choose_butcher

return handler
