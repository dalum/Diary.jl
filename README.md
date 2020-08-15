# Diary.jl 📔

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://dalum.github.io/Diary.jl/dev)
[![Build Status](https://travis-ci.org/dalum/Diary.jl.svg?branch=master)](https://travis-ci.org/dalum/Diary.jl)
[![codecov](https://codecov.io/gh/dalum/Diary.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dalum/Diary.jl)

Diary.jl keeps a copy of what you type in the REPL in a file called `diary.jl`.  The file location defaults to the root of your current active project (the same location where your `Project.toml` and `Manifest.toml` files lie).  Please read the documentation (links above) for instructions on how to configure Diary.jl to your needs.

If you encounter any problems or have suggestions for how to improve the package, please open an issue or pull request.  All contributions from all people are welcome!

## Usage

To try out Diary.jl, install it using `]add Diary`. Then,
```julia
julia> using Diary
```
to get started.

If you want to enable Diary.jl by default, put the following in your `~/.julia/config/startup.jl` file:
```julia
atreplinit() do repl
    try
        @eval using Diary
    catch e
        @warn e
    end
end
```
