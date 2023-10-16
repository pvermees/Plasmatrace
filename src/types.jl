# DEFINITIONS

abstract type plasmaData end

# immutable raw data, is used inside type 'sample'
struct SAMPLE <: plasmaData
    sname::String
    datetime::DateTime
    labels::Vector{String}
    dat::Matrix
end

# immutable raw collection of data, is used inside type 'run'
struct RUN <: plasmaData
    snames::Vector{String}
    datetimes::Vector{DateTime}
    labels::Vector{String}
    dat::Matrix
    index::Vector{Integer}
end

mutable struct window
    from::Integer
    to::Integer
end

# mutable extension of SAMPLE with blank and signal windows
mutable struct sample
    data::SAMPLE
    blank::Union{Nothing,Vector{window}}
    signal::Union{Nothing,Vector{window}}
    par::Union{Nothing,Vector}
    cov::Union{Nothing,Matrix}
end

# mutable extension of RUN with blank and signal window collections
mutable struct run
    data::RUN
    blanks::Vector{Union{Nothing,Vector{window}}}
    signals::Vector{Union{Nothing,Vector{window}}}
    par::Union{Nothing,Vector}
    cov::Union{Nothing,Matrix}
end
