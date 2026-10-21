-- Theory of operation: the Arachne lair chooses one of three source themes.
-- Each theme changes terrain, floor art, colour, and guardians together so
-- a single random draw never mixes pieces from separate themes.
local directives = require("constants.vault_directives")

local handler = {}

-- The first source branch paints a blue hall around Arachne.
local function blue_theme(api)
    api:emit(directives.SUBST, [["-? = .]])
    api:emit(directives.SUBST, "'_!^ = Y")
    api:emit(directives.FTILE, "Y = FLOOR_HALL")
    api:emit(directives.COLOUR, "Y = blue")
    api:emit(directives.KMONS, "Z = Arachne, jorogumo")
    api:emit(directives.KMONS,
        "1 = tarantella / wolf spider / redback w:20 / " ..
        "jumping spider w:30 / culicivora")
    api:emit(directives.KMONS, "2 = torpor snail / pharaoh ant")
end

-- The second source branch changes the same room into red rough floor.
local function red_theme(api)
    api:emit(directives.SUBST, "'-! = .")
    api:emit(directives.SUBST, [["_?^ = Y]])
    api:emit(directives.FTILE, "Y = FLOOR_ROUGH_RED")
    api:emit(directives.COLOUR, "Y = red")
    api:emit(directives.KMONS, "Z = Arachne, jorogumo")
    api:emit(directives.KMONS,
        "1 = redback w:20 / wolf spider / tarantella w:30 / " ..
        "jumping spider / culicivora")
    api:emit(directives.KMONS, "2 = entropy weaver / steelbarb worm")
end

-- The final source branch exposes sandstone and stronger flying defenders.
local function brown_theme(api)
    api:emit(directives.SUBST, [['"_ = .]])
    api:emit(directives.SUBST, "-!?^ = Y")
    api:emit(directives.FTILE, "Y = FLOOR_SANDSTONE")
    api:emit(directives.COLOUR, "Y = brown")
    api:emit(directives.KMONS, "Z = Arachne, jorogumo")
    api:emit(directives.KMONS,
        "1 = tarantella / wolf spider w:30 / redback w:20 / " ..
        "jumping spider / culicivora")
    api:emit(directives.KMONS, "2 = meliai / spark wasp w:5")
end

-- Preserve the source's sequential one-in-three, then one-in-two draws.
local function choose_theme(api)
    if api:one_in(3) then
        blue_theme(api)
    elseif api:one_in(2) then
        red_theme(api)
    else
        brown_theme(api)
    end
end

handler.choose_theme = choose_theme

return handler
