odir = pwd()
cd(@__DIR__)

include("../src/include.jl")

include("tests.jl")

cd(odir);
