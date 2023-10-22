function getAB(refmat::String)
    if refmat=="Hogsbo"
        t = (1029,1.7)
        y0 = (3.55,0.05)
        lambda = (1.867e-05,8e-08)
    else
        PTerror("UnknownRefMat")
    end
    DP = exp(lambda[1]*t[1])-1
    x0 = 1/DP
    A = y0[1]
    B = -A/x0
    return A, B
end

function setAB!(pd::run,refmat::Union{String,Vector{String}})
    if isa(refmat,String) refmat = [refmat] end
    nref = size(refmat,1)
    A = fill(0.0,nref)
    B = fill(0.0,nref)
    for i in eachindex(refmat)
        A[i], B[i] = getAB(refmat[i])
    end
    ctrl = getControl(pd)
    if isnothing(ctrl)
        ctrl = control(A,B,nothing)
    else
        ctrl.A = A
        ctrl.B = B
    end
    setControl!(pd,ctrl)
end
