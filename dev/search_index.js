var documenterSearchIndex = {"docs":
[{"location":"introduction/#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"introduction/","page":"Introduction","title":"Introduction","text":"Diary.jl is a workflow package designed to make it easier for you to access your REPL history.  It works by monitoring changes to your REPL history, and automatically placing lines that parse as valid Julia syntax into a diary.jl file in your current active project.  To prevent accidental cluttering, however, this is not done for the default ~/.julia/environments/vX.Y/ environments.","category":"page"},{"location":"introduction/","page":"Introduction","title":"Introduction","text":"Diary.jl also keeps track of when you change your active project, and automatically switches to the associated diary file.  By default, the diary file is called diary.jl, but this can be changed by calling Diary.configure(diary_file_name=\"<name>\").  Both of these behaviours are overridden if the environment variable, JULIA_DIARY, is set.  JULIA_DIARY specifies the desired location and name of the diary file for the session and can be changed at any time by setting ENV[\"JULIA_DIARY\"] = \"path/to/file\".  To disable it, remove the environment variable by calling: delete!(ENV, \"JULIA_DIARY\").","category":"page"},{"location":"developer_reference/#Developer-reference","page":"Developer reference","title":"Developer reference","text":"","category":"section"},{"location":"developer_reference/","page":"Developer reference","title":"Developer reference","text":"Diary.start_watching\nDiary.watch_task\nDiary.parse_history\nDiary.parse_command\nDiary.find_diary\nDiary.read_configuration\nDiary.find_configuration_file\nDiary.default_configuration\nDiary.commit\nDiary.write_header\nDiary.TaskThunk","category":"page"},{"location":"developer_reference/#Diary.start_watching","page":"Developer reference","title":"Diary.start_watching","text":"start_watching(args...)\n\nCreate and schedule a watch_task with the given args.  See also watch_task.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.watch_task","page":"Developer reference","title":"Diary.watch_task","text":"watch_task(history_file, repl_history_file=nothing)\n\nStart watching the history file at filepath history_file for changes, and parse those changes to update the diary.  If repl_history_file is set to a value other than nothing, also copy changes to repl_history_file.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.parse_history","page":"Developer reference","title":"Diary.parse_history","text":"parse_history(history_lines)\n\nParse the lines in history_lines, strip trailing semi-colons, and determine if they should be written to the diary based on the mode in which they were entered.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.parse_command","page":"Developer reference","title":"Diary.parse_command","text":"parse_command(cmd)\n\nParse the diary command, cmd.  Valid commands are:\n\ncommit [n]: Commit the last n segments.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.find_diary","page":"Developer reference","title":"Diary.find_diary","text":"find_diary(; configuration=read_configuration())\n\nLocate the diary file.  The default diary name and blacklist is read from configuration. See also read_configuration().\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.read_configuration","page":"Developer reference","title":"Diary.read_configuration","text":"read_configuration(filename=find_configuration_file())\n\nRead the configuration from filename.  See also find_configuration_file.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.find_configuration_file","page":"Developer reference","title":"Diary.find_configuration_file","text":"find_configuration_file()\n\nLocate the configuration file.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.default_configuration","page":"Developer reference","title":"Diary.default_configuration","text":"default_configuration()\n\nReturn the default configuration.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.commit","page":"Developer reference","title":"Diary.commit","text":"commit(n; kwargs...)\n\nCommit the n latest recorded lines to the diary file.\n\nKeyword arguments\n\nconfiguration: (default: read_configuration())\ndiary_file: (default: find_diary(; configuration))\nwith_header: Write header before lines. (default: true)\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.write_header","page":"Developer reference","title":"Diary.write_header","text":"write_header(io)\n\nWrite a header to the IO stream, io.\n\n\n\n\n\n","category":"function"},{"location":"developer_reference/#Diary.TaskThunk","page":"Developer reference","title":"Diary.TaskThunk","text":"thunk = TaskThunk(f, args)\n\nTo facilitate precompilation and reduce latency, we avoid creation of anonymous thunks. thunk can be used as an argument in schedule(Task(thunk)).  Adapted from Revise.\n\n\n\n\n\n","category":"type"},{"location":"#Diary.jl","page":"Index","title":"Diary.jl","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"Welcome to the documentation for Diary.jl!","category":"page"},{"location":"","page":"Index","title":"Index","text":"This document is intended to help you get started with using the package. If you have any suggestions, please open an issue or pull request on GitHub.","category":"page"}]
}