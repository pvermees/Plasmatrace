#=====================
pkg > activate .
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
    p = plot(myrun[1],["Hf176 -> 258","Hf178 -> 260"], den=["Hf178 -> 260"])
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
    blk = fitBlanks(myrun,n=2)
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
    channels = Dict("d" => "Hf178 -> 260",
                    "D" => "Hf176 -> 258",
                    "P" => "Lu175 -> 175")
    standards = Dict("Hogsbo" => "hogsbo_ana")#, "BP" => "BP"
    setStandards!(myrun,standards)
    anchors = getAnchor("LuHf",standards)
    fit = fractionation(myrun,blank=blk,channels=channels,
                        anchors=anchors,nf=2,nF=0,mf=1.4671,verbose=true)
    return myrun, blk, fit, channels, anchors
end

function predicttest()
    myrun, blk, fit, channels, anchors = fractionationtest()
    samp = myrun[2]
    pred = predict(samp,fit,blk,channels,anchors)
    p = plot(samp,channels,den="D")
    plotFitted!(p,samp,fit,blk,channels,anchors,den="D")
    @test display(p) != NaN
end

function sampletest()
    myrun, blk, fit, channels, anchors = fractionationtest()
    t, T, P, D, d = atomic(myrun[1],channels=channels,pars=fit,blank=blk)
    ratios = averat(myrun,channels=channels,pars=fit,blank=blk)
    return ratios
end

function readmetest()
    run = load("data",instrument="Agilent")
    blk = fitBlanks(run,n=2)
    standards = Dict("Hogsbo" => "hogsbo_ana")
    setStandards!(run,standards)
    anchors = getAnchor("LuHf",standards)
    channels = Dict("d"=>"Hf178 -> 260","D"=>"Hf176 -> 258","P"=>"Lu175 -> 175")
    fit = fractionation(run,blank=blk,channels=channels,anchors=anchors,nf=1,nF=0,mf=1.4671)
    ratios = averat(run,channels=channels,pars=fit,blank=blk)
    return ratios
end

function exporttest()
    ratios = readmetest()
    selection = subset(ratios,"BP")
    CSV.write("output/BP.csv",selection)
    export2IsoplotR("output/BP.json",selection,"LuHf")
end

function TUItest()
    PT("logs/test.log")
end

Plots.closeall()

#@testset "load" begin loadtest(true) end
#@testset "plot raw data" begin plottest() end
#@testset "set selection window" begin windowtest() end
#@testset "set method and blanks" begin blanktest() end
#@testset "assign standards" begin standardtest(true) end
#@testset "fit fractionation" begin fractionationtest() end
#@testset "plot fit" begin predicttest() end
#@testset "process sample" begin sampletest() end
#@testset "readme example" begin readmetest() end
@testset "export" begin exporttest() end
#@testset "TUI" begin TUItest() end
