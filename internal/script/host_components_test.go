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
	components, err := BindHosts([]HostBinding{
		Host("core.position", stores.Positions),
		Host("core.actor", stores.Actors),
		Host("core.player_turn", stores.PlayerTurn),
		Host("core.monster_energy", stores.MonsterEnergy),
		Host("core.health", stores.Health),
		Host("core.magic", stores.Magic),
		Host("core.skills", stores.Skills),
		Host("core.skill_training", stores.SkillTraining),
		Host("core.player", stores.Players),
		Host("core.progression", stores.Progression),
		Host("core.attributes", stores.Attributes),
		Host("core.durations", stores.Durations),
		Host("core.poison", stores.Poison),
		Host("core.regeneration", stores.Regeneration),
		Host("core.combat", stores.Combat),
		Host("core.constricted", stores.Constricted),
		Host("core.equipment_delay", stores.Equipment),
		Host("core.ai", stores.AI),
		Host("core.follower", stores.Followers),
		Host("core.item", stores.Items),
		Host("core.corpse", stores.Corpses),
		Host("core.carried_by", stores.CarriedBy),
		Host("core.equipped", stores.Equipped),
		Host("core.intent", stores.Intents),
	})

	if err != nil {
		t.Fatal(err)
	}

	services.HostComponents = components

	if services.ActiveActor == nil {
		services.ActiveActor = func() akara.Entity {
			return 0
		}
	}

	return New(world, rules, services)
}
