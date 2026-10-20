-- The compact Temple turns lettered sites into altars and scenery in source order.
-- The selected count comes from the saved Temple plan, not from a new roll.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Source DES directives remain ordered within each count-specific layout.
local arrangements = {
    ["12"] = {
        {
            kind = directives.SUBST,
            argument = "BCEFHIKLNOQR = _",
        },
        {
            kind = directives.SUBST,
            argument = "AGM = p, DJP = q",
        },
        {
            kind = directives.SHUFFLE,
            argument = "pq / rr / rr",
        },
        {
            kind = directives.SUBST,
            argument = "p : TG, q : TG, r = .",
        },
    },
    ["15"] = {
        {
            kind = directives.SUBST,
            argument = "BCDEFHIJKLNOPQR = _",
        },
        {
            kind = directives.SUBST,
            argument = "AGM : TG",
        },
    },
    ["18"] = {
        {
            kind = directives.SUBST,
            argument = "ABCDEFGHIJKLMNOPQR = _",
        },
    },
    default = {
        {
            kind = directives.SUBST,
            argument = "ABCGHIMNO = _, DEFJKLPQR = Y",
        },
    },
}

-- Apply only the selected arm. Emitting through the vault API keeps the
-- source order relative to the static directives around this hook.
local function configure(api)
    local selected = arrangements[count.selected(api)] or arrangements.default or {}

    for _, operation in ipairs(selected) do
        api:emit(operation.kind, operation.argument)
    end
end

handler.configure = configure

return handler
