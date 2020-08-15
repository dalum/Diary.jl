# Diary.jl 📔

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://dalum.github.io/Diary.jl/dev)
[![Build Status](https://travis-ci.org/dalum/Diary.jl.svg?branch=master)](https://travis-ci.org/dalum/Diary.jl)
[![codecov](https://codecov.io/gh/dalum/Diary.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dalum/Diary.jl)

Diary.jl keeps a copy of what you type in the REPL in a `diary.jl` file in the root of your current active environment (the same location where your `Project.toml` and `Manifest.toml` files lie).  It helps you sketch out ideas in the REPL, which can then later be refined, by editing and copying relevant pieces from `diary.jl`.

Note: Diary.jl is still under development, but feedback is much appreciated.

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
