package script

import (
	"strings"
	"testing"
	"time"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

func TestLuaHostComponentUsesAuthoritativeStore(t *testing.T) {
	for _, test := range []struct {
		name        string
		path        string
		system      string
		wantCurrent int
		wantError   string
	}{
		{
			name:        "valid write",
			path:        "testdata/host-bridge",
			system:      "test.host_bridge",
			wantCurrent: 4,
		},

		{
			name:        "invalid write",
			path:        "testdata/host-invalid",
			system:      "test.host_invalid",
			wantCurrent: 3,
			wantError:   "expected integer",
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			rules, err := modfs.Load(test.path)

			if err != nil {
				t.Fatal(err)
			}

			world := akara.NewWorld()
			defer world.Close()

			stores := ecs.Register(world)
			entity, err := world.CreateEntity()

			if err != nil {
				t.Fatal(err)
			}

			health, err := stores.Health.Set(entity, ecs.Health{
				Current: 3,
				Max:     10,
			})

			if err != nil {
				t.Fatal(err)
			}

			runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

			if err != nil {
				t.Fatal(err)
			}

			defer runtime.Close()

			for _, system := range runtime.Systems() {
				if system.Name != test.system {
					continue
				}

				err = system.Update(world, time.Duration(10))

				if test.wantError == "" &&
					err != nil {
					t.Fatal(err)
				}

				if test.wantError != "" &&
					err == nil {
					t.Fatalf("wanted error %q, got nil", test.wantError)
				}

				if test.wantError != "" &&
					!strings.Contains(err.Error(), test.wantError) {
					t.Fatalf("wanted error %q, got %v", test.wantError, err)
				}

				if err := runtime.ApplyPending(); err != nil {
					t.Fatal(err)
				}

				if health.Current != test.wantCurrent {
					t.Fatalf("host HP = %d, want %d", health.Current, test.wantCurrent)
				}

				return
			}

			t.Fatalf("missing system %s", test.system)
		})
	}
}

func TestLuaHostRemovalIsDiscardedAfterCallbackFailure(t *testing.T) {
	rules, err := modfs.Load("testdata/host-remove-fail")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	stores := ecs.Register(world)
	entity, err := world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := stores.Health.Set(entity, ecs.Health{
		Current: 3,
		Max:     10,
	}); err != nil {
		t.Fatal(err)
	}

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	for _, system := range runtime.Systems() {
		if system.Name != "test.host_remove_fail" {
			continue
		}

		err := system.Update(world, 10)

		if err == nil ||
			!strings.Contains(err.Error(), "intentional failure") {
			t.Fatalf("wanted callback failure, got %v", err)
		}

		if !stores.Health.Has(entity) {
			t.Fatal("failed Lua callback removed authoritative health")
		}

		if err := runtime.ApplyPending(); err != nil {
			t.Fatal(err)
		}

		if !stores.Health.Has(entity) {
			t.Fatal("discarded host removal applied at the barrier")
		}

		return
	}

	t.Fatal("missing test.host_remove_fail")
}

func newRuntimeWithHostComponents(
	t *testing.T,
	world *akara.World,
	rules modfs.Ruleset,
	services Services,
) (*Runtime, error) {
	t.Helper()

	stores := ecs.Register(world)
	components := make(map[string]HostComponent)

	for _, binding := range []struct {
		name string
		bind func() (HostComponent, error)
	}{
		{
			name: "core.player",
			bind: func() (HostComponent, error) {
				return BindHostComponent("core.player", stores.Players)
			},
		},

		{
			name: "core.health",
			bind: func() (HostComponent, error) {
				return BindHostComponent("core.health", stores.Health)
			},
		},

		{
			name: "core.magic",
			bind: func() (HostComponent, error) {
				return BindHostComponent("core.magic", stores.Magic)
			},
		},

		{
			name: "core.durations",
			bind: func() (HostComponent, error) {
				return BindHostComponent("core.durations", stores.Durations)
			},
		},

		{
			name: "core.poison",
			bind: func() (HostComponent, error) {
				return BindHostComponent("core.poison", stores.Poison)
			},
		},

		{
			name: "core.regeneration",
			bind: func() (HostComponent, error) {
				return BindHostComponent("core.regeneration", stores.Regeneration)
			},
		},
	} {
		component, err := binding.bind()

		if err != nil {
			t.Fatal(err)
		}

		components[binding.name] = component
	}

	services.HostComponents = components

	if services.ActiveActor == nil {
		services.ActiveActor = func() akara.Entity {
			return 0
		}
	}

	return New(world, rules, services)
}
