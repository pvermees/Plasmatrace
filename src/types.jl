const hour_milliseconds = 3.6e6

const window = Tuple{Int,Int}
export window

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
    sample_name::String
    analysis_name::String
    date_time::DateTime
    data::DataFrame
    blank_window::Vector{Tuple{Int, Int}}
    signal_window::Vector{Tuple{Int, Int}}
    group::String
end
export Sample

mutable struct Parameters # I think we should use a more explicit name (I assume Parameters meant Parameters)
    drift::Vector{Float64}
    downhole_fractionation::Vector{Float64}
    mass_fractionation::Float64
end
export Parameters
