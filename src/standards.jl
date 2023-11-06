function markStandards!(pd::run;i::Union{Nothing,Integer}=nothing,
                        prefix::Union{Nothing,AbstractString}=nothing,
                        snames::Union{Nothing,AbstractVector{>:AbstractString}}=nothing,
                        standard::Integer=0)
    j = findSamples(pd,snames=snames,prefix=prefix,i=i)
    setStandard!(pd,i=j,standard=standard)
end
export markStandards!
    
function fitStandards!(pd::run;
                       refmat::Union{AbstractString,AbstractVector{<:AbstractString}},
                       n=1,m=0,verbose=false)
    if isa(refmat,AbstractString) refmat = [refmat] end
    setAB!(pd,refmat=refmat)
    groups = groupStandards(pd)

    function misfit(par)
        out = 0
        aft = par[1:n]
        aFT = [0;par[n+1:n+m+1]]
        c = par[end]
        for g in groups
            t = g.s[:,1]
            T = g.s[:,2]
            Xm = g.s[:,3]
            Ym = g.s[:,4]
            Zm = g.s[:,5]
            ft = polyVal(p=aft,t=t)
            FT = polyVal(p=aFT,t=T)
            X = getX(Xm,Ym,Zm,g.A,g.B,ft,FT,g.bXt,g.bYt,g.bZt,c)
            Z = getZ(Xm,Ym,Zm,g.A,g.B,ft,FT,g.bXt,g.bYt,g.bZt,c)
            out += sum(getS(X,Z,Xm,Ym,Zm,g.A,g.B,ft,FT,g.bXt,g.bYt,g.bZt,c))
        end
        out
    end

    init = fill(0.0,n+m+1)
    fit = Optim.optimize(misfit,init)
    if verbose println(fit) end
    sol = Optim.minimizer(fit)
    par = getPar(pd)
    setDriftPars!(par,sol[1:n])
    setDownPars!(par,sol[n+1:n+m+1])
    setMassPars!(par,sol[end])
    setPar!(pd,par)
end
export fitStandards!

function groupStandards(pd::run)
    par = getPar(pd)
    if isnothing(par) PTerror("missingBlank") end
    A = getA(pd)
    B = getB(pd)
    bpar = getBlankPars(pd)
    bx = parseBPar(bpar,par="bx")
    by = parseBPar(bpar,par="by")
    bz = parseBPar(bpar,par="bz")
    std = getStandard(pd)
    groups = Vector{NamedTuple}(undef,0)
    for i in eachindex(A)
        j = findall(in(i),std)
        s = signalData(pd,channels=getChannels(pd),i=j)
        t = s[:,1]
        bXt = polyVal(p=bx,t=t)
        bYt = polyVal(p=by,t=t)
        bZt = polyVal(p=bz,t=t)
        dat = (A=A[i],B=B[i],s=s,bXt=bXt,bYt=bYt,bZt=bZt)
        push!(groups,dat)
    end
    return groups
end

function predictStandard(pd::run;sname::Union{Nothing,AbstractString}=nothing,
                         prefix::Union{Nothing,AbstractString}=nothing,
                         i::Union{Nothing,Integer}=nothing)
    fitable(pd,throw=true)
    i = findSamples(pd,i=i,prefix=prefix,snames=sname)[1]
    standard = getStandard(pd,i=i)
    if standard<1 return nothing end

    s = signalData(pd,i=i)
    t = s[:,1]
    T = s[:,2]
    Xm = s[:,3]
    Ym = s[:,4]
    Zm = s[:,5]
    
    c = getMassPars(pd)
    ft = polyVal(p=getDriftPars(pd),t=t)
    FT = polyVal(p=[0;getDownPars(pd)],t=T)
    
    bpar = getBlankPars(pd)
    bXt = polyVal(p=parseBPar(bpar,par="bx"),t=t)
    bYt = polyVal(p=parseBPar(bpar,par="by"),t=t)
    bZt = polyVal(p=parseBPar(bpar,par="bz"),t=t)
    
    A = getA(pd)[standard]
    B = getB(pd)[standard]
    X = getX(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    Z = getZ(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)

    Xp = @. X*ft*FT + bXt
    Yp = @. A*Z + B*X + bYt
    Zp = @. Z*exp(c) + bZt
    
    channels = getChannels(pd)
    DataFrame(hcat(t,T,Xp,Yp,Zp),[names(s)[1:2];channels])
end
