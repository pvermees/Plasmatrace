#=====================
pkg > activate .
pkg > add Test
pkg > test Plasmatrace
======================#

using Test, CSV
import Plots

function typetest()
    println(Run <: plasmaData)
end

function loadtest()
    run = load("data",instrument="Agilent")
    return run
end

function plottest()
    myrun = loadtest()
    p = plot(myrun.samples[1],channels=["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
    p = plot(myrun.samples[1],channels=["Hf176 -> 258","Hf178 -> 260"],den=["Hf178 -> 260"])
    @test display(p) != NaN
end

function windowtest()
    myrun = loadtest()
    setBwin!(myrun,[(10,20)])
    setSwin!(myrun,[(60,70),(80,100)])
end

function plotwindowtest()
    myrun = loadtest()
    i = 2
    setSwin!(myrun,[(70,90),(100,140)],i=i)
    p = plot(myrun.samples[i],channels=["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
end

function blanktest()
    myrun = loadtest()
    setBlanks!(myrun)
    fitBlanks!(myrun,n=2)
    b = Matrix(blankData(myrun))
    t = b[:,1]
    bpar = getBlankPars(myrun)
    bP = parseBPar(bpar,par="bP")
    bD = parseBPar(bpar,par="bD")
    bd = parseBPar(bpar,par="bd")
    bPt = polyVal(p=bP,t=t)
    bDt = polyVal(p=bD,t=t)
    bdt = polyVal(p=bd,t=t)
    p = Plots.plot(t,b[:,3:5])
    p = Plots.plot!(p,t,hcat(bPt,bdt,bDt),linecolor="black")
    @test display(p) != NaN
end

function forwardtest()
    myrun = loadtest()
    setBlanks!(myrun)
    setSignals!(myrun)
    fitBlanks!(myrun,n=1)
    i = findSamples(myrun,prefix="BP -")
    setStandard!(myrun,i=i[1],standard=1)
    setDriftPars!(myrun,Float64[4.0])
    setDownPars!(myrun,Float64[])
    setGainPar!(myrun,-0.34)
    setAB!(myrun,refmat="BP")
    p = plot(myrun,i=i[1],transformation="sqrt")
    @test display(p) != NaN
    return myrun
end

function standardtest(doplot=true)
    myrun = loadtest()
    setBlanks!(myrun)
    setSignals!(myrun)
    fitBlanks!(myrun,n=2)
    markStandards!(myrun,prefix="BP -",standard=1)
    markStandards!(myrun,prefix="hogsbo_",standard=2)
    fitStandards!(myrun,refmat=["BP","Hogsbo"],n=1,m=0,verbose=true)
    i = findSamples(myrun,prefix="BP -")
    if doplot
        p = plot(myrun,i=i[1])
        @test display(p) != NaN
        p = plot(myrun,i=i[1],
                 num=["Hf178 -> 260","Lu175 -> 175"],
                 den=["Hf176 -> 258"])
        @test display(p) != NaN
    end
    return myrun
end

function atomictest()
    myrun = standardtest(false)
    i = findSamples(myrun,prefix="BP -")
    p = plotAtomic(myrun,i=i[1],scatter=true,den=["Hf176"])
    @test display(p) != NaN
end

function calibrationtest()
    myrun = standardtest(false)
    p = plotCalibration(myrun,xlim=(0,80),ylim=(0,10))
    @test display(p) != NaN
end

function averagetest()
    myrun = loadtest()
    setBlanks!(myrun)
    setSignals!(myrun)
    fitBlanks!(myrun,n=2)
    markStandards!(myrun,prefix="BP -",standard=1)
    setGainOption!(myrun,1)
    fitStandards!(myrun,refmat=["BP"],n=1,m=0,verbose=true)
    i = findSamples(myrun,prefix="hogsbo")
    out = fitSamples(myrun,i=i)
    CSV.write("/home/pvermees/Desktop/hogsbo.csv",out)
    myrun
end

function TUItest()
    PT!("logs/load.log")
    PT!("logs/autoWin.log")
    PT!("logs/singleWin.log")
    PT!("logs/BP.log")
    PT!("logs/hogsbo.log")
    PT!("logs/polyN.log")
end

Plots.closeall()

@testset "type hierarchy" begin typetest() end
@testset "load" begin loadtest() end
@testset "plot raw data" begin plottest() end
@testset "set selection window" begin windowtest() end
@testset "plot selection windows" begin plotwindowtest() end
#=
@testset "set blanks" begin blankout = blanktest() end
@testset "forward model" begin forwardout = forwardtest() end
@testset "fit standards" begin standardout = standardtest() end
@testset "plot atomic" begin atomictest() end
@testset "plot calibration" begin calibrationtest() end
@testset "average results" begin averagetest() end
@testset "TUI tests" begin TUItest() end
=#
