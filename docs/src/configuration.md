# Configuring Diary.jl

Configuration of Diary.jl is done through `Diary.toml` files.  A global configuration can be set by creating a `$HOME/.julia/config/Diary.toml` file, or alternatively, per-project configuration can be set by placing a `Diary.toml` file in the project root, the same directory as the `Project.toml` file.  This is also where the diary file will end up by default.  An explicit path can also be specified by setting the environment variable `JULIA_DIARY_CONFIG`.

An example `Diary.toml` file looks like the following:
```toml
author = "Anna"
autocommit = true
blacklist = ["/home/anna/.julia/environments"]
date_format = "E U d HH:MM"
diary_name = "diary.jl"
directory_mode = false
```
If a field is not set, it will be set to a default value.

- `author`: defaults to `""`.  Written as part of the comment header to the diary file at the start of every session.
- `autocommit`: defaults to `true`.  If set to `false`, the diary file will not be automatically updated with the most recent history file changes.  Instead, changes must be manually committed by using the diary command comment syntax, `# diary: commit [n]` to commit the `n` most recent code blocks.
- `blacklist`: defaults to `["$HOME/.julia/environments"]`.  `blacklist` is a list of patterns that will disable Diary.jl, if a name or part of the path to a project matches it.  Set this to an empty vector to enable Diary.jl for all projects.
- `create_if_missing`: defaults to `true`.  If set to `false`, the diary file will not be created or written to if missing.
- `date_format`: defaults to `"E U d HH:MM"`.  The format of the date that is written to the comment header at the start of every session.  For a full list of date formatting options, see the documentation for `Dates.format`.
- `diary_file`: defaults to `"diary.jl"`.  Specifies the path to be used for the diary file, relative to the root directory.
- `directory_mode`: defaults to `false`.  If set to `true`, the root folder of the diary file is set to the current working directory, rather than the project directory.
- `persistent_history`: defaults to `true`.  If set to `false`, the REPL history will not be saved for future sessions.  This option does not affect the diary file.
