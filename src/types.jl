const sph = 3.6e6 # seconds per hour

const Window = Tuple{Int,Int}
export Window

_PT::AbstractDict = Dict()
export _PT

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
