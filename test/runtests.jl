module TestDiary

using Test, Diary

using FileWatching
using Pkg

@testset "History Parsing" begin
    history_lines = [
        "# time: ***",
        "# mode: julia",
	"\ta = rand(100);",
    ]
    @test Diary.parse_history(history_lines) == ["a = rand(100)"]

    history_lines = [
        "# time: ***",
        "# mode: julia",
	"\tstruct MyStruct",
	"\t    field::Any",
	"\tend",
    ]
    @test Diary.parse_history(history_lines) == ["struct MyStruct", "    field::Any", "end"]

    history_lines = [
        "# time: ***",
        "# mode: pkg",
	"\tstatus",
    ]
    @test Diary.parse_history(history_lines) == []

    history_lines = [
        "# time: ***",
        "# mode: julia",
	"\t# diary: commit",
    ]
    @test Diary.parse_history(history_lines) == []
end

@testset "Command Parsing" begin
    cmd = "commit"
    @test Diary.parse_command(cmd) === 0
    cmd = "commit 1"
    @test Diary.parse_command(cmd) === 0
    cmd = "commit 1 2"
    @test_logs (:error, "Diary.jl: too many arguments to `commit`: 2, expected 1") Diary.parse_command(cmd)
    cmd = "erase"
    @test Diary.parse_command(cmd) === true
    cmd = "erase diary"
    @test_logs (:error, "Diary.jl: too many arguments to `erase`: 1, expected 0") Diary.parse_command(cmd)
    cmd = "unsupported command"
    @test_logs (:error, "Diary.jl: could not parse command: $cmd") Diary.parse_command(cmd)
end

@testset "Finding configuration" begin
    haskey(ENV, "JULIA_DIARY_CONFIG") && return

    Pkg.activate()
    default_configuration = Dict{String,Any}(
        "author" => "",
        "autocommit" => true,
        "blacklist" => [
            joinpath(ENV["HOME"], ".julia", "environments"),
        ],
        "create_if_missing" => true,
        "date_format" => "E U d HH:MM",
        "diary_name" => "diary.jl",
        "directory_mode" => false,
        "file_polling" => false,
        "file_polling_interval" => 1.0,
        "persistent_history" => true,
    )

    ENV["JULIA_DIARY_CONFIG"] = tempname()
    @test Diary.default_configuration() == default_configuration
    @test Diary.read_configuration()["author"] == default_configuration["author"]
    delete!(ENV, "JULIA_DIARY_CONFIG")

    configuration_file = joinpath(
        dirname(Pkg.project().path),
        "Diary.toml",
    )
    touch(configuration_file)
    @test Diary.find_configuration_file() == configuration_file

    open(configuration_file, write=true) do io
        println(io, "author = \"Test\"")
    end
    @test Diary.read_configuration()["author"] == "Test"

    open(configuration_file, write=true) do io
        println(io, "12 34")
    end

    @test_logs(
        (
            :warn,
            string(
                "Diary.jl: an error occured while parsing configuration file: ",
                configuration_file,
            )
        ),
        Diary.read_configuration(),
    )

    # Clean-up
    rm(configuration_file)
end

@testset "Finding Diary" begin
    @testset "Basic functionality" begin
        Pkg.activate()
        default_path = joinpath(
            dirname(Pkg.project().path),
            "diary.jl",
        )
        @test Diary.find_diary() == default_path
        @test isfile(default_path)
    end

    @testset "Environment variable" begin
        env_path = joinpath(dirname(Pkg.project().path), "env_diary.jl")
        ENV["JULIA_DIARY"] = env_path
        @test Diary.find_diary() == env_path
        @test isfile(env_path)
        delete!(ENV, "JULIA_DIARY")
    end

    @testset "Blacklist" begin
        # Test that the default environment is blacklisted by default.
        Pkg.activate("v$(VERSION.major).$(VERSION.minor)"; shared=true)
        @test isnothing(Diary.find_diary(; configuration=Diary.default_configuration()))
    end

    @testset "Create missing" begin
        Pkg.activate()

        configuration = merge!(
            Diary.default_configuration(),
            Dict{String,Any}(
                "create_if_missing" => false,
            ),
        )

        diary_file_path = Diary.find_diary_path(; configuration=configuration)
        rm(diary_file_path, force=true)
        @test isnothing(Diary.find_diary(; configuration=configuration))
    end

    @testset "Directory mode" begin
        Pkg.activate()

        configuration = merge!(
            Diary.default_configuration(),
            Dict{String,Any}(
                "directory_mode" => true,
            ),
        )

        directory = mktempdir(dirname(Pkg.project().path))
        expected_dir = abspath(joinpath(directory, "diary.jl"))
        cd(directory) do
            @test Diary.find_diary(; configuration=configuration) == expected_dir
        end
    end
end

@testset "Header" begin
    Pkg.activate()

    configuration = merge!(
        Diary.default_configuration(),
        Dict{String,Any}(
            "author" => "Test",
            "date_format" => "",
        ),
    )

    diary_file = Diary.find_diary()
    open(diary_file, write=true) do io
        Diary.write_header(io; configuration=configuration)
    end

    @test readline(diary_file) == "# Test: "

    # Clean-up
    rm(diary_file)
end

