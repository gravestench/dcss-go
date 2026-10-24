package script

import (
	"testing"

	"crawl/internal/modfs"
)

// A sparse Lua layer joins both Xom selectors without editing source gates.
func TestXomEventMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/xom-event-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/xom_event_mod_test.lua")
}
