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

    # Test that the diary file was created.
    @test isfile(default_path)

    # Test that the default environment is blacklisted by default.
    Pkg.activate("v$(VERSION.major).$(VERSION.minor)"; shared=true)
    @test isnothing(Diary.find_diary())
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
