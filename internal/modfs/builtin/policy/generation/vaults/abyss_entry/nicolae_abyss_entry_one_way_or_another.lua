-- Theory of operation: nicolae_abyss_entry_one_way_or_another keeps source geometry in DES.
-- Named hooks preserve the source declaration positions and use
-- the ordinary vault operation stream for deterministic choices.
local directives = require("constants.vault_directives")

local handler = {}

-- Give the entrance guardians the original distortion choices.
local function guardian_weapons(api)
    local elf_weapon = "long sword ego:distortion w:20 | " ..
        "short sword ego:distortion | rapier ego:distortion | " ..
        "dagger ego:distortion"
    local louise_weapon = "long sword ego:distortion | " ..
        "short sword ego:distortion | battleaxe ego:distortion | " ..
        "hand axe ego:distortion | mace ego:distortion | " ..
        "dire flail ego:distortion | glaive ego:distortion w:2"

    api:emit(directives.KMONS, "2 = Louise ; " .. louise_weapon ..
        ", deep elf demonologist ; " .. elf_weapon ..
        " / deep elf sorcerer w:5 ; " .. elf_weapon)
end

handler.guardian_weapons = guardian_weapons

return handler
