odir = pwd()
cd(@__DIR__)

include("../src/Plasmatrace.jl")
include("tests.jl")

#PT()

cd(odir)
