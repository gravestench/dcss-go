-- Theory of operation: source init_forest gives every child vegetation
-- slots, blocks ambient spawns on themed glyphs, and resolves those glyphs
-- into denser trees in Lair than in the early Dungeon. Child-specific MAP
-- geometry and any earlier SHUFFLE/SUBST instructions remain in each DES.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")
local setup = {}

local themed_glyphs = { "1", "2", "E", "D", '"' }

-- Keep each glyph's source property visible: vegetation and the forest
-- area cannot become ordinary teleport destinations or ambient monster cells.
local function protect_vegetation(api)
    for _, glyph in ipairs(themed_glyphs) do
        api:emit(directives.KPROP, glyph .. " = no_tele_into")
    end

    for _, glyph in ipairs(themed_glyphs) do
        api:emit(directives.KMASK, glyph .. " = no_monster_gen")
    end
end

-- A source forest in Lair grows more dense tree glyphs; the Dungeon version
-- leaves more gaps so early floors stay navigable.
local function substitute_vegetation(api, lair)
    if lair then
        api:emit(directives.SUBST, "E = tt12222_")
        api:emit(directives.SUBST, "D = t1222222____")
        api:emit(directives.SUBST, '" = 2:25 _:50')
        api:emit(directives.SUBST, "t : tt12")
    else
        api:emit(directives.SUBST, "E = tt1_")
        api:emit(directives.SUBST, "D = tt11122_____")
        api:emit(directives.SUBST, '" = 1:5 2:10 _:60')
    end

    api:emit(directives.SUBST, "! = @")
    api:emit(directives.SUBST, "_ = .")
end

-- Emit the shared source helper at the authored location in each map.
local function configure(api)
    api:emit(directives.MONS, "bush")
    api:emit(directives.MONS, "plant")
    protect_vegetation(api)
    substitute_vegetation(api, api:branch_id() == branches.BRANCH_LAIR)
end

setup.configure = configure

return setup
