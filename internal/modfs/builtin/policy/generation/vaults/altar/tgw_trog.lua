-- Theory of operation: Trog's moth scene keeps two monster slots. The
-- first always contains a moth of wrath; absolute depth sixteen changes
-- the second from minor creatures to an elephant or beetle.
local directives = require("constants.vault_directives")

local handler = {}

-- Retain both slot numbers by emitting the paired source MONS declarations.
local function choose_beasts(api)
    api:emit(directives.MONS, "moth of wrath")

    if api:absolute_depth() < 16 then
        api:emit(directives.MONS, "rat / worm w:5")
    else
        api:emit(directives.MONS,
            "dire elephant / boulder beetle w:5")
    end
end

handler.choose_beasts = choose_beasts

return handler
