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
    fitBlanks!(myrun);
    timer!(tt,myrun);
    return myrun
end

function standardtest(tt=nothing)
    myrun = loadtest();
    setBlanks!(myrun);
    setSignals!(myrun);
    fitBlanks!(myrun);
    fitStandards!(myrun,method="LuHf",
                  refmat="Hogsbo",prefix="hogsbo_");
    timer!(tt,myrun);
    return myrun
end

tt = [time()]; # start clock

out = loadtest(tt);
plottest(tt);
out = windowtest(tt);
plotwindowtest(tt);
out = blanktest(tt);
out = standardtest(tt);

println(round.(tt[2:end]-tt[1:end-1],digits=4)) # print timings

cd(odir);
