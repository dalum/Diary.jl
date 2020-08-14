module Diary

using Dates: Dates
using FileWatching: FileWatching
using Pkg: Pkg
using REPL: REPL

const GLOBAL_SEGMENT_BUFFER = Vector{String}[]

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
        previous_diary_file = nothing
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
                # Skip if the lines do not parse.
                try
                    Meta.parse(join(diary_lines, '\n'))
                catch e
                    continue
                end
                push!(GLOBAL_SEGMENT_BUFFER, diary_lines)
                # Read user configuration.
                configuration = read_configuration()
                # Skip if auto-committing is disabled.
                !configuration["autocommit"] && continue
                # Locate the diary file.
                diary_file = find_diary(; configuration)
                # Skip if a suitable diary file could not be found.
                isnothing(diary_file) && continue
                # Write a new header, if the diary file has changed, i.e., if we switched
                # project or manually set `ENV["JULIA_DIARY"]`.
                with_header = previous_diary_file != diary_file
                previous_diary_file = diary_file
                # Commit the latest segment.
                commit(1; configuration, diary_file, with_header)
            end
        end
    catch e
        @error "Diary.jl ($history_file)" exception=(e, catch_backtrace())
    finally
        # Clean-up.
        close(history_file_handle)
    end
    return nothing
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
            mode = Symbol(strip(line[8:end]))
            @debug "Diary.jl: mode line found: $mode"
            mode != :julia && empty!(diary_lines)
            break
        end
        # Each line is indented with a '\t' character, so we skip the first index.
        line = line[2:end]
        if startswith(line, "# diary: ")
            cmd = strip(line[9:end])
            @debug "Diary.jl: got command: $cmd"
            parse_command(cmd)
            break
        end
        # If the line ends with a ';', we strip it off.
        while endswith(line, ';')
            line = line[1:(end - 1)]
        end
        push!(diary_lines, line)
    end
    return reverse!(diary_lines)
end

"""
    parse_command(cmd)

Parse the diary command, `cmd`.  Valid commands are:
- `commit [n]`: Commit the last `n` segments.
"""
function parse_command(cmd)
    args = split(cmd)
    if args[1] == "commit"
        length(args) == 1 && return commit()
        length(args) == 2 && return commit(parse(Int, args[2]))
        @error("Diary.jl: too many arguments to `commit`: $(length(args) - 1), expected 1")
    else
        @error("Diary.jl: could not parse command: $cmd")
    end
end

"""
    find_diary(; configuration=read_configuration())

Locate the diary file.  The default diary name and blacklist is read from `configuration`.
See also [`read_configuration()`](@ref).
"""
function find_diary(; configuration=read_configuration())
    diary_file = get(ENV, "JULIA_DIARY", nothing)

    if isnothing(diary_file)
        environment_directory = dirname(Pkg.project().path)
        @debug "Diary.jl: using $environment_directory as diary root folder"
        # Exit early, if the directory is blacklisted.
        is_blacklisted = any(configuration["blacklist"]) do needle
            occursin(needle, environment_directory)
        end
        if is_blacklisted
            @debug "Diary.jl: $environment_directory is blacklisted"
            return nothing
        end
        diary_file = joinpath(environment_directory, configuration["diary_name"])
    else
        @debug "Diary.jl: JULIA_DIARY = $diary_file"
        diary_file = abspath(diary_file)
    end
    # Create the diary file if missing.
    !isfile(diary_file) && touch(diary_file)

    return diary_file
end

"""
    read_configuration(filename=find_configuration_file())

Read the configuration from `filename`.  See also [`find_configuration_file`](@ref).
"""
function read_configuration(filename=find_configuration_file())
    configuration = default_configuration()
    (isnothing(filename) || !isfile(filename)) && return configuration
    return merge!(configuration, Pkg.TOML.parsefile(filename))
end

"""
    find_configuration_file()

Locate the configuration file.
"""
function find_configuration_file()
    # If `ENV["JULIA_DIARY_CONFIG"]` is set, return that.
    filename = get(ENV, "JULIA_DIARY_CONFIG", nothing)
    !isnothing(filename) && return abspath(filename)
    # Otherwise, if a `Diary.toml` is found in the current project, return it.
    environment_directory = dirname(Pkg.project().path)
    filename = joinpath(environment_directory, "Diary.toml")
    isfile(filename) && return abspath(filename)
    # Fall back to returning `~/.julia/config/Diary.toml`, if it exists.
    filename = joinpath(ENV["HOME"], ".julia", "config", "Diary.toml")
    isfile(filename) && return abspath(filename)
    # No configuration file could be found.
    return nothing
end

"""
    default_configuration()

Return the default configuration.
"""
function default_configuration()
    return Dict{String,Any}(
        "author" => "",
        "diary_name" => "diary.jl",
        "date_format" => "E U d HH:MM",
        "autocommit" => true,
        "blacklist" => [
           joinpath(ENV["HOME"], ".julia", "environments"),
        ]
    )
end

"""
    commit(n; kwargs...)

Commit the `n` latest recorded lines to the diary file.

# Keyword arguments
- `configuration`: (default: `read_configuration()`)
- `diary_file`: (default: `find_diary(; configuration)`)
- `with_header`: Write header before lines. (default: `true`)
"""
function commit(
    n = length(GLOBAL_SEGMENT_BUFFER);
    configuration = read_configuration(),
    diary_file = find_diary(; configuration),
    with_header = true,
)
    # If the diary file could not be found, no lines were written
    isnothing(diary_file) && return 0
    # Prevent committing more lines than are in the buffer.
    n = min(n, length(GLOBAL_SEGMENT_BUFFER))
    @debug "Diary.jl: committing $n lines to $diary_file"
    # Update the diary file.
    open(diary_file, read=true, write=true) do io
        # Get the last line in the diary file.
        diary_lines = readlines(io)
        last_diary_line = iszero(length(diary_lines)) ? "" : diary_lines[end]
        for segment in GLOBAL_SEGMENT_BUFFER[(end - n + 1):end]
            if with_header
                # Insert an extra newline before the header, if the previous line
                # exists and contains non-whitespace characters.
                !all(isspace, last_diary_line) && print(io, '\n')
                write_header(io; configuration)
                with_header = false
            elseif (
                length(segment) > 1
                && !startswith(last_diary_line, "#")
                && !all(isspace, last_diary_line)
            )
                # Print an extra newline before multiline entries, if the last line
                # was not a comment or a newline.
                print(io, '\n')
            end

            # Write the segment to the diary.
            join(io, segment, '\n')
            print(io, '\n')
            # Always print an extra newline after multiline entries.
            length(segment) > 1 && print(io, '\n')
        end
    end
    # Clear the segment buffer.
    empty!(GLOBAL_SEGMENT_BUFFER)
    return n
end

"""
    write_header(io)

Write a header to the IO stream, `io`.
"""
function write_header(io; configuration=read_configuration())
    author = configuration["author"]
    date = Dates.format(Dates.now(), configuration["date_format"])
    print(io, "# ", author, ": ", date, '\n')
    print(io, '\n')
    return io
end

end # module
