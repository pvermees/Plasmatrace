using Debugger

odir = pwd()
cd(@__DIR__)

include("../src/include.jl")
include("tests.jl")
#@run iCaptest()
#PT("logs/emacs.log")

cd(odir)
