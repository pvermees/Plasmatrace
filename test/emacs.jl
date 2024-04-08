using Debugger

odir = pwd()
cd(@__DIR__)

include("../src/include.jl")
include("tests.jl")
#PAtest()
PT("logs/emacs.log")

cd(odir)
