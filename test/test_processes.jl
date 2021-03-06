module TestProcesses
include("preamble.jl")

@testset "mapfoldl" begin
    # https://clojure.org/reference/transducers#_transduce
    xf = Filter(isodd) |> Map(inc)
    @testset for xs in iterator_variants(0:4)
        @test mapfoldl(xf, +, xs, init=0) == 6
        @test mapfoldl(xf, +, xs, init=100) == 106
    end

    # https://clojuredocs.org/clojure.core/transduce
    xf = Filter(isodd) |> Take(10)
    @testset "$(typeof(xs))" for xs in iterator_variants(0:1000)
        @test mapfoldl(xf, push!, xs, init=Int[]) == 1:2:19
        @test mapfoldl(xf, +, xs, init=0) == 100
        @test mapfoldl(xf, +, xs, init=17) == 117
        @test mapfoldl(xf, string, xs, init="") == "135791113151719"

        @test transduce(xf, push!, Int[], xs) == Reduced(1:2:19)
        @test transduce(xf, +, 0, xs) == Reduced(100)
        @test transduce(xf, +, 17, xs) == Reduced(117)
        @test transduce(xf, string, "", xs) == Reduced("135791113151719")
    end

    @testset "empty" begin
        xf = Filter(_ -> false)
        iter = 1:4
        @test foldl(+, xf, iter) === 0
        @test foldl(+, xf, iter, init=32.) === 32.

        ed = eduction(xf, iter)
        @test foldl(+, ed) === 0
        @test foldl(+, ed, init=32.) === 32.

        @test mapfoldl(xf, +, iter) === 0
        @test mapfoldl(xf, +, iter, init=32.) === 32.

        nested_xf = Drop(10^9) |> FlagFirst() |> Map(x -> 32)
        @test foldl(+, nested_xf, iter) === 0
    end

    @testset "zip-of-arrays" begin
        @testset for arrays in [
                (0:3,),
                (0:3, 1:2:8),
                (0:3, 1:2:8, 10:3:19),
                (reshape([1:9;], (3, 3)), [10:3:34;]),
                ]
            xs = zip(arrays...)
            VERSION >= v"1.1-" && @test xs isa Iterators.Zip
            @test mapfoldl(MapSplat(*), +, xs) == sum(map(*, arrays...))
        end
    end

    @testset "product-of-iterators" begin
        iterator_prototypes = [
            (1, 2),
            0:3,
            [-1, 2, 1],
        ]
        @testset for iterators in Iterators.product(iterator_prototypes,
                                                    iterator_prototypes,
                                                    iterator_prototypes),
                n in 1:length(iterators)
            xs = Iterators.product(iterators[1:n]...)
            @test collect(Map(identity), xs) == collect(xs)[:]
            @test mapfoldl(MapSplat(*), +, xs) == sum(Base.splat(*), xs)
        end
    end
end


@testset "eduction" begin
    # https://clojuredocs.org/clojure.core/eduction
    xf = Filter(isodd) |> Take(5)
    @testset "$(typeof(xs))" for xs in iterator_variants(0:1000)
        @test collect(xf, xs) == 1:2:9
        @test collect(eduction(xf, xs)) == 1:2:9
        @test collect(Map(x -> 2x), eduction(xf, xs)) == 2(1:2:9)
    end

    @testset for xs in iterator_variants(1:5)
        @test collect(xf, xs) == 1:2:5
        @test collect(eduction(xf, xs)) == 1:2:5
        @test collect(Map(x -> 2x), eduction(xf, xs)) == 2(1:2:5)
    end

    ed = eduction(xf, 1:5)
    @test eltype(ed) === Int
end

# Custom container without unary push! method
struct MinimalContainer
    internal
end

Base.push!(coll::MinimalContainer, x) =
    MinimalContainer(push!(coll.internal, x))

@testset "append!" begin
    # https://clojuredocs.org/clojure.core/into#example-57294b20e4b050526f331420
    xf = Map(x -> x + 2) |> Filter(isodd)
    @testset for xs in iterator_variants(0:9)
        @test append!(xf, [-1, -2], xs) == [-1, -2, 3, 5, 7, 9, 11]
        @test append!(xf, MinimalContainer([-1, -2]), xs).internal ==
            [-1, -2, 3, 5, 7, 9, 11]
    end
end

@testset "map!" begin
    xs0 = 1:10
    @testset for src in [xs0, collect(xs0)]
        dest = similar(xs0)
        @test map!(Scan(+), dest, src) === dest
        @test dest == cumsum(xs0)
    end

    xs0 = 1:5
    @testset for src in [xs0, collect(xs0)]
        dest = zero(src)
        @test map!(Filter(isodd) |> Scan(+), dest, src) == [1, 0, 4, 0, 9]
    end

    @testset "Expansive transducers are not allowed" begin
        @test_throws Exception map!(Cat(), [0], 1:1)
    end
