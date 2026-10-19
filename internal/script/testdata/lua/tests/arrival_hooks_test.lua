-- An embedded vault hook expands between COLOUR and KMASK without reordering authored directives.

local des = require("policy.generation.vaults.des")
local hooks = require("policy.generation.vaults.hooks")
local directives = require("constants.vault_directives")

local test = {}

-- Expand a runnable hook between authored directives without moving COLOUR or KMASK.
function test.run()
    local vault = des.parse("vaults/arrival/test_hook.des", [[NAME: test_hook
TAGS: arrival
COLOUR: . = brown
: vault.run("choose_subst")
KMASK: ' = no_item_gen
MAP
@.
ENDMAP
]])

    local api = {
        -- Hook expansion only needs the emission surface; no terminal side effects enter this test.
        emit = function() end,
    }

    local operations = hooks.expand(vault, api)

    assert(#operations == 4)
    assert(operations[1].kind == directives.TAGS)
    assert(operations[2].kind == directives.COLOUR)
    assert(operations[3].kind == directives.SUBST)
    assert(operations[3].argument == "1 = .")
    assert(operations[4].kind == directives.KMASK)
end

return test
