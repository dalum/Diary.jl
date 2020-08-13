# Diary.jl 📔

`Diary.jl` keeps a copy of what you type in the REPL in a `diary.jl` file in the root of your current active environment (the same location where your `Project.toml` and `Manifest.toml` files lie).  It helps you sketch out ideas in the REPL, which can then later be refined, by editing and copying relevant pieces from `diary.jl`.

Note: `Diary.jl` is still under development, but feedback is much appreciated.

## Usage

To try out `Diary.jl`, install it using `]add https://github.com/dalum/Diary.jl`. Then,
```julia
julia> using Diary
```
to get started.

If you want to enable `Diary.jl` by default, put the following in your `~/.julia/config/startup.jl` file:
```julia
try
    using Diary
    Diary.configure(author_name="<your name>")
catch e
    @warn(e.msg)
end
```