end

@testset "copy!" begin
    xs0 = 1:10
    @testset for src in [xs0, collect(xs0)]
    # @testset for src in iterator_variants(xs0)  # TODO: fix
        dest = similar(xs0)
        @test copy!(Scan(+), dest, src) === dest
        @test dest == cumsum(src)
    end

    xs0 = 1:5
    @testset for src in [xs0, collect(xs0)]
    # @testset for src in iterator_variants(xs0)  # TODO: fix
        dest = zero(xs0)
        @test copy!(Filter(isodd) |> Scan(+), dest, src) == [1, 4, 9]
    end
end

@testset "simple_transduce" begin
    xf = PartitionBy(x -> x > 0) |>
        Filter(xs -> mean(abs, xs) < 1.0) |>
        Map(prod)

    for _ in 1:100
        xs = randn(100)
        @test transduce(xf, +, 0.0, xs) == simple_transduce(xf, +, 0.0, xs)
    end
end

@testset "Transducer(::Reduction)" begin
    # testing Transducer(::Eduction) which calls Transducer(::Reduction)
    @testset for xf in [
            Map(sin),
            TeeZip(Filter(isfinite) |> Map(tan)),
            Map(sin) |> TeeZip(Filter(isfinite) |> Map(tan)) |>
                Map(cos),
            TeeZip(Map(sin) |> TeeZip(Map(tan))),
            TeeZip(TeeZip(Map(tan)) |> Map(identity)),
            TeeZip(Map(sin) |> TeeZip(Map(tan)) |> Map(identity)),
            Map(cos) |> TeeZip(Map(sin) |> TeeZip(Map(tan)) |> Map(identity)),
            Map(cos) |>
                TeeZip(Map(sin) |> TeeZip(Map(tan)) |> Map(identity)) |>
                Map(first),
            TeeZip(TeeZip(Map(tan))),
            ]
        @test Transducer(eduction(xf, 1:1)) === xf
    end
end

@testset "isexpansive" begin
    expansives = [
        Cat()
        Cat() |> Filter(isodd)
        Filter(isodd) |> Cat()
    ]
    @testset for xf in expansives
        @test isexpansive(xf)
        @test isexpansive(TeeZip(xf))
    end
    nonexpansives = [
        Map(identity)
        Map(identity) |> Count()
    ]
    @testset for xf in nonexpansives
        @test !isexpansive(xf)
        @test !isexpansive(TeeZip(xf))
    end
end

@testset "Non-executable transducers" begin
    @testset for ex in @expressions begin
            mapfoldl(Map(error), +, Int[])
            foldl(+, Map(error), Int[])
            foldl(+, eduction(Map(error), Int[]))
            Channel(Map(error), Int[])
            Channel(eduction(Map(error), Int[]))
            Channel(Map(error), eduction(Map(identity), Int[]))
            Channel(Map(identity), eduction(Map(error), Int[]))
        end

        err = @eval @test_error $ex
        @test occursin("inferred", sprint(showerror, err))
        @test occursin("`Union{}`", sprint(showerror, err))
    end

    @testset for ex in @expressions begin
            mapfoldl(Map(error), +, ["hello"]; init=0)
            foldl(+, Map(error), ["hello"]; init=0)
            foldl(+, eduction(Map(error), ["hello"]); init=0)
            foreach(tuple, Map(error), ["hello"])
            foreach(tuple, eduction(Map(error), ["hello"]))
            collect(Map(error), ["hello"])
            collect(eduction(Map(error), ["hello"]))
            append!(Map(error), [], ["hello"])
            copy!(Map(error), [], ["hello"])
        end

        @eval @test_throws ErrorException("hello") $ex
    end
end

@testset "identityof error" begin
    @test mapfoldl(Map(identity), right, Any[]) === nothing
    err = @test_error mapfoldl(Map(identity), +, Any[])
    msg = sprint(showerror, err)
    @test occursin("cannot be inferred", msg)
    @test occursin("Use the argument `init` to specify the initial value",
                   msg)

    @test mapfoldl(Map(identity), right, Vector{Int}[]) === nothing
    err = @test_error mapfoldl(Map(identity), +, Vector{Int}[])
    msg = sprint(showerror, err)
    @test occursin("Array", msg)
    @test occursin("Use the argument `init` to specify the initial value",
                   msg)
end

end  # module
