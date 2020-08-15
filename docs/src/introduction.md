# Introduction

Diary.jl is a workflow package designed to make it easier for you to access your REPL history.  It works by monitoring changes to your REPL history, and automatically placing lines that parse as valid Julia syntax into a `diary.jl` file in your current active project.  To prevent accidental cluttering, however, this is not done for environments in the `$HOME/.julia/environments/` folder.

Diary.jl also keeps track of when you change your active project, and automatically switches to the associated diary file.  By default, the diary file is called `diary.jl`.  This can be overridden by the `JULIA_DIARY` environment variable, which specifies the desired location and name of the diary file for the session.  It can be changed at any time by setting `ENV["JULIA_DIARY"] = "path/to/file"` to dynamically switch to a different diary file.  To go back to the default file, remove the environment variable by calling: `delete!(ENV, "JULIA_DIARY")`.

Diary.jl can be configured on a per-project basis, by putting a `Diary.toml` file in the project root, with the desired configuration.  To set a global configuration, a `Diary.toml` file can also be put in the `$HOME/.julia/config/` directory, which will be loaded if a configuration file is not found in the current project.  See [Configuring Diary.jl](@ref) for more information.
