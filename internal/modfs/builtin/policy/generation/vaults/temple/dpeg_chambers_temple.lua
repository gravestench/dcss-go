-- The chambers shuffle paired entrances only for the smaller altar arrangement.
-- The selected count comes from the saved Temple plan, not from a new roll.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Source DES directives remain ordered within each count-specific layout.
local arrangements = {
    ["14"] = {
        {
            kind = directives.SUBST,
            argument = "CDEF = B, '\"-~ = .",
        },
    },
    ["10"] = {
        {
            kind = directives.SHUFFLE,
            argument = "C' / D\" / E- / F~",
        },
        {
            kind = directives.SUBST,
            argument = "CD = B, '\" = ., EF-~ = v",
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
