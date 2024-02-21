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
    i = 2
    setSwin!(myrun[i],[(70,90),(100,140)])
    p = plot(myrun[i],channels=["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
end

function blanktest()
    myrun = loadtest()
    blk = fitBlanks(myrun,n=3)
    pairing = Pairing("LuHf",
                      (d="Hf178 -> 260",D="Hf176 -> 258",P="Lu175 -> 175"))
    println(blk[:,collect(values(pairing.pairs))])
end

function forwardtest()
end

function fractionationtest()
end

function averagetest()
end

function TUItest()
end

Plots.closeall()

@testset "load" begin loadtest() end
#@testset "plot raw data" begin plottest() end
#@testset "set selection window" begin windowtest() end
@testset "set method and blanks" begin blanktest() end

