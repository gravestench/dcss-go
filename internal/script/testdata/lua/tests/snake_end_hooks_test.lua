-- The Pools source script chooses one coherent terrain and monster theme.
-- Its single hook must never emit mixed fire and water declarations.
local directives = require("constants.vault_directives")
local handler = require(
    "policy.generation.vaults.snake_end.grunt_snake_rune_pools")
local harness = require("tests.harness")

local test = {}

-- Drive only the source one-in-three decision; production hook code owns
-- all resulting directives and their order.
local function emitted_theme(fire)
    local emitted = {}
    local api = {}

    function api:one_in(bound)
        harness.equal(bound, 3, "source fire chance")

        return fire
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    handler.choose_theme(api)

    return emitted
end

-- The keyed feature is the decisive terrain fact; monster and substitution
-- counts pin the rest of each source branch without copying every string.
function test.run()
    local fire = emitted_theme(true)
    local water = emitted_theme(false)

    harness.equal(#fire, 9, "fire declarations")
    harness.equal(#water, 6, "water declarations")
    harness.equal(fire[7].kind, directives.KFEAT,
        "fire keyed terrain")
    harness.equal(fire[7].argument, "7 = l", "fire paints lava")
    harness.equal(water[5].kind, directives.KFEAT,
        "water keyed terrain")
    harness.equal(water[5].argument, "7 = w", "water paints water")
end

return test
