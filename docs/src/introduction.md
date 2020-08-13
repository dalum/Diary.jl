# Introduction

Diary.jl is a workflow package designed to make it easier for you to access your REPL history.  It works by monitoring changes to your REPL history, and automatically placing lines that parse as valid Julia syntax into a `diary.jl` file in your current active project.  To prevent accidental cluttering, however, this is not done for the default `~/.julia/environments/vX.Y/` environments.

Diary.jl also keeps track of when you change your active project, and automatically switches to the associated diary file.  By default, the diary file is called `diary.jl`, but this can be changed by calling `Diary.configure(diary_file_name="<name>")`.  Both of these behaviours are overridden if the environment variable, `JULIA_DIARY`, is set.  `JULIA_DIARY` specifies the desired location and name of the diary file for the session and can be changed at any time by setting `ENV["JULIA_DIARY"] = "path/to/file"`.  To disable it, set `ENV["JULIA_DIARY"] = nothing`.
