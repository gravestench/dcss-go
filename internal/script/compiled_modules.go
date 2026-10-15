package script

import (
	"bytes"
	"crypto/sha256"
	"sync"

	lua "github.com/yuin/gopher-lua"
)

type compiledModuleKey struct {
	name string
	hash [sha256.Size]byte
}

type compiledModule struct {
	once  sync.Once
	proto *lua.FunctionProto
	err   error
}

// Only immutable Lua code is shared. Each runtime creates a new function
// around the prototype, so globals and captured state stay in its own VM.
var compiledModules sync.Map

func compiledPrototype(
	state *lua.LState,
	name string,
	data []byte,
) (*lua.FunctionProto, error) {
	key := compiledModuleKey{
		name: name,
		hash: sha256.Sum256(data),
	}

	value, _ := compiledModules.LoadOrStore(key, &compiledModule{})
	module := value.(*compiledModule)

	module.once.Do(func() {
		chunk, err := state.Load(bytes.NewReader(data), name)

		if err != nil {
			module.err = err

			return
		}

		module.proto = chunk.Proto
	})

	return module.proto, module.err
}
