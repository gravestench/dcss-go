-- The ecumenical triangle supports every count from six through fourteen.
-- Its source arrangement uses a separate coin flip only for six altars.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit the chosen entrance shuffle and altar substitution as one ordered
-- pattern. Static decoration, floor tile, and colour directives follow.
local function configure(api)
    local selected = tonumber(count.selected(api))

    if selected == 6 then
        if api:roll(2) == 0 then
            api:emit(directives.SHUFFLE, "DPZ/JMN")
            api:emit(directives.SUBST,
                "DPZ = {, JMNHKR = B, EFLOQS = a")
        else
            api:emit(directives.SHUFFLE, "DPZ/JMN/HKR")
            api:emit(directives.SUBST,
                "DPZ = {, EFLOQS = B, JMN = a, HKR = p")
        end
    elseif selected == 7 then
        api:emit(directives.SUBST,
            "R = {, EFHJKMN = B, D = a, LO = p, PZ = q, QS = r")
    elseif selected == 8 then
        api:emit(directives.SUBST,
            "D = {, HJKPQRSZ = B, EF = a, LO = p, MN = q")
    elseif selected == 9 then
        api:emit(directives.SHUFFLE, "DPZ/JMN")
        api:emit(directives.SUBST,
            "DPZ = {, EHLFKOQRS = B, JMN = a")
    elseif selected == 10 then
        api:emit(directives.SUBST,
            "R = {, DEFHJKLMNO = B, PZ = a, QS = p")
    elseif selected == 11 then
        api:emit(directives.SHUFFLE, "DR")
        api:emit(directives.SUBST,
            "D = {, EFHKLOPQRSZ = B, JMN = a")
    elseif selected == 12 then
        api:emit(directives.SHUFFLE, "DPZ/JMN")
        api:emit(directives.SUBST,
            "DPZ = {, EFHJKLMNOQRS = B")
    elseif selected == 13 then
        api:emit(directives.SHUFFLE, "DJ/KP")
        api:emit(directives.SUBST,
            "D = {, EFHKLMNOPQRSZ = B, J = a")
    else
        api:emit(directives.SHUFFLE, "DR")
        api:emit(directives.SUBST,
            "D = {, EFHJKLMNOPQRSZ = B")
    end
end

handler.configure = configure

return handler
