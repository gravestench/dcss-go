-- The Panitentiary Temple varies its altar cells and demonic scenery at
-- six altar counts. One six-sided source die also selects each variant.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Emit one complete source substitution after the two static shuffles.
-- Rolling even for the six-altar form preserves the source draw sequence.
local function configure(api)
    local selected = tonumber(count.selected(api))
    local die = api:roll(6) + 1

    if selected == 6 then
        api:emit(directives.SUBST, "Zz = B, PpRr = U, QqSs = .")
    elseif selected == 9 then
        if die <= 3 then
            api:emit(directives.SUBST, "PR = B, pr = U, QSZqsz = .")
        else
            api:emit(directives.SUBST, "PSz = B, Zps = U, QRqr = .")
        end
    elseif selected == 12 then
        if die <= 2 then
            api:emit(directives.SUBST, "QR = B, psz = U, PSZqr = .")
        elseif die <= 4 then
            api:emit(directives.SUBST, "PRz = B, Zpr = U, SQsq = .")
        else
            api:emit(directives.SUBST, "PSps = B, QRqr = U, Zz = .")
        end
    elseif selected == 15 then
        if die <= 3 then
            api:emit(directives.SUBST, "PRps = B, QSqr = U, Zz = .")
        else
            api:emit(directives.SUBST, "QRS = B, psz = U, PZqr = .")
        end
    elseif selected == 18 then
        if die <= 2 then
            api:emit(directives.SUBST, "PRpr = B, Zz = U, QSqs = .")
        elseif die <= 4 then
            api:emit(directives.SUBST, "QRps = B, Zz = U, PSqr = .")
        else
            api:emit(directives.SUBST, "PQRS = B, Zz = U, pqrs = .")
        end
    else
        if die <= 3 then
            api:emit(directives.SUBST, "PQRSZ = B, pqrsz = U")
        else
            api:emit(directives.SUBST, "QRpsz = B, PSZrq = U")
        end
    end
end

handler.configure = configure

return handler
