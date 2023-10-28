using Plasmatrace, Test
import Plots

function loadtest()
    dname = "/home/pvermees/Documents/Plasmatrace/GlorieGarnet/"
    out = load(dname)
    return out
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
    fitBlanks!(myrun,method="LuHf",n=2)
    b = blankData(myrun)
    t = b[:,1]
    bpar = Plasmatrace.getBPar(myrun)
    bx = Plasmatrace.parseBPar(bpar,par="bx")
    by = Plasmatrace.parseBPar(bpar,par="by")
    bz = Plasmatrace.parseBPar(bpar,par="bz")
    bXt = Plasmatrace.polyVal(p=bx,t=t)
    bYt = Plasmatrace.polyVal(p=by,t=t)
    bZt = Plasmatrace.polyVal(p=bz,t=t)
    p = Plots.plot(t,b[:,3:5])
    p = Plots.plot!(p,t,hcat(bXt,bYt,bZt),linecolor="black")
    @test display(p) != NaN
end

function methodtest()
    myrun = loadtest()
    labels = ["Lu175 -> 175","Hf178 -> 260","Hf176 -> 258"]
    println(Plasmatrace.label2index(myrun,labels))
    println(Plasmatrace.getLabels(myrun,i=15))
end

function forwardtest()
    myrun = loadtest()
    setBlanks!(myrun)
    setSignals!(myrun)
    Plasmatrace.setDRS!(myrun,method="LuHf",refmat="BP")
    fitBlanks!(myrun,method="LuHf",n=1)
    i = Plasmatrace.findSamples(myrun,prefix="BP -")
    setStandard!(myrun,i=i[1],standard=1)
    Plasmatrace.setSPar!(myrun,spar=[0.0,4.0])
    channels = Plasmatrace.getChannels(myrun)
    p = plot(myrun,i=i[1],channels=channels,transformation="sqrt")
    @test display(p) != NaN
    return myrun
end

function standardtest()
    myrun = loadtest()
    setBlanks!(myrun)
    setSignals!(myrun)
    fitBlanks!(myrun,method="LuHf",n=2)
    markStandards!(myrun,prefix="hogsbo_",standard=1)
    markStandards!(myrun,prefix="BP -",standard=2)
    fitStandards!(myrun,
                  method="LuHf",
                  refmat=["Hogsbo","BP"],
                  n=1)
    i = Plasmatrace.findSamples(myrun,prefix="hogsbo")
    p = plot(myrun,i=i[1])
    @test display(p) != NaN
    return myrun
end

@testset "load" begin loaddat = loadtest() end
@testset "plot" begin plottest() end
@testset "window" begin windowout = windowtest() end
@testset "plotwindow" begin plotwindowtest() end
@testset "blank" begin blankout = blanktest() end
@testset "method" begin methodout = methodtest() end
@testset "forward" begin forwardout = forwardtest() end
@testset "standard" begin standardout = standardtest() end
