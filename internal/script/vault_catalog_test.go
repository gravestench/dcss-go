package script

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

func TestVaultCatalogAddsAndReplacesDESFiles(t *testing.T) {
	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	baseWorld := akara.NewWorld()
	baseRuntime, err := NewCatalog(baseWorld, bundled)

	if err != nil {
		baseWorld.Close()
		t.Fatal(err)
	}

	baseCount := len(baseRuntime.DefinitionIDs("vaults"))
	baseRuntime.Close()
	baseWorld.Close()

	for _, test := range []struct {
		name       string
		overlay    string
		countDelta int
		wantID     string
		wantWeight lua.LNumber
	}{
		{
			name:       "add new vault",
			overlay:    "testdata/vault-new",
			countDelta: 1,
			wantID:     "zz_new_arrival",
			wantWeight: 4,
		},

		{
			name:       "discover new vault family",
			overlay:    "testdata/vault-custom-family",
			countDelta: 1,
			wantID:     "zz_custom_vault",
			wantWeight: 3,
		},

		{
			name:       "replace one vault",
			overlay:    "testdata/vault-replace",
			countDelta: 0,
			wantID:     "roderic_crop_circles_arrival_small",
			wantWeight: 7,
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			rules, err := modfs.Load(test.overlay)

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

			if count := len(runtime.DefinitionIDs("vaults")); count != baseCount+test.countDelta {
				t.Fatalf("vault count = %d, want %d", count, baseCount+test.countDelta)
			}

			definition := runtime.definitions["vaults"][test.wantID]

			if definition == nil ||
				definition.RawGetString("weight") != test.wantWeight {
				t.Fatalf("vault %s weight did not come from effective DES", test.wantID)
			}
		})
	}
}

func TestVaultCatalogRejectsDuplicateAndInlineLua(t *testing.T) {
	for _, test := range []struct {
		name    string
		overlay string
		want    []string
	}{
		{
			name:    "duplicate NAME",
			overlay: "testdata/vault-duplicate",
			want: []string{
				"vaults/arrival/zz_duplicate.des",
				"vaults/arrival/roderic_crop_circles_arrival_small.des",
			},
		},

		{
			name:    "unported inline Lua",
			overlay: "testdata/vault-inline",
			want: []string{
				"vaults/arrival/zz_inline.des",
				"zz_inline",
				"3",
			},
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			rules, err := modfs.Load(test.overlay)

			if err != nil {
				t.Fatal(err)
			}

			world := akara.NewWorld()
			defer world.Close()

			_, err = NewCatalog(world, rules)

			if err == nil {
				t.Fatal("invalid effective vault catalog loaded")
			}

			for _, want := range test.want {
				if !strings.Contains(err.Error(), want) {
					t.Fatalf("error %q does not mention %q", err, want)
				}
			}
		})
	}
}

func TestVaultCatalogKeepsFullMapsOutOfStartupRegistry(t *testing.T) {
	rules, err := modfs.Load()

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

	definition := runtime.definitions["vaults"]["roderic_crop_circles_arrival_small"]

	if definition == nil {
		t.Fatal("source vault is missing")
	}

	if definition.RawGetString("rows") != lua.LNil ||
		definition.RawGetString("operations") != lua.LNil {
		t.Fatal("full DES body was copied into every runtime at startup")
	}
}

func TestVaultCatalogRejectsMissingHookAtStartup(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-missing-hook")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	_, err = NewCatalog(world, rules)

	if err == nil {
		t.Fatal("catalog accepted a missing Lua vault handler")
	}

	for _, want := range []string{
		"vaults/arrival/zz_missing_hook.des",
		"zz_missing_hook",
		"missing_method",
	} {
		if !strings.Contains(err.Error(), want) {
			t.Fatalf("error %q does not mention %q", err, want)
		}
	}
}
