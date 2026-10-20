-- The X-shaped Temple changes which arms hold altars and which remain decoration.
-- The selected count comes from the saved Temple plan, not from a new roll.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Source DES directives remain ordered within each count-specific layout.
local arrangements = {
    ["12"] = {
        {
            kind = directives.SUBST,
            argument = "D = B, E = ., g : Ghhh, h : tTV.....",
        },
    },
    ["16"] = {
        {
            kind = directives.SUBST,
            argument = "E = B, Dgh = .",
        },
    },
    default = {
        {
            kind = directives.SUBST,
            argument = "D = B, E = ., g : Ghhh, h : tTV.....",
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
