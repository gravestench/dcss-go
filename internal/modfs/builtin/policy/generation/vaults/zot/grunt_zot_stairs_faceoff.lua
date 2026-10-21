-- Faceoff chooses two different draconian colours for opposing teams.
-- The source removes the first colour before its second draw; the two
-- later monster slots must use exactly those chosen colours.
local directives = require("constants.vault_directives")

local handler = {}

-- Swap the first draw with the final array entry, then draw from the
-- shortened range. This preserves source random calls and avoids a
-- rejection loop that would bias both selection and seed progression.
local function choose_teams(api)
    local teams = {
        "black",
        "yellow",
        "green",
        "purple",
        "red",
        "white",
    }
    local first_index = api:roll(#teams) + 1
    local first = teams[first_index]

    teams[first_index] = teams[#teams]

    local second = teams[api:roll(#teams - 1) + 1]

    api:emit(directives.MONS, first .. " draconian")
    api:emit(directives.MONS, first .. " draconian knight")
    api:emit(directives.MONS, second .. " draconian")
    api:emit(directives.MONS, second .. " draconian knight")
end

handler.choose_teams = choose_teams

return handler
