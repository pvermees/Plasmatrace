const sph = 3.6e6 # seconds per hour

const Window = Tuple{Int,Int}
export Window

_PT = Dict(
    "lambda" => Dict(
        "LuHf" => (1.867e-05,8e-08)
    ),
    "iratio" => Dict(
        "Hf174Hf177" => 0.00871,
        "Hf178Hf177" => 1.4671,
        "Hf179Hf177" => 0.7325,
        "Hf180Hf177" => 1.88651
    ),
    "refmat" => Dict(
        "LuHf" => Dict(
            "Hogsbo" => (t=(1029,1.7),y0=(3.55,0.05)),
            "BP" => (t=(1745,5),y0=(3.55,0.05))
        )
    )
)
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
