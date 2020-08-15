# Configuring Diary.jl

Configuration of Diary.jl is done through `Diary.toml` files.  A global configuration can be set by creating a `$HOME/.julia/config/Diary.toml` file, or alternatively, per-project configuration can be set by placing a `Diary.toml` file in the project root, the same directory as the `Project.toml` file.  This is also where the diary file will end up by default.  An explicit path can also be specified by setting the environment variable `JULIA_DIARY_CONFIG`.

An example `Diary.toml` file looks like the following:
```toml
author = "Anna"
date_format = "E U d HH:MM"
diary_name = "diary.jl"
autocommit = true
blacklist = ["/home/anna/.julia/environments"]
```
If a field is not set, it will be set to a default value.

- The `author` and `date_format` fields affect the header written in diary files and default to `""` and `"E U d HH:MM"` respectively.  For a full list of date formatting options, consult the documentation for `Dates.format`.
- `diary_file` specifies the name to be used for the diary file and defaults to `"diary.jl"`.
- `autocommit` defaults to `true`.  If set to `false`, the diary file will not be automatically updated with the most recent history file changes.  Instead, changes must be manually committed by using the diary command comment syntax, `# diary: commit [n]` to commit the `n` most recent code blocks.
- `blacklist` is a list of patterns that will disable Diary.jl, for projects that match them.  By default, the list is set to `["$HOME/.julia/environments"]`.  Set this to an empty vector to enable Diary.jl for all projects.
