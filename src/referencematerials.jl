referenceMaterials = Dict(
    "LuHf" => Dict(
        "Hogsbo" => (t=(1029,1.7),y0=(3.55,0.05)),
        "BP" => (t=(1745,5),y0=(3.55,0.05))
    )
)

lambda = Dict(
    "LuHf" => (1.867e-05,8e-08)
)

function getAB(;method::String,refmat::String)
    L = lambda[method][1]
    t = referenceMaterials[method][refmat].t[1]
    y0 = referenceMaterials[method][refmat].y0[1]
    DP = exp(L*t)-1
    x0 = 1/DP
    A = y0
    B = -A/x0
    return A, B
end

function setAB!(pd::run;refmat::Union{String,Vector{String}})
    method = getMethod(pd)
    if isnothing(method) PTerror("undefinedMethod") end
    if isa(refmat,String) refmat = [refmat] end
    nref = size(refmat,1)
    A = Vector{AbstractFloat}(undef,nref)
    B = Vector{AbstractFloat}(undef,nref)
    for i in eachindex(refmat)
        A[i], B[i] = getAB(method=method,refmat=refmat[i])
    end
    setA!(pd,A)
    setB!(pd,B)
end
