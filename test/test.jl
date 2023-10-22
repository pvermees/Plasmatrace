odir = pwd();
cd(@__DIR__);
dir ="../src/";

include(dir*"dependencies.jl")
include(dir*"types.jl")
include(dir*"errors.jl")
include(dir*"methods.jl")
include(dir*"io.jl")
include(dir*"plots.jl")
include(dir*"windows.jl")
include(dir*"toolbox.jl")
include(dir*"DRS.jl")
include(dir*"referencematerials.jl")
include(dir*"blanks.jl")
include(dir*"standards.jl")
include(dir*"samples.jl")
include(dir*"crunch.jl")

closeall();

function timer!(tt=nothing,out=nothing)
    if !isnothing(tt) push!(tt,time()) end
    if !isnothing(out) return out end
end

function loadtest(tt=nothing)
    dname = "/home/pvermees/Documents/Plasmatrace/GlorieGarnet/";
    out = load(dname);
    timer!(tt,out);
    return out
end

function plottest(tt=nothing)
    myrun = loadtest();
    p = plot(myrun,i=1,channels=["Hf176 -> 258","Hf178 -> 260"]);
    p = plot(myrun,i=1);
    p = plot(myrun);
    timer!(tt,p);
end

function windowtest(tt=nothing)
    myrun = loadtest();
    setBlanks!(myrun,windows=[(10,20)]);
    setBlanks!(myrun,windows=[(0,10),(12,15)],i=[2,3]);
    setBlanks!(myrun,i=1);
    setSignals!(myrun,windows=[(10,20)]);
    setSignals!(myrun,windows=[(60,70),(80,100)],i=2);
    setSignals!(myrun,i=1);
    timer!(tt,myrun);
    return myrun
end

function plotwindowtest(tt=nothing)
    myrun = loadtest();
    setBlanks!(myrun);
    setSignals!(myrun);
    setSignals!(myrun,windows=[(70,90),(100,140)],i=2);
    plot(myrun,channels=["Hf176 -> 258","Hf178 -> 260"],i=2);
    timer!(tt,myrun);
end

function blanktest(tt=nothing)
    myrun = loadtest();
    setBlanks!(myrun);
    setMethod!(myrun,method="LuHf")
    fitBlanks!(myrun,n=2);
    b = blankData(myrun);
    t = b[:,1]
    bpar = getBPar(myrun);
    bx = parseBPar(bpar,"bx")
    by = parseBPar(bpar,"by")
    bz = parseBPar(bpar,"bz")
    bXt = polyVal(bx,t)
    bYt = polyVal(by,t)
    bZt = polyVal(bz,t)
    p = Plots.plot(t,b[:,3:5]);
    p = Plots.plot!(p,t,hcat(bXt,bYt,bZt),linecolor="black");
    display(p);
    timer!(tt,myrun);
end

function methodtest(tt=nothing)
    myrun = loadtest();
    labels = ["Lu175 -> 175","Hf178 -> 260","Hf176 -> 258"]
    println(label2index(myrun,labels))
    println(getLabels(myrun,i=15))
    timer!(tt,myrun);
end

function forwardtest(tt=nothing)
    myrun = loadtest();
    setBlanks!(myrun);
    setSignals!(myrun);
    setDRS!(myrun,method="LuHf")
    fitBlanks!(myrun,n=1);
    i = findSamples(myrun,prefix="hogsbo_")
    setStandard!(myrun,i=i[1],standard=1)
    setSPar!(myrun,[5.0,-5.0])
    channels = getChannels(myrun)
    obs = signalData(myrun;channels=channels,i=i[1])
    pred = predictStandard(myrun;i=i[1])
    plot(myrun,i=i[1],transformation="sqrt");
    timer!(tt,myrun);
    return myrun
end

function standardtest(tt=nothing)
    myrun = loadtest();
    setBlanks!(myrun);
    setSignals!(myrun);
    setDRS!(myrun,method="LuHf",refmat="Hogsbo")
    fitBlanks!(myrun,n=2);
    fitStandards!(myrun,prefix="hogsbo_",n=1);
    i = findSamples(myrun,prefix="hogsbo_")
    plot(myrun,i=i[1]);
    timer!(tt,myrun);
    return myrun
end

tt = [time()]; # start clock

out = loadtest(tt);
plottest(tt);
out = windowtest(tt);
plotwindowtest(tt);
out = blanktest(tt);
out = methodtest(tt);
out = forwardtest(tt);
out = standardtest(tt);

println(round.(tt[2:end]-tt[1:end-1],digits=4)) # print timings

cd(odir);
