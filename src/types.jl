const sph = 3.6e6 # seconds per hour
const Window = Tuple{Int,Int}

mutable struct Sample
    sname::String
    datetime::DateTime
    dat::DataFrame
    bwin::Vector{Window}
    swin::Vector{Window}
    standard::Int
end

struct Standard
    x0::Float64
    y0::Float64
    d::String
    D::String
    P::String
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
