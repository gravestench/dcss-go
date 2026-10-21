-- One source helper configures all sixteen Spider jumping islands. The
-- parent selects them through their static nico_jumpspide tag; each child
-- still owns its own shape, local substitutions, and source weight.
local directives = require("constants.vault_directives")

local handler = {}

-- The source helper first names its monster draw, then shapes island
-- water and clears unused placeholder cells. Tags are static DES metadata
-- so the parent can discover helpers before this runtime hook executes.
local function configure(api)
    api:emit(directives.MONS, "jumping spider")
    api:emit(directives.NSUBST, "1 = 3=1 / 1. / 1.. / .")
    api:emit(directives.SUBST, "w = w:10 W:1")
    api:emit(directives.SUBST, "Z = w")
    api:emit(directives.CLEAR, "-")
end

-- Source omits allow_dup on unusual shapes and the sole stair helper.
local function configure_unique(api)
    configure(api)
end

-- Repeatable children share the same terrain and monster setup. Their
-- allow_dup tag is declared in DES before the parent draws a helper.
local function configure_repeatable(api)
    configure(api)
end

handler.configure_unique = configure_unique
handler.configure_repeatable = configure_repeatable

return handler
