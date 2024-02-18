const sph = 3.6e6 # seconds per hour
const Window = Tuple{Int,Int}

abstract type abstractSample end
abstract type hasWindows <: abstractSample end
abstract type hasStandards <: hasWindows end

abstract type plasmaData{T<:abstractSample} end
abstract type hasControl{T} <: plasmaData{T} end
abstract type hasPars{T} <: hasControl{T} end

mutable struct Sample <: abstractSample
    sname::String
    datetime::DateTime
    dat::DataFrame
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

mutable struct Wsample <: hasWindows
    sample::Sample
    bwin::Vector{Window}
    swin::Vector{Window}
end
mutable struct Ssample <: hasStandards
    sample::Wsample
    standard::Int
end

mutable struct Run{T} <: plasmaData{T}
    samples::Vector{T}
    instrument::String
end
mutable struct Crun{T} <: hasControl{T}
    samples::Vector{T}
    control::Control
end
mutable struct Prun{T} <: hasPars{T}
    samples::Vector{T}
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
