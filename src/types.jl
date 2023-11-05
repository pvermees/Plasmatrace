const sph = 3.6e6 # seconds per hour
const window = Tuple{Int,Int}
abstract type plasmaData end

mutable struct control
    instrument::Union{Nothing,AbstractString}
    method::Union{Nothing,AbstractString}
    A::Union{Nothing,AbstractVector{AbstractFloat}}
    B::Union{Nothing,AbstractVector{AbstractFloat}}
    isotopes::Union{Nothing,AbstractVector{AbstractString}}
    channels::Union{Nothing,AbstractVector{AbstractString}}
end

mutable struct sample <: plasmaData
    sname::AbstractString
    datetime::DateTime
    dat::DataFrame
    bwin::Union{Nothing,AbstractVector{window}}
    swin::Union{Nothing,AbstractVector{window}}
    standard::Integer
end

mutable struct run <: plasmaData
    samples::Union{Nothing,AbstractVector{sample}}
    control::Union{Nothing,control}
    bpar::Union{Nothing,AbstractVector}
    spar::Union{Nothing,AbstractVector}
    bcov::Union{Nothing,Matrix}
    scov::Union{Nothing,Matrix}
end

mutable struct TUIpars
    chain::AbstractVector{AbstractString}
    i::Integer
    history::DataFrame
    channels::Union{Nothing,AbstractVector{AbstractString}}
    den::Union{Nothing,AbstractVector{AbstractString}}
    prefixes::Union{Nothing,AbstractVector{AbstractString}}
    refmats::Union{Nothing,AbstractVector{AbstractString}}
    n::AbstractVector{Integer}
    prioritylist::Dict
end

sample(sname,datetime,dat) = sample(sname,datetime,dat,nothing,nothing,0)

control() = control(nothing,nothing,nothing,nothing,nothing,nothing)

run(samples) = run(samples,control(),nothing,nothing,nothing,nothing)

run() = run(nothing)
