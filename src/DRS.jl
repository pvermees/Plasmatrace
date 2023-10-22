function setDRS!(pd::run;method="LuHf",
                 refmat::Union{String,Vector{String}}="Hogsbo")
    if (method=="LuHf")
        channels = ["Lu175 -> 175","Hf178 -> 260","Hf176 -> 258"]
    end
    if isa(refmat,String) refmat = [refmat] end
    nref = size(refmat,1)
    A = fill(0.0,nref)
    B = fill(0.0,nref)
    for i in eachindex(refmat)
        A[i], B[i] = getAB(A[i],B[i],refmat[i])
    end
    setControl!(pd,control(A,B,channels))
end
