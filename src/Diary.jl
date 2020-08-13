module Diary

using Dates: Dates
using FileWatching: FileWatching
using Pkg: Pkg
using REPL: REPL

mutable struct DiaryConfig
    write_header::Bool
    blacklist::Set{Regex}
    break_lines::Set{String}
    author_name::String
    date_format::String
end

const GLOBAL_CONFIG = DiaryConfig(
    true,
    Set([r"\.julia\/environments\/v[0-9]+\.[0-9]+"]),
    Set(["# mode: julia"]),
    "",
    "E U d HH:MM",
)

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

function configure(; author_name=nothing, date_format=nothing)
    if !isnothing(author_name)
        GLOBAL_CONFIG.author_name = author_name
    end
    if !isnothing(date_format)
        GLOBAL_CONFIG.date_format = date_format
    end
end

function __init__()
    repl_history_file = REPL.find_hist_file()
    history_file, history_file_handle = mktemp()
    # Copy existing REPL history into the temporary history file.
    open(repl_history_file) do io
        for line in eachline(io)
            println(history_file_handle, line)
        end
    end
    # Close `history_file_handle` to write-out the copied lines.
    close(history_file_handle)
    # Set the REPL history file to the temporary file.
    ENV["JULIA_HISTORY"] = history_file

    @debug "Diary.jl: Watching: $history_file"
    start_watching(history_file, repl_history_file)
    return nothing
end

function write_header(io)
    author = GLOBAL_CONFIG.author_name
    date = Dates.format(Dates.now(), GLOBAL_CONFIG.date_format)
    print(io, "# ", author, ": ", date, '\n')
    print(io, '\n')
end

start_watching(args...) = schedule(Task(TaskThunk(watch_task, args)))

function watch_task(history_file, repl_history_file)
    history_file_handle = open(history_file)
    try
        watching = true
        # Flush lines to get to the end of the history file, so we
        # only track new changes.
        readlines(history_file_handle)

        diary_file = nothing
        while watching
            file_event = FileWatching.watch_file(history_file)
            if file_event.changed
                history_lines = readlines(history_file_handle)
                @debug "Diary.jl ($history_file): History file has changed:" history_lines
                # Copy history lines to the REPL history file
                open(repl_history_file, read=true, write=true) do io
                    seekend(io)
                    println(io, join(history_lines, '\n'))
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

                diary_file = find_diary(diary_file)
                # Skip if a suitable diary file could not be found.
                isnothing(diary_file) && continue
                # Get the last line in the diary file.
                last_diary_line = let
                    lines = readlines(diary_file)
                    iszero(length(lines)) ? "" : lines[end]
                end

                open(diary_file, read=true, write=true) do io
                    seekend(io)
                    if GLOBAL_CONFIG.write_header
                        # Insert an extra newline before the header, if the previous
                        # line exists and contains non-whitespace characters.
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

                    print(io, diary_lines_string, '\n')
                    # Always print an extra newline after multiline entries.
                    length(diary_lines) > 1 && print(io, '\n')
                end
            end
        end
    catch e
        @error "Diary.jl ($history_file): $diary_file" exception=(e, catch_backtrace())
    end
    # Clean-up.
    close(history_file_handle)
    return true
end

function find_diary(previous_diary_file=nothing)
    diary_file = get(ENV, "JULIA_DIARY", nothing)

    if isnothing(diary_file)
        environment_directory = dirname(Pkg.project().path)
        # Exit early, if the directory is blacklisted.
        is_blacklisted = any(GLOBAL_CONFIG.blacklist) do pat
            !isnothing(match(pat, environment_directory))
        end
        if is_blacklisted
            @debug "Diary.jl: $environment_directory found in blacklist"
            return nothing
        end
        diary_file = joinpath(environment_directory, "diary.jl")
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

function parse_history(history_lines)
    reversed_history_lines = reverse(history_lines)
    diary_lines = String[]
    for line in reversed_history_lines
        if startswith(line, "#")
            !(line in GLOBAL_CONFIG.break_lines) && empty!(diary_lines)
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

end # module