@testset "Committing" begin
    Pkg.activate()

    configuration = merge!(
        Diary.default_configuration(),
        Dict{String,Any}(
            "author" => "Test",
            "date_format" => "",
        ),
    )

    push!(Diary.GLOBAL_SEGMENT_BUFFER, ["a = rand(100)"])

    diary_file = Diary.find_diary(; configuration=configuration)
    Diary.commit(; diary_file=diary_file, configuration=configuration)

    @test readlines(Diary.find_diary(; configuration=configuration)) == ["# Test: ", "", "a = rand(100)"]

    push!(Diary.GLOBAL_SEGMENT_BUFFER, ["function f(x)", "    return x^2", "end"])

    diary_file = Diary.find_diary(; configuration=configuration)
    Diary.commit(; diary_file=diary_file, configuration=configuration, with_header=false)

    expected_output = [
        "# Test: ",
        "",
        "a = rand(100)",
        "",
        "function f(x)",
        "    return x^2",
        "end",
        "",
    ]
    @test readlines(Diary.find_diary(; configuration=configuration)) == expected_output

    @testset "Erasing" begin
        Diary.erase_diary(; diary_file=diary_file, configuration=configuration)
        @test readlines(Diary.find_diary(; configuration=configuration)) == []
    end

    # Clean-up
    rm(diary_file)
end

@testset "Interactivity" begin
    Pkg.activate()
    # Re-initialise Diary, enabling the watcher.
    ENV["JULIA_HISTORY"] = tempname()
    touch(ENV["JULIA_HISTORY"])
    repl_history_file = ENV["JULIA_HISTORY"]
    Diary.__init__(enabled=true)
    # Locate relevant files.
    history_file = ENV["JULIA_HISTORY"]
    configuration_file = joinpath(dirname(Pkg.project().path), "Diary.toml")
    # Write the configuration.
    open(configuration_file, write=true) do io
        join(io, ["author = \"Test\"", "date_format = \"\""], "\n")
        print(io, "\n")
    end
    diary_file = Diary.find_diary()

    @test Diary.read_configuration()["author"] == "Test"
    @test Diary.read_configuration()["date_format"] == ""

    # Simulate user interaction by writing lines to the history file.
    history_lines = [
        "# time: ***",
        "# mode: julia",
	"\ta = rand(100);",
    ]
    open(history_file, read=true, write=true) do io
        seekend(io)
        join(io, history_lines, "\n")
        print(io, "\n")
    end
    # Allow the `watch_task` to update the diary file.
    file_event = FileWatching.watch_file(diary_file, 5)
    @test file_event.changed || file_event.timedout
    @test readlines(diary_file) == ["# Test: ", "", "a = rand(100)"]
    @test readlines(repl_history_file) == history_lines

    # Add line with incorrect syntax and check that it does not update the diary file.
    history_lines = [
        "# time: ***",
        "# mode: julia",
	"\ta b c d e",
    ]
    open(history_file, read=true, write=true) do io
        seekend(io)
        join(io, history_lines, "\n")
        print(io, "\n")
    end
    # Allow the `watch_task` to update the diary file.
    file_event = FileWatching.watch_file(diary_file, 5)
    @test file_event.timedout
    @test readlines(diary_file) == ["# Test: ", "", "a = rand(100)"]

    @testset "Non-persistent history" begin
        previous_history_lines = readlines(repl_history_file)

        open(configuration_file, write=true) do io
            configuration = [
                "author = \"Test\"",
                "date_format = \"\"",
                "persistent_history = false",
            ]
            join(io, configuration, "\n")
            print(io, "\n")
        end
        # Simulate user interaction by writing lines to the history file.
        open(history_file, read=true, write=true) do io
            seekend(io)
            join(io, ["# time: ***", "# mode: julia", "\tb = 42"], "\n")
            print(io, "\n")
        end
        # Allow the `watch_task` to update the diary file.
        file_event = FileWatching.watch_file(diary_file, 5)
        @test file_event.changed || file_event.timedout
        @test readlines(diary_file) == ["# Test: ", "", "a = rand(100)", "b = 42"]
        # Test that the original history file hasn't changed.
        @test readlines(repl_history_file) == previous_history_lines
    end

    @testset "File polling" begin
        open(configuration_file, write=true) do io
            configuration = [
                "author = \"Test\"",
                "date_format = \"\"",
                "file_polling = true",
            ]
            join(io, configuration, "\n")
            print(io, "\n")
        end
        # Trigger a configuration refresh to make the task switch to polling, and erase the
        # diary.
        open(history_file, read=true, write=true) do io
            seekend(io)
            join(io, ["# time: ***", "# mode: julia", "\t# diary: erase"], "\n")
            print(io, "\n")
        end
        # Allow the diary to synchronise before wiping it.
        sleep(5)
        # Write the actual history lines we want to check up against.
        open(history_file, read=true, write=true) do io
            seekend(io)
            join(io, ["# time: ***", "# mode: julia", "\tc = 13"], "\n")
            print(io, "\n")
        end
        file_event = FileWatching.watch_file(diary_file, 5)
        @test file_event.changed || file_event.timedout
        @test readlines(diary_file) == ["c = 13"]
    end

    # Clean-up
    rm(configuration_file)
    rm(diary_file)
end

end # module
