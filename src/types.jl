const Window = Tuple{Int,Int}
export Window

mutable struct Sample
    sname::String
    datetime::DateTime
    dat::DataFrame
    t0::Float64
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

_PT::AbstractDict = Dict()

function init_PT!()
    _PT["methods"] = getMethods()
    _PT["lambda"] = getLambdas()
    _PT["iratio"] = getiratios()
    _PT["refmat"] = getReferenceMaterials()
    _PT["glass"] = getGlass()
end
export init_PT!
