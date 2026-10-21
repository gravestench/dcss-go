-- One debate scene pairs an Elf priesthood with Beogh; the other pairs
-- sorcerers with Lugonu. The source coin flip chooses the entire side.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep both monster and altar declarations in the same source branch.
local function configure(api)
    if api:one_in(2) then
        api:emit(directives.KMONS, "3 = orc high priest")
        api:emit(directives.KMONS, "4 = deep elf high priest")
        api:emit(directives.KFEAT,
            "4 = altar_vehumet / altar_makhleb / altar_sif_muna")
    else
        api:emit(directives.KMONS, "3 = orc sorcerer")
        api:emit(directives.KMONS, "4 = deep elf sorcerer")
        api:emit(directives.KFEAT, "4 = altar_lugonu")
    end
end

handler.configure = configure

return handler
