package game

import (
	"fmt"
	"hash/fnv"
)

// RNGStreams owns serializable SplitMix64 state for each gameplay domain.
type RNGStreams struct {
	seed   uint64
	states map[string]uint64
}

func NewRNGStreams(seed uint64) *RNGStreams {
	return &RNGStreams{
		seed:   seed,
		states: make(map[string]uint64),
	}
}

func RestoreRNGStreams(seed uint64, states map[string]uint64) *RNGStreams {
	copyStates := make(map[string]uint64, len(states))
	for name, state := range states {
		copyStates[name] = state
	}
	return &RNGStreams{
		seed:   seed,
		states: copyStates,
	}
}

func (r *RNGStreams) States() map[string]uint64 {
	copyStates := make(map[string]uint64, len(r.states))
	for name, state := range r.states {
		copyStates[name] = state
	}
	return copyStates
}

func (r *RNGStreams) next(name string) uint64 {
	state, found := r.states[name]
	if !found {
		hash := fnv.New64a()
		_, _ = hash.Write([]byte(name))
		state = r.seed ^ hash.Sum64()
	}
	state += 0x9e3779b97f4a7c15
	r.states[name] = state
	z := state
	z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9
	z = (z ^ (z >> 27)) * 0x94d049bb133111eb
	return z ^ (z >> 31)
}

func (r *RNGStreams) Intn(name string, n int) (int, error) {
	if name == "" || n <= 0 {
		return 0, fmt.Errorf("RNG stream name and positive bound required")
	}
	bound := uint64(n)
	threshold := -bound % bound
	for {
		value := r.next(name)
		if value >= threshold {
			return int(value % bound), nil
		}
	}
}
