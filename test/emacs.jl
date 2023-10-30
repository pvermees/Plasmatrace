odir = pwd()
cd(@__DIR__)

include("../src/include.jl")

include("tests.jl")

Plots.closeall()

include("testsets.jl")

cd(odir);
