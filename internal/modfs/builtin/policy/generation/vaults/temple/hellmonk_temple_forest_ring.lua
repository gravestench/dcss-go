-- The forest ring closes unused clearings and opens the chosen altar sites.
-- The selected count comes from the saved Temple plan, not from a new roll.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Source DES directives remain ordered within each count-specific layout.
local arrangements = {
    ["8"] = {
        {
            kind = directives.SUBST,
            argument = "E = B",
        },
        {
            kind = directives.SUBST,
            argument = "+DFH = c",
        },
    },
    ["9"] = {
        {
            kind = directives.SUBST,
            argument = "EF = B, D = ., H:AG",
        },
    },
    ["12"] = {
        {
            kind = directives.SUBST,
            argument = "EH = B, D = ., F = AGT",
        },
    },
    default = {
        {
            kind = directives.SUBST,
            argument = "EFH = B, D = .",
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
