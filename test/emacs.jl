if !(@isdefined rerun)
    using Revise, Pkg
    Pkg.activate("/home/pvermees/git/Plasmatrace")
    Pkg.instantiate()
    Pkg.precompile()
    cd("/home/pvermees/git/Plasmatrace/test")
end

rerun = true

include("runtests.jl")

PT!(logbook="logs/concentrations.log")
