package script

import (
	"github.com/gravestench/akara"
)

// componentCommand records the pre-commit value when replay begins. This
// keeps ordered remove/add/set operations reversible if a later command fails.
func componentCommand(
	entity akara.Entity,
	store *akara.DynamicStore,
	host HostComponent,
	next *pendingComponent,
) structuralCommand {
	var previous map[string]any
	var existed bool

	set := func(values map[string]any) error {
		if store == nil {
			return host.Set(entity, values)
		}

		_, err := store.Set(entity, values)

		return err
	}

	remove := func() {
		if store == nil {
			host.Remove(entity)
		} else {
			store.Remove(entity)
		}
	}

	return structuralCommand{
		entity: entity,
		apply: func() error {
			if store == nil {
				previous, existed = host.Get(entity)
			} else {
				component, found := store.Get(entity)
				existed = found

				if found {
					snapshot, err := component.Snapshot()

					if err != nil {
						return err
					}

					previous = snapshot
				}
			}

			if !next.present {
				remove()

				return nil
			}

			return set(next.values)
		},
		undo: func() error {
			if !existed {
				remove()

				return nil
			}

			return set(previous)
		},
	}
}
