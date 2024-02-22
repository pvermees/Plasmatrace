referenceMaterials = Dict(
    "LuHf" => Dict(
        "Hogsbo" => (t=(1029,1.7),y0=(3.55,0.05)),
        "BP" => (t=(1745,5),y0=(3.55,0.05))
    )
)

lambda = Dict(
    "LuHf" => (1.867e-05,8e-08)
)

function setStandards!(run::Vector{Sample},prefix::AbstractString,refmat::AbstractString)
    snames = getSnames(run)
    selection = findall(contains(prefix),snames)
    for i in selection
        run[i].group = refmat
    end
end
function setStandards!(run::Vector{Sample},standards::Dict)
    for (refmat,prefix) in standards
        setStandards!(run,prefix,refmat)
    end
end
function setStandards!(run::Vector{Sample})
    for sample in run
        sample.group = "sample" # reset
    end
end
export setStandards!

function getx0y0(method::AbstractString,refmat::AbstractString)
    L = lambda[method][1]
    t = referenceMaterials[method][refmat].t[1]
    x0 = 1/(exp(L*t)-1)
    y0 = referenceMaterials[method][refmat].y0[1]
    return (x0=x0, y0=y0)
end

function getAnchor(method::String,refmat::String)
    if method=="LuHf"
        return getx0y0(method,refmat)
    end
end
function getAnchor(method::AbstractString,standards::Dict)
    nr = length(standards)
    out = Dict{String, NamedTuple}()
    for (refmat,prefix) in standards
        out[refmat] = getAnchor(method,refmat)
    end
    return out
end
export getAnchor
