odir = pwd();
cd(@__DIR__);
dir ="../src/";

include(dir*"dependencies.jl")
include(dir*"types.jl")
include(dir*"io.jl")
include(dir*"plots.jl")
include(dir*"windows.jl")

closeall();

tests = ["load","blank"];
testlist = ["load","plot","blank"];

if "load" in tests
    dname = "/home/pvermees/Documents/Plasmatrace/GlorieGarnet/";
    myrun = load(dname);
end
if "plot" in tests
    plot(myrun,channels=["Hf176 -> 258","Hf178 -> 260"]);
end
if "blank" in tests
    setBlank!(myrun);
    setBlank!(myrun,blank=[window(0,10),window(12,15)],i=1);
    dump(myrun.blanks,maxdepth=3)
end

cd(odir);
