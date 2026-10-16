local directives = require("constants.vault_directives")

local handler = {}

local function choose_beogh(api)
    api:emit(directives.KFEAT, "C = altar_beogh")
    api:emit(directives.SUBST, "DG = I")
    api:emit(directives.KMONS, "1 = orc / nothing")
    api:emit(directives.KMONS, "2 = orc wizard / orc priest / orc / nothing")
    api:emit(directives.KMONS, "3 = orc warrior")
end

local function choose_lugonu(api)
    api:emit(directives.KFEAT, "C = altar_lugonu")
    api:emit(directives.KFEAT, "D = enter_abyss")
    api:emit(directives.KMONS,
        "1 = iron imp / ufetubus / shadow imp / crimson imp / quasit w:5 / white imp w:5")
    api:emit(directives.SUBST, "t : U'''', 23 = 0")
end

local function choose_jiyva(api)
    api:emit(directives.KFEAT, "C = altar_jiyva")
    api:emit(directives.SUBST, "D = .")
    api:emit(directives.KMONS, "1 = jelly / endoplasm")
    api:emit(directives.SUBST, "t : U'''', 23 = 0")
end

local function choose_ordinary(api)
    api:emit(directives.SUBST, "D = V")
    api:emit(directives.KMONS, "1 : gnoll / orc / 0 w:20")
    api:emit(directives.KMONS, "2 : ogre / 0 w:70")
    api:emit(directives.KMONS, "3 : troll / 0 w:70")
    api:emit(directives.SUBST, "t = T")
end

-- Port of arrival/twisted.des:407-431. Exactly one nine-way draw.
local function choose_temple_tenant(api)
    local choice = api:roll(9)

    if choice == 0 then
        choose_beogh(api)
    elseif choice == 1 then
        choose_lugonu(api)
    elseif choice == 2 then
        choose_jiyva(api)
    else
        choose_ordinary(api)
    end
end

handler.choose_temple_tenant = choose_temple_tenant

return handler
