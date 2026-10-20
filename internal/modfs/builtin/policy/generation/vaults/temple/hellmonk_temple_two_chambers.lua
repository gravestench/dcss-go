-- The paired chambers redistribute altars between their connected rooms.
-- The selected count comes from the saved Temple plan, not from a new roll.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Source DES directives remain ordered within each count-specific layout.
local arrangements = {
    ["6"] = {
        {
            kind = directives.SUBST,
            argument = "D = B, F = K",
        },
    },
    ["7"] = {
        {
            kind = directives.SUBST,
            argument = "DK = B, F = K",
        },
    },
    ["8"] = {
        {
            kind = directives.SUBST,
            argument = "FJ = B, D = J",
        },
    },
    ["12"] = {
        {
            kind = directives.SUBST,
            argument = "DF = B",
        },
    },
    default = {
        {
            kind = directives.SUBST,
            argument = "DFJK = B",
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
