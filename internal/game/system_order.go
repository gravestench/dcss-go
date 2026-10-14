package game

import (
	"fmt"
	"slices"

	"github.com/gravestench/akara"
)

// systemSpec names one behavior in the game's deterministic Akara order.
// A Go system's current neighbor order is kept until its domain moves to Lua.
type systemSpec struct {
	name    string
	system  akara.System
	after   []string
	before  []string
	goOrder bool
}

func orderSystems(specs []systemSpec) ([]systemSpec, error) {
	index := make(map[string]int, len(specs))

	for position, spec := range specs {
		if spec.name == "" || spec.system == nil {
			return nil, fmt.Errorf("unnamed or nil game system")
		}

		if _, found := index[spec.name]; found {
			return nil, fmt.Errorf("duplicate game system %s", spec.name)
		}

		index[spec.name] = position
	}

	edges := make([]map[int]bool, len(specs))
	indegree := make([]int, len(specs))

	for position := range edges {
		edges[position] = make(map[int]bool)
	}

	addEdge := func(from, to int) {
		if !edges[from][to] {
			edges[from][to] = true
			indegree[to]++
		}
	}

	previousGo := -1

	for position, spec := range specs {
		if spec.goOrder {
			if previousGo >= 0 {
				addEdge(previousGo, position)
			}

			previousGo = position
		}

		for _, name := range spec.after {
			before, found := index[name]

			if !found {
				return nil, fmt.Errorf("system %s follows unknown system %s", spec.name, name)
			}

			addEdge(before, position)
		}

		for _, name := range spec.before {
			after, found := index[name]

			if !found {
				return nil, fmt.Errorf("system %s precedes unknown system %s", spec.name, name)
			}

			addEdge(position, after)
		}
	}

	ordered := make([]systemSpec, 0, len(specs))
	used := make([]bool, len(specs))

	for len(ordered) < len(specs) {
		chosen := -1

		for position := range specs {
			if !used[position] && indegree[position] == 0 {
				chosen = position

				break
			}
		}

		if chosen < 0 {
			return nil, fmt.Errorf("cycle in game system order")
		}

		used[chosen] = true
		ordered = append(ordered, specs[chosen])

		for next := range edges[chosen] {
			indegree[next]--
		}
	}

	return ordered, nil
}

func systemNames(specs []systemSpec) []string {
	names := make([]string, 0, len(specs))

	for _, spec := range specs {
		names = append(names, spec.name)
	}

	return slices.Clone(names)
}
