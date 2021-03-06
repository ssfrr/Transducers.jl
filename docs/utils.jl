using Documenter
using Transducers
# Not importing `Literate` here so that this file can be included from
# test.

EXAMPLE_PAGES = [
    "Tutorial: Missing values" => "examples/tutorial_missings.md",
    "Parallel word count" => "examples/words.md",
    "Prime sieve" => "examples/primes.md",
    "Writing transducers" => "examples/transducers.md",
    "Writing reducibles" => "examples/reducibles.md",
]

transducers_rm_examples() =
    rm(joinpath(@__DIR__, "src/examples"); force=true, recursive=true)

function transducers_literate(;
        inputbase = joinpath(@__DIR__, "..", "examples"),
        outputbase = joinpath(@__DIR__, "src", "examples"),
        examples = EXAMPLE_PAGES,
        kwargs...)
    transducers_rm_examples()
    for (_, outpath) in examples
        name, = splitext(basename(outpath))
        inputfile = joinpath(inputbase, "$name.jl")
        outputdir = outputbase
        Literate.markdown(
            inputfile, outputdir;
            documenter = true,
            kwargs...)
    end
end

transducers_makedocs(;
        examples = EXAMPLE_PAGES,
        kwargs...) =
    makedocs(;
        modules = [Transducers],
        pages = [
            "Home" => "index.md",
            "Manual" => "manual.md",
            "Interface" => "interface.md",
            "Examples" => examples,
            hide("Internals" => "internals.md"),
            hide("doctests/show_xf.md"),
            hide("doctests/show_rf.md"),
        ],
        repo = "https://github.com/tkf/Transducers.jl/blob/{commit}{path}#L{line}",
        sitename = "Transducers.jl",
        authors = "Takafumi Arakaki",
        assets = [],
        root = @__DIR__,
        strict = true,
        kwargs...)
