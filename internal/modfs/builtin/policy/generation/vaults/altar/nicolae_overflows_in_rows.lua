-- Theory of operation: this source map has a fifteen-altar row lattice.
-- Count-dependent substitutions fold the outer positions inward. The order
-- matters: temporary Z is used to swap letters without clobbering a row.
local count = require("policy.generation.vaults.altar.count")
local directives = require("constants.vault_directives")

local handler = {}

-- Preserve the source's conditional sequence before its fixed DF rule and
-- GT shuffle, so each advertised count still yields its authored row shape.
local function arrange_altars(api)
    local selected = count.selected(api, 9, 15)

    if selected >= 13 then
        api:emit(directives.SUBST, "T=F")
    end

    if selected % 2 == 0 then
        api:emit(directives.SUBST, "T=.")
        api:emit(directives.SUBST, "F=Z")
        api:emit(directives.SUBST, "H=F")
        api:emit(directives.SUBST, "Z=H")
    end

    if selected >= 11 then
        api:emit(directives.SUBST, "G=D")
    end

    if selected >= 11 and selected <= 13 then
        api:emit(directives.SUBST, "D=Z")
        api:emit(directives.SUBST, "E=D")
        api:emit(directives.SUBST, "Z=E")
    end
end

handler.arrange_altars = arrange_altars

return handler
