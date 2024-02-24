const sph = 3.6e6 # seconds per hour

const Window = Tuple{Int,Int}
export Window

mutable struct Sample
    sname::String
    datetime::DateTime
    dat::DataFrame
    bwin::Vector{Window}
    swin::Vector{Window}
    group::String
end
export Sample

mutable struct Pars
    drift::Vector{Float64}
    down::Vector{Float64}
    mfrac::Float64
end
export Pars

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
