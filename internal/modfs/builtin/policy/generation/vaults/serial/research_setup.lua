-- Theory of operation: the ten research DES maps share one source helper.
-- Their own MONS, MARKER, and visual directives stay in the map files. This
-- hook runs at the position of source init_research, adding the caster
-- lottery, map substitutions, and both items at the D glyph. Only the
-- discipline changes between rooms, so each named method calls configure.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local schools = require("constants.spell_schools")
local setup = {}

local elf_casters = "0 = deep elf pyromancer / " ..
    "deep elf zephyrmancer / deep elf knight w:5 / " ..
    "deep elf archer w:5"
local other_casters = "0 = wizard / ogre mage / naga mage w:8 / " ..
    "deep elf pyromancer w:5 / deep elf zephyrmancer w:5"

-- Use the source branch split for the caster on glyph 0. The source
-- SHUFFLE and SUBST directives then decide which terrain and creature
-- positions survive. Two KITEM comma slots stack the book and star item.
local function configure(api, discipline)
    local casters = api:branch_id() == branches.BRANCH_ELF and
        elf_casters or other_casters
    local spell_count = 5 + api:roll(2)
    local book = "D = randbook disc:" .. discipline ..
        " numspells:" .. spell_count .. ", star_item"

    api:emit(directives.KMONS, casters)
    -- The source also masks comma glyphs, but none of these ten maps has
    -- one. Preserve the effective mask on their authored @ entrances.
    api:emit(directives.KMASK, "@ = !no_monster_gen")
    api:emit(directives.SHUFFLE, "abcdefghi")
    api:emit(directives.SUBST, "abcd = c")
    api:emit(directives.SUBST, "efg = v")
    api:emit(directives.SUBST, "hi = b")
    api:emit(directives.COLOUR, "v = white")
    api:emit(directives.TILE, "n = DNGN_TRANSPARENT_STONE_WHITE")
    api:emit(directives.KITEM, book)
end

-- Preserve Fire as the pyrotechnics room's themed book school.
local function fire(api)
    configure(api, schools.FIRE)
end

-- Preserve Ice as the thermodynamics room's themed book school.
local function ice(api)
    configure(api, schools.ICE)
end

-- Preserve Air as the electronics room's themed book school.
local function air(api)
    configure(api, schools.AIR)
end

-- Preserve Earth as the geology room's themed book school.
local function earth(api)
    configure(api, schools.EARTH)
end

-- Preserve Poison as the toxicology room's themed book school.
local function poison(api)
    configure(api, schools.POISON)
end

-- Preserve Necromancy as the thanatology room's themed book school.
local function necromancy(api)
    configure(api, schools.NECROMANCY)
end

-- Preserve Transmutation as the metamorphosis room's themed book school.
local function transmutation(api)
    configure(api, schools.TRANSMUTATION)
end

-- Preserve Translocation as the quantum room's themed book school.
local function translocation(api)
    configure(api, schools.TRANSLOCATION)
end

-- Preserve Summoning as the convocations room's themed book school.
local function summoning(api)
    configure(api, schools.SUMMONING)
end

-- Preserve Hexes as the probablistics room's themed book school.
local function hexes(api)
    configure(api, schools.HEXES)
end

-- Preserve the source's delayed ugly-thing skeleton at the % glyph.
-- The typed record survives generation and saves until decay materializes.
local function decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "%",
        alternatives = "ugly thing skeleton",
    })
end

setup.fire = fire
setup.ice = ice
setup.air = air
setup.earth = earth
setup.poison = poison
setup.necromancy = necromancy
setup.transmutation = transmutation
setup.translocation = translocation
setup.summoning = summoning
setup.hexes = hexes
setup.decay = decay

return setup
