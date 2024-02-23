#=====================
pkg > activate .
pkg > add Test
pkg > test Plasmatrace
======================#

using Test, CSV
import Plots

function loadtest(verbatim=false)
    run = load("data",instrument="Agilent")
    if verbatim summarise(run) end
    return run
end

function plottest()
    myrun = loadtest()
    p = plot(myrun[1],["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
    p = plot(myrun[1],["Hf176 -> 258","Hf178 -> 260"],den=["Hf178 -> 260"])
    @test display(p) != NaN
end

function windowtest()
    myrun = loadtest()
    i = 2
    setSwin!(myrun[i],[(70,90),(100,140)])
    p = plot(myrun[i],["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
end

function blanktest()
    myrun = loadtest()
    blk = fitBlanks(myrun,n=3)
    return myrun, blk
end

function standardtest(verbatim=false)
    myrun, blk = blanktest()
    standards = Dict("BP" => "BP", "Hogsbo" => "hogsbo_ana")
    setStandards!(myrun,standards)
    anchors = getAnchor("LuHf",standards)
    if verbatim
        summarise(myrun)
        println(anchors)
    end
end

function fractionationtest()
    myrun, blk = blanktest()
    channels = Dict("d" => "Hf178 -> 260", "D" => "Hf176 -> 258", "P" => "Lu175 -> 175")
    standards = Dict("BP" => "BP", "Hogsbo" => "hogsbo_ana")
    setStandards!(myrun,standards)
    anchors = getAnchor("LuHf",standards)
    par = fractionation(myrun,blank=blk,channels=channels,anchors=anchors,verbose=true)
    println(par)
end

function averagetest()
end

function TUItest()
end

Plots.closeall()

#@testset "load" begin loadtest() end
#@testset "plot raw data" begin plottest() end
#@testset "set selection window" begin windowtest() end
#@testset "set method and blanks" begin blanktest() end
#@testset "assign standards" begin standardtest(true) end
@testset "fit fractionation" begin fractionationtest() end
