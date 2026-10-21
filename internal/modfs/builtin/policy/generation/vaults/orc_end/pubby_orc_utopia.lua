-- The p glyph is the Elf gate only on the Orc floor that the run's branch
-- schedule chose. Other placements keep the source abandoned feature roll.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local features = require("constants.vault_features")

local handler = {}

-- Read the scheduled entrance fact rather than hardcoding current Elf
-- depth. The generated-floor owner links this feature after placement.
local function choose_elf_gate(api)
    local request = "p = abandoned_shop w:5 / fountain_blue / floor w:30"

    if api:branch_entry(branches.BRANCH_ELF) then
        request = "p = " .. features.ENTER_ELF
    end

    api:emit(directives.KFEAT, request)
end

handler.choose_elf_gate = choose_elf_gate

return handler
