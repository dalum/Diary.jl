module TestDiary

using Test, Diary

using Pkg

@testset "Finding Diary" begin
    Pkg.activate()
    default_path = joinpath(
        dirname(Pkg.project().path),
        Diary.GLOBAL_CONFIG.diary_file_name
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
end

@testset "Line parsing" begin
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
end

@testset "Header" begin
    Pkg.activate()
    Diary.configure(author="Test", date_format="")
    default_path = joinpath(
        dirname(Pkg.project().path),
        Diary.GLOBAL_CONFIG.diary_file_name
    )

    open(default_path, write=true) do io
        Diary.write_header(io)
    end
    @test readline(default_path) == "# Test: "
end

end # module
