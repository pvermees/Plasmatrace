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

_PT::AbstractDict = Dict()

function init_PT!()
    _PT["methods"] = getMethods()
    _PT["lambda"] = getLambdas()
    _PT["iratio"] = getiratios()
    _PT["nuclides"] = getNuclides()
    _PT["refmat"] = getReferenceMaterials()
    _PT["glass"] = getGlass()
    _PT["tree"] = getPTree()
    _PT["ctrl"] = nothing
    _PT["extensions"] = nothing
end
export init_PT!
