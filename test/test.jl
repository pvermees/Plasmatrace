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
    fitBlanks!(myrun,method="LuHf",n=2);
    b = blankData(myrun);
    t = b[:,1]
    bpar = getBPar(myrun);
    bx = parseBPar(bpar,par="bx")
    by = parseBPar(bpar,par="by")
    bz = parseBPar(bpar,par="bz")
    bXt = polyVal(p=bx,t=t)
    bYt = polyVal(p=by,t=t)
    bZt = polyVal(p=bz,t=t)
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
    setDRS!(myrun;method="LuHf",refmat="BP")
    fitBlanks!(myrun,method="LuHf",n=1);
    i = findSamples(myrun,prefix="BP -")
    setStandard!(myrun,i=i[1],standard=1)
    setSPar!(myrun;spar=[0.0,4.0])
    channels = getChannels(myrun)
    plot(myrun,i=i[1],channels=channels,transformation="sqrt");
    
    timer!(tt,myrun);
    return myrun
end

function standardtest(tt=nothing)
    myrun = loadtest();
    setBlanks!(myrun);
    setSignals!(myrun);
    fitBlanks!(myrun,method="LuHf",n=2);
    markStandards!(myrun,prefix="hogsbo_",standard=1);
    markStandards!(myrun,prefix="BP -",standard=2);
    fitStandards!(myrun,
                  method="LuHf",
                  refmat=["Hogsbo","BP"],
                  n=1)
    i = findSamples(myrun,prefix="BP -")
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
