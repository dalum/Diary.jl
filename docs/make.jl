using Documenter
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using Diary

DocMeta.setdocmeta!(Diary, :DocTestSetup, :(using Diary); recursive=true)
makedocs(
    sitename = "Diary.jl 📔",
    modules = [Diary],
    pages = [
        "Index" => "index.md",
        "introduction.md",
        "api.md",
    ],
)

deploydocs(
    repo = "github.com/dalum/Diary.jl.git",
)
