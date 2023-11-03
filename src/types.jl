const sph = 3.6e6 # seconds per hour
const window = Tuple{Int,Int}
abstract type plasmaData end

mutable struct control
    instrument::Union{Nothing,String}
    method::Union{Nothing,String}
    A::Union{Nothing,Vector{AbstractFloat}}
    B::Union{Nothing,Vector{AbstractFloat}}
    isotopes::Union{Nothing,Vector{String}}
    channels::Union{Nothing,Vector{String}}
end

mutable struct sample <: plasmaData
    sname::String
    datetime::DateTime
    dat::DataFrame
    bwin::Union{Nothing,Vector{window}}
    swin::Union{Nothing,Vector{window}}
    standard::Integer
end

mutable struct run <: plasmaData
    samples::Union{Nothing,Vector{sample}}
    control::Union{Nothing,control}
    bpar::Union{Nothing,Vector}
    spar::Union{Nothing,Vector}
    bcov::Union{Nothing,Matrix}
    scov::Union{Nothing,Matrix}
end

mutable struct TUIpars
    chain::Vector{String}
    history::DataFrame
    i::Integer
    channels::Union{Nothing,Vector{String}}
end

sample(sname,datetime,dat) = sample(sname,datetime,dat,nothing,nothing,0)

control() = control(nothing,nothing,nothing,nothing,nothing,nothing)

run(samples) = run(samples,control(),nothing,nothing,nothing,nothing)

run() = run(nothing)
