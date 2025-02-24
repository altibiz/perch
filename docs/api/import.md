# Import

- `import.dirToAttrsWithMap`
  (`({ __import: { path, name, type, value } } -> ?) -> directory path -> deep attrset of ?`):
  Import a directory into a deep attrset of the type of the return type of the
  mapping function.

- `import.dirToAttrsWithMetadata`
  (`directory path -> deep attrset of { __import: { path, name, type, value } }`):
  Import a directory into a deep attrset of imports with metadata.

- `import.dirToValueAttrs` (`directory path -> deep attrset of ?`): Import a
  directory into a deep attrset of values.

- `import.dirToPathAttrs` (`directory path -> deep attrset of ?`): Import a
  directory into a deep attrset of paths.

- `import.dirToListWithMap`
  (`({ __import: { path, name, type, value } } -> ?) -> directory path -> list of ?`):
  Import a directory into a list of the type of the return type of the mapping
  function.

- `import.dirToListWithMetadata`
  (`directory path -> list of { __import: { path, name, type, value } }`):
  Import a directory into a list of imports with metadata.

- `import.dirToValueList` (`directory path -> list of ?`): Import a directory
  into a list of values.

- `import.dirToPathList` (`directory path -> list of ?`): Import a directory
  into a list of paths.

- `import.dirToFlatAttrsWithMap`
  (`({ __import: { path, name, type, value } } -> ?) -> directory path -> flat attrs of ?`):
  Import a directory into flat attrs of the type of the return type of the
  mapping function.

- `import.dirToFlatAttrsWithMetadata`
  (`directory path -> flat attrs of { __import: { path, name, type, value } }`):
  Import a directory into flat attrs of imports with metadata.

- `import.dirToValueFlatAttrs` (`directory path -> flat attrs of ?`): Import a
  directory into flat attrs of values.

- `import.dirToPathFlatAttrs` (`directory path -> flat attrs of ?`): Import a
  directory into flat attrs of paths.
