-- Pleasuredromes uses the same authored map on ordinary deep floors and at
-- the Zot approach. Its depth formula changes four trap/monster patterns;
-- the portal substitutions apply only when Zot opens on this floor.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

-- Clamp the source absolute-depth ramp before emitting four related
-- substitutions. These operate on MAP glyphs before entity projection.
local function configure(api)
    local pressure = math.max(math.min(5 +
        (api:absolute_depth() - 23) * 5, 30), 10)

    api:emit(directives.SUBST, "2 = 2:20 3:" .. pressure)
    api:emit(directives.SUBST, "5 = 5:20 6:" .. pressure)
    api:emit(directives.SUBST,
        "1 = 1:" .. 40 - pressure .. " 2:" .. pressure - 5)
    api:emit(directives.SUBST,
        "4 = 4:" .. 40 - pressure .. " 5:" .. pressure - 5)
end

-- A scheduled Zot entry opens the gate and chooses which of the source's
-- three portal glyphs survives. Otherwise those glyphs remain untouched.
local function zot_portal(api)
    if not api:branch_entry(branches.BRANCH_ZOT) then
        return
    end

    api:emit(directives.SUBST, ")]}> = ., \" = `")
    api:emit(directives.NSUBST, "' = 1:Z / 2:^ / *:`")
end

handler.configure = configure
handler.zot_portal = zot_portal

return handler
