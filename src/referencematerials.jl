referenceMaterials = Dict(
    "LuHf" => Dict(
        "Hogsbo" => (t=(1029,1.7),y0=(3.55,0.05)),
        "BP" => (t=(1745,5),y0=(3.55,0.05))
    )
)

lambda = Dict(
    "LuHf" => (1.867e-05,8e-08)
)

function getx0y0(;method::T,refmat::T) where T<:AbstractString
    L = lambda[method][1]
    t = referenceMaterials[method][refmat].t[1]
    x0 = 1/(exp(L*t)-1)
    y0 = referenceMaterials[method][refmat].y0[1]
    return x0, y0
end

function setx0y0!(pd::run;refmat::Union{T,AbstractVector{T}}) where T<:AbstractString
    method = getMethod(pd)
    if isnothing(method) PTerror("undefinedMethod") end
    if isa(refmat,AbstractString) refmat = [refmat] end
    nref = size(refmat,1)
    x0 = Vector{Float64}(undef,nref)
    y0 = Vector{Float64}(undef,nref)
    for i in eachindex(refmat)
        x0[i], y0[i] = getx0y0(method=method,refmat=refmat[i])
    end
    setx0!(pd,x0)
    sety0!(pd,y0)
end
