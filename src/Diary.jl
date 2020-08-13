module Diary

using Dates: Dates
using FileWatching: FileWatching
using Pkg: Pkg
using REPL: REPL

"""
    thunk = TaskThunk(f, args)

To facilitate precompilation and reduce latency, we avoid creation of anonymous thunks.
`thunk` can be used as an argument in `schedule(Task(thunk))`.  Adapted from `Revise`.
"""
struct TaskThunk
    f
    args
end
@noinline (thunk::TaskThunk)() = thunk.f(thunk.args...)

"""
    DiaryConfig

Mutable configuration for Diary.jl.  Diary.jl contains a single global instance of this
type, `GLOBAL_CONFIG`.  Configuration of Diary.jl should be done through [`configure`](@ref)
rather than direct manipulations of `GLOBAL_CONFIG`.
"""
mutable struct DiaryConfig
    write_header::Bool
    blacklist::Set{Regex}
    author::String
    date_format::String
    diary_file_name::String
end

const GLOBAL_CONFIG = DiaryConfig(
    true,
    Set([r"\.julia\/environments\/v[0-9]+\.[0-9]+"]),
    "",
    "E U d HH:MM",
    "diary.jl",
)

"""
    configure(; kwargs...)

Change configuration for Diary.jl in the current session.

## Supported keywords
 - `author`: Author name put in the header.  (default: "")
 - `date_format`: `Dates.format`--compatible date format used in the header.
    (default: "E U d HH:MM")
 - `diary_file_name`: Default name of the diary file.  (default: "diary.jl")

!!! note
    If `ENV["JULIA_DIARY"]` is set, the diary file name will be ignored.
"""
function configure(; kwargs...)
    for arg in (:author, :date_format, :diary_file_name)
        value = get(kwargs, arg, nothing)
        !isnothing(value) && setfield!(GLOBAL_CONFIG, arg, value)
    end
    return nothing
end

function __init__()
    # Only run the watcher if we are running in interactive mode.
    !isinteractive() && return nothing
    # Locate the current history file used by the REPL, so we can keep it updated.
    repl_history_file = REPL.find_hist_file()
    # Create a new, temporary history file that we track.  This protects our diary from
    # being cluttered by changes to the global history, which may not originate from our
    # current session.
    history_file = tempname()
    # Copy existing REPL history into the temporary history file.
    cp(repl_history_file, history_file)
    # Set the REPL history file to the temporary history file.
    ENV["JULIA_HISTORY"] = history_file

    @debug "Diary.jl: Watching: $history_file"
    start_watching(history_file, repl_history_file)
    return nothing
end

"""
    start_watching(args...)

Create and schedule a `watch_task` with the given `args`.  See also [`watch_task`](@ref).
"""
start_watching(args...) = schedule(Task(TaskThunk(watch_task, args)))

