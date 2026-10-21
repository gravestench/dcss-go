-- The Gauntlet's four source coinflips create independent encounter tiers.
-- Separate named functions make the order visible beside each DES hook.
local directives = require("constants.vault_directives")

local handler = {}

-- Steam and acid guardians are the first, easier pair of choices.
local function choose_easy(api)
    if api:coinflip() then
        api:emit(directives.MONS, "pale draconian, steam dragon")
    else
        api:emit(directives.MONS, "grey draconian, wyvern")
    end
end

-- The next roll chooses an acid or swamp encounter independently.
local function choose_medium(api)
    if api:coinflip() then
        api:emit(directives.MONS, "yellow draconian, acid dragon")
    else
        api:emit(directives.MONS, "green draconian, swamp dragon")
    end
end

-- Fire and cold occupy the third source tier; one roll chooses both actors.
local function choose_hard(api)
    if api:coinflip() then
        api:emit(directives.MONS, "red draconian, fire dragon")
    else
        api:emit(directives.MONS, "white draconian, ice dragon")
    end
end

-- The final coinflip changes both the draconian and keyed eighth guard.
local function choose_boss(api)
    if api:coinflip() then
        api:emit(directives.MONS, "black draconian")
        api:emit(directives.KMONS, "8 = storm dragon")
    else
        api:emit(directives.MONS, "purple draconian")
        api:emit(directives.KMONS, "8 = quicksilver dragon")
    end
end

handler.choose_easy = choose_easy
handler.choose_medium = choose_medium
handler.choose_hard = choose_hard
handler.choose_boss = choose_boss

return handler
