# Transducer interface

## Core interface for transducers

```@docs
Transducers.Transducer
Transducers.AbstractFilter
Transducers.R_
Transducers.start
Transducers.next
Transducers.complete
Transducers.outtype
```

## Helpers for stateful transducers

```@docs
Transducers.wrap
Transducers.unwrap
Transducers.wrapping
```

## Interface for reducibles

```@docs
Transducers.__foldl__
Transducers.@return_if_reduced
```
