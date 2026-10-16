local directives = require("constants.vault_directives")

local handler = {}

-- Port of arrival/small.des:2342-2359.
local function choose_zoo_roster(api)
    if api:one_in(10) then
        api:emit(directives.SHUFFLE, "16")
        api:emit(directives.MONS, "centaur / centaur warrior / yaktaur / yaktaur captain")
        api:emit(directives.MONS, "rat / river rat / hell rat / quokka")
        api:emit(directives.MONS, "imperial myrmidon / servant of whispers / ragged hierophant")
        api:emit(directives.MONS, "worm / tyrant leech")
        api:emit(directives.MONS, "komodo dragon / iguana / basilisk")
        api:emit(directives.MONS, "ettin / frost giant / stone giant / fire giant")
    else
        api:emit(directives.SHUFFLE, "1234567")
        api:emit(directives.MONS, "frilled lizard / iguana / snapping turtle / komodo dragon")
        api:emit(directives.MONS, "hog / jackal / wolf / hound")
        api:emit(directives.MONS, "giant cockroach / scorpion / butterfly / killer bee / redback")
        api:emit(directives.MONS, "swamp worm / lindwurm / worm")
        api:emit(directives.MONS, "swamp drake / hydra / wyvern / rime drake")
        api:emit(directives.MONS, "polar bear / black bear")
        api:emit(directives.MONS, "black mamba / water moccasin / anaconda / salamander")
    end
end

handler.choose_zoo_roster = choose_zoo_roster

return handler
