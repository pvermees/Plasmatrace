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

# mutable extension of SAMPLE
mutable struct sample <: processed
    data::SAMPLE
    blank::Union{Nothing,Vector{window}}
    signal::Union{Nothing,Vector{window}}
    channels::Union{Nothing,Vector{String}}
    par::Union{Nothing,Vector}
    cov::Union{Nothing,Matrix}
end

# mutable extension of RUN
mutable struct run <: processed
    data::RUN
    blank::Vector{Union{Nothing,Vector{window}}}
    signal::Vector{Union{Nothing,Vector{window}}}
    channels::Union{Nothing,Vector{String}}
    par::Union{Nothing,Vector}
    cov::Union{Nothing,Matrix}
end
