# Diary.jl

Welcome to the documentation for Diary.jl!

This document is intended to help you get started with using the package. If you have any suggestions, please open an issue or pull request on GitHub.

# Getting started

To get started with Diary.jl, it must be enabled at startup. To do so, put the following in your `~/.julia/config/startup.jl` file:
```julia
atreplinit() do repl
    try
        @eval using Diary
    catch e
        @error "Loading Diary.jl:" exception=(e, catch_backtrace())
    end
end
```
After this, any new Julia session you start will have `Diary.jl` enabled.
