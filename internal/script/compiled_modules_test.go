package script

import (
	"os"
	"testing"

	"crawl/internal/modfs"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

func TestCompiledModulesKeepOverlaySourcesAndVMStateSeparate(t *testing.T) {
	testCases := []struct {
		name   string
		modDir string
		source string
	}{
		{
			name:   "first overlay",
			modDir: "testdata/cache-overlay-a",
			source: "A",
		},

		{
			name:   "second runtime with first overlay",
			modDir: "testdata/cache-overlay-a",
			source: "A",
		},

		{
			name:   "same path with different source",
			modDir: "testdata/cache-overlay-b",
			source: "B",
		},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			rules, err := modfs.Load(testCase.modDir)

			if err != nil {
				t.Fatal(err)
			}

			world := akara.NewWorld()
			defer world.Close()

			runtime, err := NewCatalog(world, rules)

			if err != nil {
				t.Fatal(err)
			}

			defer runtime.Close()

			for call := 1; call <= 2; call++ {
				result, err := runtime.Policy("test.cache_probe", nil)

				if err != nil {
					t.Fatal(err)
				}

				if result["source"] != testCase.source || result["calls"] != int64(call) {
					t.Fatalf("policy call %d = %#v", call, result)
				}
			}
		})
	}
}

func TestCompiledModulesRunConcurrentlyWithSeparateVMState(t *testing.T) {
	data, err := os.ReadFile("testdata/cache_probe.lua")

	if err != nil {
		t.Fatal(err)
	}

	for index := range 4 {
		t.Run(string(rune('A'+index)), func(t *testing.T) {
			t.Parallel()

			state := lua.NewState()
			defer state.Close()

			proto, err := compiledPrototype(state, "testdata/cache_probe.lua", data)

			if err != nil {
				t.Fatal(err)
			}

			if err := state.CallByParam(lua.P{
				Fn:      state.NewFunctionFromProto(proto),
				NRet:    1,
				Protect: true,
			}); err != nil {
				t.Fatal(err)
			}

			next, ok := state.Get(-1).(*lua.LFunction)
			state.Pop(1)

			if !ok {
				t.Fatal("compiled module did not return a function")
			}

			for call := 1; call <= 2; call++ {
				if err := state.CallByParam(lua.P{
					Fn:      next,
					NRet:    1,
					Protect: true,
				}); err != nil {
					t.Fatal(err)
				}

				got := state.Get(-1)
				state.Pop(1)

				if got != lua.LNumber(call) {
					t.Fatalf("call %d = %v", call, got)
				}
			}
		})
	}
}
