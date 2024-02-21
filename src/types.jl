const sph = 3.6e6 # seconds per hour

const Window = Tuple{Int,Int}
export Window

mutable struct Sample
    sname::String
    datetime::DateTime
    dat::DataFrame
    bwin::Vector{Window}
    swin::Vector{Window}
    standard::Int
end
export Sample

struct Pairing
    name::String
    pairs::NamedTuple{(:d,:D,:P),Tuple{String,String,String}}
end
export Pairing

struct Reference
    x0::Float64
    y0::Float64
end
export Standard

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
