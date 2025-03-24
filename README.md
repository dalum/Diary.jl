# Diary.jl 📔

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://dalum.github.io/Diary.jl/dev)
[![codecov](https://codecov.io/gh/dalum/Diary.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dalum/Diary.jl)

Diary.jl keeps a copy of what you type in the REPL in a file called `diary.jl`.  The file location defaults to the root of your current active project (the same location where your `Project.toml` and `Manifest.toml` files lie).  Please read the documentation (links above) for instructions on how to configure Diary.jl to your needs.

If you encounter any problems or have suggestions for how to improve the package, please open an issue or pull request.  All contributions from all people are welcome!

## Usage

To use Diary.jl, it must be enabled at startup. To do so, put the following in your `~/.julia/config/startup.jl` file:
```julia
atreplinit() do repl
    try
        @eval using Diary
    catch e
        @error "Loading Diary.jl:" exception=(e, catch_backtrace())
    end
end
```

## Known issues

* Diary.jl only works if loaded at startup. Calling `using Diary` in a running REPL does not work ([#3](https://github.com/dalum/Diary.jl/issues/3)).
* If used together with [OhMyREPL](https://github.com/KristofferC/OhMyREPL.jl), Diary.jl must be loaded *after* OhMyREPL.
