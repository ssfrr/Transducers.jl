# Show method for reducing functions

```@meta
DocTestSetup = quote
    using Transducers
    using Transducers: Reduction, TeeZip
    using Setfield: @set!
end
```

```jldoctest
Reduction(
    Filter(isfinite) |> Map(sin),
    +,
    Float64)

# output

Reduction{▶ Float64}(
    Filter(isfinite),
    Reduction{▶ Float64}(
        Map(sin),
        +))
```

```jldoctest
rf = Reduction(
    TeeZip(Count()),
    right,
    Float64)
@set! rf.inner.inner.value = 1.25

# output

Splitter{▶ Float64}(
    Reduction{▶ Float64}(
        Count(1, 1),
        Joiner{▶ ⦃Float64, Int64⦄}(
            Transducers.right,
            1.25)),
    (@lens _.inner.value))
```

```jldoctest
rf = Reduction(
    Filter(isfinite) |> TeeZip(Count()) |> Enumerate() |> MapSplat(*),
    right,
    Float64)
@set! rf.inner.inner.inner.value = 1.25

# output

Reduction{▶ Float64}(
    Filter(isfinite),
    Splitter{▶ Float64}(
        Reduction{▶ Float64}(
            Count(1, 1),
            Joiner{▶ ⦃Float64, Int64⦄}(
                Reduction{▶ ⦃Float64, Int64⦄}(
                    Enumerate(1, 1),
                    Reduction{▶ ⦃Int64, ⦃Float64, Int64⦄⦄}(
                        MapSplat(*),
                        Transducers.right)),
                1.25)),
        (@lens _.inner.value)))
```

```jldoctest
rf = Reduction(
    TeeZip(Count() |> TeeZip(FlagFirst())),
    right,
    Float64)
@set! rf.inner.inner.inner.inner.value = 123456789
@set! rf.inner.inner.inner.inner.inner.value = 1.25

# output

Splitter{▶ Float64}(
    Reduction{▶ Float64}(
        Count(1, 1),
        Splitter{▶ Int64}(
            Reduction{▶ Int64}(
                FlagFirst(),
                Joiner{▶ ⦃Int64, ⦃Bool, Int64⦄⦄}(
                    Joiner{▶ ⦃Float64, ⦃Int64, ⦃Bool, Int64⦄⦄⦄}(
                        Transducers.right,
                        1.25),
                    123456789)),
            (@lens _.inner.value))),
    (@lens _.inner.inner.inner.inner.value))
```

```jldoctest
rf = Reduction(
    TeeZip(Filter(isodd) |> Map(identity) |> TeeZip(Map(identity))),
    right,
    Int64)
@set! rf.inner.inner.inner.inner.inner.value = 123456789
@set! rf.inner.inner.inner.inner.inner.inner.value= 123456789

# output

Splitter{▶ Int64}(
    Reduction{▶ Int64}(
        Filter(isodd),
        Reduction{▶ Int64}(
            Map(identity),
            Splitter{▶ Int64}(
                Reduction{▶ Int64}(
                    Map(identity),
                    Joiner{▶ ⦃Int64, Int64⦄}(
                        Joiner{▶ ⦃Int64, ⦃Int64, Int64⦄⦄}(
                            Transducers.right,
                            123456789),
                        123456789)),
                (@lens _.inner.value)))),
    (@lens _.inner.inner.inner.inner.inner.value))
```

```jldoctest
rf = Reduction(
    TeeZip(Filter(isodd) |> Map(identity) |> TeeZip(Map(identity))),
    right,
    Any)

# output

Splitter{▶ Any}(
    Reduction{▶ Any}(
        Filter(isodd),
        Reduction{▶ Any}(
            Map(identity),
            Splitter{▶ Any}(
                Reduction{▶ Any}(
                    Map(identity),
                    Joiner{▶ ⦃Any, Any⦄}(
                        Joiner{▶ ⦃Any, ⦃Any, Any⦄⦄}(
                            Transducers.right,
                            nothing),
                        nothing)),
                (@lens _.inner.value)))),
    (@lens _.inner.inner.inner.inner.inner.value))
```

```@meta
DocTestSetup = nothing
```
