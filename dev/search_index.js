var documenterSearchIndex = {"docs":
[{"location":"introduction/#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"introduction/","page":"Introduction","title":"Introduction","text":"Diary.jl is a workflow package designed to make it easier for you to access your REPL history.  It works by monitoring changes to your REPL history, and automatically placing lines that parse as valid Julia syntax into a diary.jl file in your current active project.  To prevent accidental cluttering, however, this is not done for environments in the $HOME/.julia/environments/ folder.","category":"page"},{"location":"introduction/","page":"Introduction","title":"Introduction","text":"Diary.jl also keeps track of when you change your active project, and automatically switches to the associated diary file.  By default, the diary file is called diary.jl.  This can be overridden by the JULIA_DIARY environment variable, which specifies the desired location and name of the diary file for the session.  It can be changed at any time by setting ENV[\"JULIA_DIARY\"] = \"path/to/file\" to dynamically switch to a different diary file.  To go back to the default file, remove the environment variable by calling: delete!(ENV, \"JULIA_DIARY\").","category":"page"},{"location":"introduction/","page":"Introduction","title":"Introduction","text":"Diary.jl can be configured on a per-project basis, by putting a Diary.toml file in the project root, with the desired configuration.  To set a global configuration, a Diary.toml file can also be put in the $HOME/.julia/config/ directory, which will be loaded if a configuration file is not found in the current project.  See Configuring Diary.jl for more information.","category":"page"},{"location":"developer_reference/#Developer-reference","page":"Developer reference","title":"Developer reference","text":"","category":"section"},{"location":"developer_reference/","page":"Developer reference","title":"Developer reference","text":"Diary.start_watching\nDiary.watch_task\nDiary.parse_history\nDiary.parse_command\nDiary.find_diary\nDiary.read_configuration\nDiary.find_configuration_file\nDiary.default_configuration\nDiary.commit\nDiary.write_header\nDiary.TaskThunk","category":"page"},{"location":"developer_reference/#Diary.start_watching","page":"Developer reference","title":"Diary.start_watching","text":"start_watching(args...)\n\nCreate and schedule a watch_task with the given args.  See also watch_task.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.watch_task","page":"Developer reference","title":"Diary.watch_task","text":"watch_task(history_file, repl_history_file=nothing)\n\nStart watching the history file at filepath history_file for changes, and parse those changes to update the diary.  If repl_history_file is set to a value other than nothing, also copy changes to repl_history_file.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.parse_history","page":"Developer reference","title":"Diary.parse_history","text":"parse_history(history_lines)\n\nParse the lines in history_lines, strip trailing semi-colons, and determine if they should be written to the diary based on the mode in which they were entered.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.parse_command","page":"Developer reference","title":"Diary.parse_command","text":"parse_command(cmd)\n\nParse the diary command, cmd.  Valid commands are:\n\ncommit [n]: Commit the last n segments.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.find_diary","page":"Developer reference","title":"Diary.find_diary","text":"find_diary(; configuration=read_configuration())\n\nLocate the diary file.  The default diary name and blacklist is read from configuration. See also read_configuration().\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.read_configuration","page":"Developer reference","title":"Diary.read_configuration","text":"read_configuration(filename=find_configuration_file())\n\nRead the configuration from filename.  See also find_configuration_file.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.find_configuration_file","page":"Developer reference","title":"Diary.find_configuration_file","text":"find_configuration_file()\n\nLocate the configuration file.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.default_configuration","page":"Developer reference","title":"Diary.default_configuration","text":"default_configuration()\n\nReturn the default configuration.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.commit","page":"Developer reference","title":"Diary.commit","text":"commit(n; kwargs...)\n\nCommit the n latest recorded lines to the diary file.\n\nKeyword arguments\n\nconfiguration: (default: read_configuration())\ndiary_file: (default: find_diary(; configuration))\nwith_header: Write header before lines. (default: true)\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.write_header","page":"Developer reference","title":"Diary.write_header","text":"write_header(io)\n\nWrite a header to the IO stream, io.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.TaskThunk","page":"Developer reference","title":"Diary.TaskThunk","text":"thunk = TaskThunk(f, args)\n\nTo facilitate precompilation and reduce latency, we avoid creation of anonymous thunks. thunk can be used as an argument in schedule(Task(thunk)).  Adapted from Revise.\n\n\n\n\n\n","category":"type"},{"location":"configuration/#Configuring-Diary.jl","page":"Configuring Diary.jl","title":"Configuring Diary.jl","text":"","category":"section"},{"location":"configuration/","page":"Configuring Diary.jl","title":"Configuring Diary.jl","text":"Configuration of Diary.jl is done through Diary.toml files.  A global configuration can be set by creating a $HOME/.julia/config/Diary.toml file, or alternatively, per-project configuration can be set by placing a Diary.toml file in the project root, the same directory as the Project.toml file.  This is also where the diary file will end up by default.  An explicit path can also be specified by setting the environment variable JULIA_DIARY_CONFIG.","category":"page"},{"location":"configuration/","page":"Configuring Diary.jl","title":"Configuring Diary.jl","text":"An example Diary.toml file looks like the following:","category":"page"},{"location":"configuration/","page":"Configuring Diary.jl","title":"Configuring Diary.jl","text":"author = \"Anna\"\nautocommit = true\nblacklist = [\"/home/anna/.julia/environments\"]\ndate_format = \"E U d HH:MM\"\ndiary_name = \"diary.jl\"\ndirectory_mode = false","category":"page"},{"location":"configuration/","page":"Configuring Diary.jl","title":"Configuring Diary.jl","text":"If a field is not set, it will be set to a default value.","category":"page"},{"location":"configuration/","page":"Configuring Diary.jl","title":"Configuring Diary.jl","text":"author: defaults to \"\".  Written as part of the comment header to the diary file at the start of every session.\nautocommit: defaults to true.  If set to false, the diary file will not be automatically updated with the most recent history file changes.  Instead, changes must be manually committed by using the diary command comment syntax, # diary: commit [n] to commit the n most recent code blocks.\nblacklist: defaults to [\"$HOME/.julia/environments\"].  blacklist is a list of patterns that will disable Diary.jl, if a name or part of the path to a project matches it.  Set this to an empty vector to enable Diary.jl for all projects.\ndate_format: defaults to \"E U d HH:MM\".  The format of the date that is written to the comment header at the start of every session.  For a full list of date formatting options, see the documentation for Dates.format.\ndiary_file: defaults to diary.jl.  Specifies the name to be used for the diary file.\ndirectory_mode: defaults to false.  If set to true, the root folder of the diary file is set to the current working directory, rather than the project directory.\npersistent_history: defaults to true.  If set to false, the REPL history will not be saved for future sessions.  This option does not affect the diary file.","category":"page"},{"location":"how_it_works/#How-it-works","page":"How it works","title":"How it works","text":"","category":"section"},{"location":"how_it_works/","page":"How it works","title":"How it works","text":"When Diary.jl is loaded, it finds the location of the active history file and saves it to an internal variable called repl_history_file.  It then creates a new temporary file on the computer, copies over the history from repl_history_file and assigns the JULIA_HISTORY environment variable to it.  This makes the REPL use the new temporary file as its history file, while retaining all previous history.  It also means that Diary.jl will break if JULIA_HISTORY is changed during an active session.","category":"page"},{"location":"how_it_works/","page":"How it works","title":"How it works","text":"A background task is then created, which monitors the temporary file for file changes.  Any new lines added to it are copied into repl_history_file, which ensures that history will persist across sessions, and not be lost due to the temporary nature of the temporary file.  After copying the lines over, they are subsequently parsed by Diary.jl.  The parser ignores lines that are not typed into the main Julia REPL (i.e., the help, package or other modes) and then does some very light formatting.  If the lines are diary command comments, the associated commands are executed, and otherwise they are inserted into the diary file.","category":"page"},{"location":"how_it_works/","page":"How it works","title":"How it works","text":"At every change, the configuration is loaded and the location of the diary file is determined.  This enables dynamic updates of both the configuration and file location, and the incurred overhead should be negligible.  If the diary file location has changed, a flag is set to write a header into the new diary file with author name and timestamp according to the active configuration.","category":"page"},{"location":"#Diary.jl","page":"Index","title":"Diary.jl","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"Welcome to the documentation for Diary.jl!","category":"page"},{"location":"","page":"Index","title":"Index","text":"This document is intended to help you get started with using the package. If you have any suggestions, please open an issue or pull request on GitHub.","category":"page"}]
}