"""
    watch_task(history_file, repl_history_file=nothing)

Start watching the history file at filepath `history_file` for changes, and parse those
changes to update the diary.  If `repl_history_file` is set to a value other than `nothing`,
also copy changes to `repl_history_file`.
"""
function watch_task(history_file, repl_history_file=nothing)
    # Open the history file for reading, so we only have to parse the most recent changes.
    history_file_handle = open(history_file)
    try
        watching = true
        # Flush lines to get to the end of the history file, so we only track new changes.
        readlines(history_file_handle)
        # We set the diary file to `nothing` outside the loop so we can keep track of the
        # file location and whether it changes while the task is running.
        diary_file = nothing
        while watching
            file_event = FileWatching.watch_file(history_file)
            if file_event.changed
                history_lines = readlines(history_file_handle)
                @debug "Diary.jl ($history_file): History file has changed:" history_lines
                # Copy history lines to the REPL history file
                if !isnothing(repl_history_file)
                    open(repl_history_file, read=true, write=true) do io
                        seekend(io)
                        println(io, join(history_lines, '\n'))
                    end
                end
                # Parse history lines to put in the diary.
                diary_lines = parse_history(history_lines)
                iszero(length(diary_lines)) && continue
                diary_lines_string = join(diary_lines, '\n')
                # Skip if the lines do not parse.
                try
                    Meta.parse(diary_lines_string)
                catch e
                    continue
                end
                # Locate the diary file.
                diary_file = find_diary(diary_file)
                # Skip if a suitable diary file could not be found.
                isnothing(diary_file) && continue
                # Get the last line in the diary file.
                last_diary_line = let
                    lines = readlines(diary_file)
                    iszero(length(lines)) ? "" : lines[end]
                end
                # Update the diary file.
                open(diary_file, read=true, write=true) do io
                    seekend(io)
                    if GLOBAL_CONFIG.write_header
                        # Insert an extra newline before the header, if the previous line
                        # exists and contains non-whitespace characters.
                        !all(isspace, last_diary_line) && print(io, '\n')
                        write_header(io)
                        GLOBAL_CONFIG.write_header = false
                    elseif (
                        length(diary_lines) > 1
                        && !startswith(last_diary_line, "#")
                        && !all(isspace, last_diary_line)
                    )
                        # Print an extra newline before multiline entries, if the last line
                        # was not a comment or a newline.
                        print(io, '\n')
                    end
                    # Write the parsed lines to the diary.
                    print(io, diary_lines_string, '\n')
                    # Always print an extra newline after multiline entries.
                    length(diary_lines) > 1 && print(io, '\n')
                end
            end
        end
    catch e
        @error "Diary.jl ($history_file): $diary_file" exception=(e, catch_backtrace())
    finally
        # Clean-up.
        close(history_file_handle)
    end
    return nothing
end

"""
    find_diary(previous_diary_file=nothing)

Locate the diary file.  If `previous_diary_file` is `nothing` or is different from the
located diary file, also set the global `write_header` flag to true.
"""
function find_diary(previous_diary_file=nothing)
    diary_file = get(ENV, "JULIA_DIARY", nothing)

    if isnothing(diary_file)
        environment_directory = dirname(Pkg.project().path)
        @debug "Diary.jl: using $environment_directory as diary root folder"
        # Exit early, if the directory is blacklisted.
        is_blacklisted = any(GLOBAL_CONFIG.blacklist) do pat
            !isnothing(match(pat, environment_directory))
        end
        if is_blacklisted
            @debug "Diary.jl: $environment_directory found in blacklist"
            return nothing
        end
        diary_file = joinpath(environment_directory, GLOBAL_CONFIG.diary_file_name)
    else
        diary_file = abspath(diary_file)
    end
    # Create the diary file if missing.
    !isfile(diary_file) && touch(diary_file)
    # Write a new header, if the diary file has changed, i.e., if we switched project or
    # manually set `ENV["JULIA_DIARY"]`.
    if previous_diary_file != diary_file
        GLOBAL_CONFIG.write_header = true
    end

    return diary_file
end

"""
    parse_history(history_lines)

Parse the lines in `history_lines`, strip trailing semi-colons, and determine if they should
be written to the diary based on the mode in which they were entered.
"""
function parse_history(history_lines)
    reversed_history_lines = reverse(history_lines)
    diary_lines = String[]
    for line in reversed_history_lines
        if startswith(line, "# mode: ")
            mode = Symbol(line[8:end])
            mode != "julia" && empty!(diary_lines)
            break
        end
        # Each line is indented with a '\t' character, so we skip the first index.
        line = line[2:end]
        # If the line ends with a ';', we strip it off.
        while endswith(line, ';')
            line = line[1:(end - 1)]
        end
        push!(diary_lines, line)
    end
    return reverse!(diary_lines)
end

"""
    write_header(io)

Write a header to the IO stream, `io`.
"""
function write_header(io)
    author = GLOBAL_CONFIG.author
    date = Dates.format(Dates.now(), GLOBAL_CONFIG.date_format)
    print(io, "# ", author, ": ", date, '\n')
    print(io, '\n')
    return io
end

end # module
