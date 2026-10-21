-- Source Elf:3 endings call these common helpers in DES declaration order.
-- Keeping the roster and loot policy here lets each ending own only its
-- authored geometry and any additions particular to that map.
local directives = require("constants.vault_directives")

local shared = {}

-- Seven fixed monster slots form the ordinary final-hall encounter.
local function elf_monsters(api)
    api:emit(directives.MONS, "deep elf high priest")
    api:emit(directives.MONS,
        "deep elf demonologist / deep elf elementalist w:3")
    api:emit(directives.MONS,
        "deep elf annihilator / deep elf elementalist w:3")
    api:emit(directives.MONS,
        "deep elf sorcerer / deep elf elementalist w:3")
    api:emit(directives.MONS, "deep elf death mage")
    api:emit(directives.MONS, "deep elf blademaster")
    api:emit(directives.MONS, "deep elf master archer")
end

-- Keyed loot glyphs sometimes receive defenders instead of empty floor.
local function elf_loot_defenders(api)
    api:emit(directives.KMONS,
        "$ = w:450 nothing / deep elf sorcerer / deep elf annihilator")
    api:emit(directives.KMONS,
        "* = w:300 nothing / deep elf annihilator / deep elf death mage")
    api:emit(directives.KMONS,
        "| = w:600 nothing / deep elf demonologist / deep elf death mage")
end

-- Source randomizes gold, starred treasure, and ordinary items only after
-- the ending's own monster and substitution directives have been emitted.
local function elf_loot_randomisation(api)
    api:emit(directives.KFEAT, "$ = $")
    api:emit(directives.KFEAT, "* = *")
    api:emit(directives.KFEAT, "| = |")
    api:emit(directives.SUBST, "| = | *:2")
    api:emit(directives.SUBST, "$ = $:20 *:4 |:1")
    api:emit(directives.SUBST, "* = * |:3")
end

shared.elf_monsters = elf_monsters
shared.elf_loot_defenders = elf_loot_defenders
shared.elf_loot_randomisation = elf_loot_randomisation

return shared
