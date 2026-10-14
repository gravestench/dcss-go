package game

import (
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/gravestench/akara"
)

func TestLuaSystemCanRunBetweenExistingGoSystems(t *testing.T) {
	noop := akara.SystemFunc(func(*akara.World, time.Duration) error {
		return nil
	})

	specs := []systemSpec{
		{
			name:    "go.first",
			system:  noop,
			goOrder: true,
		},

		{
			name:    "go.second",
			system:  noop,
			goOrder: true,
		},

		{
			name:   "lua.middle",
			system: noop,
			after:  []string{"go.first"},
			before: []string{"go.second"},
		},
	}

	ordered, err := orderSystems(specs)

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(systemNames(ordered), []string{
		"go.first",
		"lua.middle",
		"go.second",
	}) {
		t.Fatalf("unexpected order: %v", systemNames(ordered))
	}
}

func TestSystemOrderRejectsUnknownAndCycle(t *testing.T) {
	noop := akara.SystemFunc(func(*akara.World, time.Duration) error {
		return nil
	})

	for _, test := range []struct {
		name  string
		specs []systemSpec
		want  string
	}{
		{
			name: "unknown",
			specs: []systemSpec{
				{
					name:   "lua",
					system: noop,
					after:  []string{"missing"},
				},
			},
			want: "unknown",
		},

		{
			name: "cycle",
			specs: []systemSpec{
				{
					name:   "a",
					system: noop,
					after:  []string{"b"},
				},

				{
					name:   "b",
					system: noop,
					after:  []string{"a"},
				},
			},
			want: "cycle",
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			_, err := orderSystems(test.specs)

			if err == nil {
				t.Fatalf("wanted %q failure", test.want)
			}

			if !strings.Contains(err.Error(), test.want) {
				t.Fatalf("wanted %q, got %v", test.want, err)
			}
		})
	}
}
