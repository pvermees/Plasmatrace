# DEFINITIONS

const sph = 3.6e6 # seconds per hour

abstract type plasmaData end
abstract type raw <: plasmaData end
abstract type processed <: plasmaData end

# immutable raw data, is used inside type 'sample'
struct SAMPLE <: raw
    sname::String
    datetime::DateTime
    labels::Vector{String}
    dat::Matrix
end

# immutable raw collection of data, is used inside type 'run'
struct RUN <: raw
    sname::Vector{String}
    datetime::Vector{DateTime}
    labels::Vector{String}
    dat::Matrix
    index::Vector{Integer}
end

const window = Tuple{Int,Int}

mutable struct control
    channels::Union{Nothing,Vector{String}}
    A::Union{Float64}
    B::Union{Float64}
end

# mutable extension of SAMPLE
mutable struct sample <: processed
    data::SAMPLE
    bwin::Union{Nothing,Vector{window}}
    swin::Union{Nothing,Vector{window}}
    control::Union{Nothing,control}
    bpar::Union{Nothing,Vector}
    spar::Union{Nothing,Vector}
    bcov::Union{Nothing,Matrix}
    scov::Union{Nothing,Matrix}
end

# mutable extension of RUN
mutable struct run <: processed
    data::RUN
    bwin::Vector{Union{Nothing,Vector{window}}}
    swin::Vector{Union{Nothing,Vector{window}}}
    control::Union{Nothing,control}
    bpar::Union{Nothing,Vector}
    spar::Union{Nothing,Vector}
    bcov::Union{Nothing,Matrix}
    scov::Union{Nothing,Matrix}
end
