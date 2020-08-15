module TestDiary

using Test, Diary

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
    @test Diary.parse_command(cmd) == 0
    cmd = "commit 1"
    @test Diary.parse_command(cmd) == 0
    cmd = "commit 1 2"
    @test_logs (:error, "Diary.jl: too many arguments to `commit`: 2, expected 1") Diary.parse_command(cmd)
    cmd = "unsupported command"
    @test_logs (:error, "Diary.jl: could not parse command: $cmd") Diary.parse_command(cmd)
end

@testset "Finding configuration" begin
    haskey(ENV, "JULIA_DIARY_CONFIG") && return

    Pkg.activate()
    default_configuration = Dict{String,Any}(
        "author" => "",
        "diary_name" => "diary.jl",
        "date_format" => "E U d HH:MM",
        "autocommit" => true,
        "directory_mode" => false,
        "blacklist" => [
           joinpath(ENV["HOME"], ".julia", "environments"),
        ]
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
end

@testset "Finding Diary" begin
    Pkg.activate()
    default_path = joinpath(
        dirname(Pkg.project().path),
        "diary.jl",
    )
    @test Diary.find_diary() == default_path
    @test isfile(default_path)

    env_path = joinpath(dirname(Pkg.project().path), "env_diary.jl")
    ENV["JULIA_DIARY"] = env_path
    @test Diary.find_diary() == env_path
    @test isfile(env_path)
    delete!(ENV, "JULIA_DIARY")

    # Test that the default environment is blacklisted by default.
    Pkg.activate("v$(VERSION.major).$(VERSION.minor)"; shared=true)
    @test isnothing(Diary.find_diary())

    Pkg.activate()
    configuration = Dict{String,Any}(
        "directory_mode" => true,
        "diary_name" => "diary.jl",
        "blacklist" => [],
    )
    directory = mktempdir(dirname(Pkg.project().path))
    expected_dir = abspath(joinpath(directory, "diary.jl"))
    cd(directory) do
        @test Diary.find_diary(; configuration) == expected_dir
    end
end

@testset "Header" begin
    Pkg.activate()
    configuration = Dict{String,Any}(
        "author" => "Test",
        "date_format" => "",
    )
    diary_file = Diary.find_diary()
    open(diary_file, write=true) do io
        Diary.write_header(io; configuration)
    end

    @test readline(diary_file) == "# Test: "

    # Clean-up
    rm(diary_file)
end

@testset "Committing" begin
    Pkg.activate()
    configuration = Dict{String,Any}(
        "author" => "Test",
        "date_format" => "",
        "diary_name" => "diary.jl",
        "directory_mode" => false,
        "blacklist" => [],
    )
    push!(Diary.GLOBAL_SEGMENT_BUFFER, ["a = rand(100)"])

    diary_file = Diary.find_diary(; configuration)
    Diary.commit(; diary_file, configuration)

    @test readlines(Diary.find_diary(; configuration)) == ["# Test: ", "", "a = rand(100)"]

    push!(Diary.GLOBAL_SEGMENT_BUFFER, ["function f(x)", "    return x^2", "end"])

    diary_file = Diary.find_diary(; configuration)
    Diary.commit(; diary_file, configuration, with_header=false)

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
    @test readlines(Diary.find_diary(; configuration)) == expected_output
    # Clean-up
    rm(diary_file)
end

@testset "Interactivity" begin
    Pkg.activate()
    # Re-initialise Diary, enabling the watcher.
    ENV["JULIA_HISTORY"] = tempname()
    touch(ENV["JULIA_HISTORY"])
    Diary.__init__(enabled=true)
    # Locate relevant files.
    history_file = ENV["JULIA_HISTORY"]
    diary_file = Diary.find_diary()
    configuration_file = joinpath(dirname(Pkg.project().path), "Diary.toml")
    # Write the configuration.
    open(configuration_file, write=true) do io
        join(io, ["author = \"Test\"", "date_format = \"\""], "\n")
        print(io, "\n")
    end
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
    # Allow the watch task to update the diary file.
    sleep(0.1)

    @test readlines(diary_file) == ["# Test: ", "", "a = rand(100)"]
    # Clean-up
    rm(diary_file)
end

end # module
