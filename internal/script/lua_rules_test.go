package script

import (
	"context"
	"path"
	"strings"
	"testing"
	"time"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

// Lua rules tests execute in the production VM with production schemas.
// The Go runner supplies isolation and reports the Lua assertion location.
func TestLuaRules(t *testing.T) {
	rules, err := modfs.Load("testdata/lua")

	if err != nil {
		t.Fatal(err)
	}

	for _, name := range rules.Paths() {
		if !strings.HasPrefix(name, "tests/") ||
			!strings.HasSuffix(name, "_test.lua") {
			continue
		}

		t.Run(path.Base(name), func(t *testing.T) {
			runLuaRule(t, rules, name)
		})
	}
}

func TestModJewelleryRule(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/mod-jewellery")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/jewellery_mod_test.lua")
	runLuaRule(t, rules, "tests/reflector_mod_test.lua")
}

func runLuaRule(t *testing.T, rules modfs.Ruleset, name string) {
	t.Helper()

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(
		t,
		world,
		rules,
		Services{
			Emit: func(string, string) {},
			Random: func(_ string, _ int) (int, error) {
				return 0, nil
			},
			RandomWord: func(string) uint64 {
				return 0
			},
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	module, err := runtime.runModule(name)

	if err != nil {
		t.Fatal(err)
	}

	table, ok := module.(*lua.LTable)

	if !ok {
		t.Fatalf("%s must return a test module", name)
	}

	run, ok := runtime.state.GetField(table, "run").(*lua.LFunction)

	if !ok {
		t.Fatalf("%s must have a named run function", name)
	}

	limit, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	runtime.state.SetContext(limit)
	err = runtime.state.CallByParam(lua.P{
		Fn:      run,
		NRet:    0,
		Protect: true,
	}, runtime.context)

	runtime.state.RemoveContext()

	if err != nil {
		runtime.DiscardPending()
		t.Fatal(err)
	}

	if err := runtime.ApplyPending(); err != nil {
		t.Fatal(err)
	}
}
