package script

import (
	"strings"
	"testing"
	"time"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

func TestLoadTreeSkipsDES(t *testing.T) {
	rules, err := modfs.Load("testdata/des-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/des_mod_test.lua")
}

func TestOverlayCanRegisterComponentAndSystem(t *testing.T) {
	rules, err := modfs.Load("testdata/valid-mod")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	entity, err := world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	systems := runtime.Systems()

	var counter *System

	for index := range systems {
		if systems[index].Name == "test.count_turns" {
			counter = &systems[index]
			break
		}
	}

	if counter == nil {
		t.Fatalf("test.count_turns missing from Lua systems: %+v", systems)
	}

	if _, err := world.AddSystem(*counter); err != nil {
		t.Fatal(err)
	}

	if err := world.Update(time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	store := runtime.Components()["test.counter"]

	if store.Has(entity) {
		t.Fatal("structural add was visible before the barrier")
	}

	if err := runtime.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if err := world.Update(time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	if err := runtime.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	component, found := store.Get(entity)

	if !found {
		t.Fatal("Lua component was not attached")
	}

	value, err := component.Get("value")

	if err != nil {
		t.Fatal(err)
	}

	if value != int64(2) {
		t.Fatalf("Lua system did not update component: %v, %v", value, err)
	}
}

func TestLuaFailureDiscardsQueuedStructuralChange(t *testing.T) {
	rules, err := modfs.Load("testdata/failing-mod")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	entity, err := world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	for _, system := range runtime.Systems() {
		if _, err := world.AddSystem(system); err != nil {
			t.Fatal(err)
		}
	}

	err = world.Update(time.Duration(10))

	if err == nil {
		t.Fatal("Lua system failure was ignored")
	}

	if !strings.Contains(err.Error(), "test.fail") ||
		!strings.Contains(err.Error(), "intentional failure") {
		t.Fatalf("failure has no system context: %v", err)
	}

	if err := runtime.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if runtime.Components()["test.counter"].Has(entity) {
		t.Fatal("failed Lua callback left a queued component")
	}
}

func TestLuaBarrierRejectsMissingEntityBeforeAnyComponentChanges(t *testing.T) {
	rules, err := modfs.Load("testdata/valid-mod")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	first, err := world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	second, err := world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	for _, system := range runtime.Systems() {
		if _, err := world.AddSystem(system); err != nil {
			t.Fatal(err)
		}
	}

	if err := world.Update(time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	if !world.DestroyEntity(second) {
		t.Fatal("queued entity could not be destroyed")
	}

	err = runtime.ApplyPending()

	if err == nil {
		t.Fatal("missing target was accepted")
	}

	if runtime.Components()["test.counter"].Has(first) {
		t.Fatal("barrier partially applied a batch")
	}
}

func TestLoopingLuaSystemTimesOut(t *testing.T) {
	rules, err := modfs.Load("testdata/loop-mod")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	if _, err := world.CreateEntity(); err != nil {
		t.Fatal(err)
	}

	for _, system := range runtime.Systems() {
		if _, err := world.AddSystem(system); err != nil {
			t.Fatal(err)
		}
	}

	err = world.Update(time.Duration(10))

	if err == nil {
		t.Fatal("looping Lua system did not stop")
	}

	if !strings.Contains(err.Error(), "deadline exceeded") {
		t.Fatalf("loop failure has no deadline context: %v", err)
	}
}

func TestLuaRuntimeRejectsUnknownComponentAndOrderingCycle(t *testing.T) {
	cases := []struct {
		name      string
		directory string
		want      string
	}{
		{
			name:      "unknown component",
			directory: "testdata/invalid-unknown",
			want:      "unknown component",
		},

		{
			name:      "cycle",
			directory: "testdata/invalid-cycle",
			want:      "cycle",
		},
	}

	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			rules, err := modfs.Load(test.directory)

			if err != nil {
				t.Fatal(err)
			}

			world := akara.NewWorld()
			defer world.Close()

			_, err = newRuntimeWithHostComponents(t, world, rules, Services{})

			if err == nil {
				t.Fatalf("wanted %q failure", test.want)
			}

			if !strings.Contains(err.Error(), test.want) {
				t.Fatalf("wanted %q failure, got %v", test.want, err)
			}
		})
	}
}
