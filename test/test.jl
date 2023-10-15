odir = pwd()
cd(@__DIR__)
dir ="../src/"

include(dir*"dependencies.jl")
include(dir*"types.jl")
include(dir*"io.jl")
include(dir*"plots.jl")
include(dir*"windows.jl")

closeall()

dname = "/home/pvermees/Documents/plasmatrace/GlorieGarnet/"
myrun = load(dname)
plot(myrun,channels=["Hf176 -> 258","Hf178 -> 260"])
chooseBlank!(myrun,blank=[window(0,10),window(12,15)],i=1)

cd(odir)
