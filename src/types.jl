const sph = 3.6e6 # seconds per hour
const Window = Tuple{Int,Int}

abstract type plasmaData end
abstract type hasControl <: plasmaData end
abstract type hasPars <: hasControl end

mutable struct Sample
    sname::String
    datetime::DateTime
    dat::DataFrame
    bwin::Vector{Window}
    swin::Vector{Window}
    standard::Int
end

mutable struct Control
    method::String
    x0::Vector{Float64}
    y0::Vector{Float64}
    isotopes::Vector{String}
    channels::Vector{String}
    gainOption::Integer
end

mutable struct Pars
    blank::Vector{Float64}
    drift::Vector{Float64}
    down::Vector{Float64}
    gain::Float64
end

mutable struct Run <: plasmaData
    samples::Vector{Sample}
end
mutable struct Crun <: hasControl
    samples::Vector{Sample}
    control::Control
end
mutable struct Prun <: hasPars
    samples::Vector{Sample}
    control::Control
    pars::Pars
end

struct TUIpars
    chain::Vector{String}
    i::Int
    history::DataFrame
    channels::Vector{String}
    den::Vector{String}
    prefixes::Vector{String}
    refmats::Vector{String}
    n::Vector{Int}
    prioritylist::Dict
end
