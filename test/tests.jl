#=====================
pkg > activate .
pkg > add Test
pkg > test Plasmatrace
======================#

using Test, CSV
import Plots

function loadtest()
    run = load("data",instrument="Agilent")
    return run
end

function plottest()
    myrun = loadtest()
    p = plot(myrun[1],channels=["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
    p = plot(myrun[1],channels=["Hf176 -> 258","Hf178 -> 260"],den=["Hf178 -> 260"])
    @test display(p) != NaN
end

function windowtest()
    myrun = loadtest()
    for i in eachindex(myrun)
        setBwin!(myrun[i],[(10,20)])
        setSwin!(myrun[i],[(60,70),(80,100)])
    end
end

function plotwindowtest()
    myrun = loadtest()
    i = 2
    setSwin!(myrun[i],[(70,90),(100,140)])
    p = plot(myrun[i],channels=["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
end

function blanktest()
end

function forwardtest()
end

function standardtest()
end

function fractionationtest()
end

function averagetest()
end

function TUItest()
end

Plots.closeall()

@testset "load" begin loadtest() end
@testset "plot raw data" begin plottest() end
@testset "set selection window" begin windowtest() end
@testset "plot selection windows" begin plotwindowtest() end
