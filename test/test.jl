odir = pwd();
cd(@__DIR__);
dir ="../src/";

include(dir*"dependencies.jl")
include(dir*"types.jl")
include(dir*"constructors.jl")
include(dir*"methods.jl")
include(dir*"converters.jl")
include(dir*"io.jl")
include(dir*"plots.jl")
include(dir*"windows.jl")

closeall();

function timer!(tt=nothing,out=nothing)
    if !isnothing(tt) push!(tt,time()) end
    if !isnothing(out) return out end
end

function loadtest(tt=nothing)
    dname = "/home/pvermees/Documents/Plasmatrace/GlorieGarnet/";
    out = load(dname);
    timer!(tt,out)
end

function plottest(tt=nothing)
    myrun = loadtest();
    p = plot(myrun,channels=["Hf176 -> 258","Hf178 -> 260"]);
    timer!(tt,p)
end

function blanktest(tt=nothing)
    myrun = loadtest();
    #setBlank!(myrun,blank=[window(10,20)]);
    setBlank!(myrun);
    #setBlank!(myrun,blank=[window(0,10),window(12,15)],i=2);
    #setBlank!(myrun,i=1);
    timer!(tt,myrun)
end

function plotblanktest(tt=nothing)
    myrun = blanktest();
    plot(myrun,channels=["Hf176 -> 258","Hf178 -> 260"],i=1);
    timer!(tt,myrun)
end

tt = [time()]; # start clock

loadtest(tt);
plottest(tt);
blanktest(tt);
plotblanktest(tt);

println(round.(tt[2:end]-tt[1:end-1],digits=4)) # print timings

cd(odir);
