# Sealed domain failures instead of Resource<T>

Repositories and use cases signal failure by throwing a small sealed `DomainFailure` hierarchy (validation, not found, storage), and one presentation mapper turns each case into driver-facing copy. We dropped `Resource<T>` because it coexisted with thrown exceptions in the same call chain, and Riverpod's `AsyncValue.guard` already gives the UI an error state from a thrown failure without wrapping every layer.
