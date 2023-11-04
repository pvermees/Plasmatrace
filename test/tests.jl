using Test, CSV
import Plots

function loadtest()
    dname = "/home/pvermees/Documents/Plasmatrace/GlorieGarnet/"
    out = run()
    DRS!(out,
         method="LuHf",
         channels=["Lu175 -> 175","Hf178 -> 260","Hf176 -> 258"])
    load!(out,dname=dname,instrument="Agilent")
    out
end

function plottest(option=0)
    myrun = loadtest()
    if option==0 || option==1
        p = plot(myrun,i=1,channels=["Hf176 -> 258","Hf178 -> 260"])
        @test display(p) != NaN
    end
    if option==0 || option==2
        p = plot(myrun,i=1)
        @test display(p) != NaN
    end
    if option==0 || option==3
        p = plot(myrun)
        @test display(p) != NaN
    end
    if option==0 || option==4
        p = plot(myrun,i=3,
                 num=["Lu175 -> 175","Hf178 -> 260"],
                 den=["Hf176 -> 258"])
        @test display(p) != NaN
    end
end

function windowtest()
    myrun = loadtest()
    setBlanks!(myrun,windows=[(10,20)])
    setBlanks!(myrun,windows=[(0,10),(12,15)],i=[2,3])
    setBlanks!(myrun,i=1)
    setSignals!(myrun,windows=[(10,20)])
    setSignals!(myrun,windows=[(60,70),(80,100)],i=2)
    setSignals!(myrun,i=1)
end

function plotwindowtest()
    myrun = loadtest()
    setBlanks!(myrun)
    setSignals!(myrun)
    setSignals!(myrun,windows=[(70,90),(100,140)],i=2)
    p = plot(myrun,channels=["Hf176 -> 258","Hf178 -> 260"],i=2)
    @test display(p) != NaN
end

function blanktest()
    myrun = loadtest()
    setBlanks!(myrun)
    fitBlanks!(myrun,n=2)
    b = Matrix(blankData(myrun))
    t = b[:,1]
    bpar = getBPar(myrun)
    bx = parseBPar(bpar,par="bx")
    by = parseBPar(bpar,par="by")
    bz = parseBPar(bpar,par="bz")
    bXt = polyVal(p=bx,t=t)
    bYt = polyVal(p=by,t=t)
    bZt = polyVal(p=bz,t=t)
    p = Plots.plot(t,b[:,3:5])
    p = Plots.plot!(p,t,hcat(bXt,bYt,bZt),linecolor="black")
    @test display(p) != NaN
end

function forwardtest()
    myrun = loadtest()
    setBlanks!(myrun)
    setSignals!(myrun)
    fitBlanks!(myrun,n=1)
    i = findSamples(myrun,prefix="BP -")
    setStandard!(myrun,i=i[1],standard=1)
    setSPar!(myrun,[4.0,-0.34])
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
    fitStandards!(myrun,refmat=["BP","Hogsbo"],n=1,verbose=true)
    i = findSamples(myrun,prefix="BP -")
    if doplot
        p = plot(myrun,i=i[1])
        @test display(p) != NaN
        p = plot(myrun,i=i[1],
                 num=["Lu175 -> 175","Hf178 -> 260"],
                 den=["Hf176 -> 258"])
        @test display(p) != NaN
    end
    return myrun
end

function atomictest()
    myrun = standardtest(false)
    i = findSamples(myrun,prefix="BP -")
    p = plotAtomic(myrun,i=i[1],scatter=true)
    @test display(p) != NaN
end

function calibrationtest()
    myrun = standardtest(false)
    p = plotCalibration(myrun)
    @test display(p) != NaN
end

function averagetest()
    myrun = loadtest()
    setBlanks!(myrun)
    setSignals!(myrun)
    fitBlanks!(myrun,n=2)
    markStandards!(myrun,prefix="BP -",standard=1)
    fitStandards!(myrun,refmat=["BP"],n=1,verbose=true)
    i = findSamples(myrun,prefix="hogsbo")
    out = fitSamples(myrun,i=i,den=["Hf176"])
    CSV.write("hogsbo.csv",out)
end

Plots.closeall()

if false
    @testset "load" begin loaddat = loadtest() end
    @testset "plot raw data" begin plottest() end
    @testset "set selection window" begin windowout = windowtest() end
    @testset "plot selection windows" begin plotwindowtest() end
    @testset "set blanks" begin blankout = blanktest() end
    @testset "forward model" begin forwardout = forwardtest() end
    @testset "fit standards" begin standardout = standardtest() end
    @testset "plot atomic" begin atomictest() end
    @testset "plot calibration" begin calibrationtest() end
    @testset "average results" begin averagetest() end
end
