-- The circular Temple first chooses altar rings from the saved count,
-- then independently chooses whether its centre is filled, absent, or wet.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Change the authored rings before the static W substitution. Each case
-- has its own entrance cell and number of exposed altar glyphs.
local function choose_altars(api)
    local selected = tonumber(count.selected(api))

    if selected == 10 then
        api:emit(directives.SUBST, "C = B, E = G, DH<IJ = .")
        api:emit(directives.NSUBST, "F = 1:{ / *:.")
    elseif selected == 14 then
        api:emit(directives.SUBST, "CDEF = B, CHIJ = ., < = {")
    elseif selected == 18 then
        api:emit(directives.SUBST, "BDCEFH = ., IJ = B, < = {")
    elseif selected == 21 then
        api:emit(directives.SUBST, "BDCEFI = ., HJ = B, < = {")
    end
end

-- Preserve the source thirty-way centre draw. The last seven outcomes
-- flood the ring, with five water outcomes and two lava outcomes.
local function choose_ring(api)
    local draw = api:roll(30)

    if draw < 5 then
        api:emit(directives.SUBST, "mwWTvbG[ = c")
    elseif draw < 23 then
        api:emit(directives.SUBST, "mwW = ., [ = {")
    else
        api:emit(directives.SUBST, "TW[ = w")

        if draw < 28 then
            api:emit(directives.NSUBST, "w = 6:1w / *:w")
            api:emit(directives.COLOUR, "m = lightblue")
            api:emit(directives.COLOUR, "c = blue")
        else
            api:emit(directives.SUBST, "w = l")
            api:emit(directives.NSUBST, "l = 6:2l / *:l")
            api:emit(directives.COLOUR, "m = lightred")
            api:emit(directives.COLOUR, "c = red")
        end
    end
end

handler.choose_altars = choose_altars
handler.choose_ring = choose_ring

return handler
