function fitStandards!(pd::run;method="LuHf",refmat="Hogsbo",snames=nothing,
                       prefix=nothing,i=nothing,n=2)
    
    setDRS!(pd,method=method)
    groups = standardGroups(pd,refmat=refmat,snames=snames,prefix=prefix,i=i)
    
    function misfit(par)
        out = 0
        c = par[end]
        aft = parseSPar(par,"f")
        aFT = parseSPar(par,"F")
        for g in groups
            ft = polyVal(aft,g.t)
            FT = polyVal(aFT,g.T)
            X = getX(g.Xm,g.Ym,g.Zm,g.A,g.B,ft,FT,g.bXt,g.bYt,g.bZt,c)
            Z = getZ(g.Xm,g.Ym,g.Zm,g.A,g.B,ft,FT,g.bXt,g.bYt,g.bZt,c)
            out += sum(getS(X,Z,g.Xm,g.Ym,g.Zm,g.A,g.B,ft,FT,g.bXt,g.bYt,g.bZt,c))
        end
        out
    end

    init = fill(0.0,2*n)
    fit = optimize(misfit,init)
    println(fit)
    sol = Optim.minimizer(fit)
    setSPar!(pd,sol)
end

function standardGroups(pd::run;refmat::Union{String,Vector{String}}="Hogsbo",
                       snames::Union{Nothing,String,Vector{String}}=nothing,
                       prefix::Union{Nothing,String,Vector{String}}=nothing,
                       i::Union{Nothing,Vector{Int},Vector{Vector{Int}}}=nothing)
    bpar = getBPar(pd)
    if isnothing(bpar) PTerror("missingBlank") end
    if !isa(refmat,Vector{String}) refmat = [refmat] end
    if !isa(snames,Vector{String}) snames = [snames] end
    if !isa(prefix,Vector{String}) prefix = [prefix] end
    if !isa(i,Vector{Vector{Int}}) i = [i] end
    A = getA(pd)
    B = getB(pd)
    bx = parseBPar(bpar,"bx")
    by = parseBPar(bpar,"by")
    bz = parseBPar(bpar,"bz")
    groups = Vector{NamedTuple}(undef,0)
    for j in eachindex(refmat)
        k = markStandards!(pd,i=i[j],standard=j,prefix=prefix[j],snames=snames[j])
        s = signalData(pd,channels=getChannels(pd),i=k)
        t = s[:,1]
        T = s[:,2]
        Xm = s[:,3]
        Ym = s[:,4]
        Zm = s[:,5]
        bXt = polyVal(bx,t)
        bYt = polyVal(by,t)
        bZt = polyVal(bz,t)
        dat = (A=A[j],B=B[j],t=t,T=T,Xm=Xm,Ym=Ym,Zm=Zm,bXt=bXt,bYt=bYt,bZt=bZt)
        push!(groups,dat)
    end
    return groups
end

function markStandards!(pd;i=nothing,prefix=nothing,snames=nothing,standard=0)
    j = findSamples(pd,snames=snames,prefix=prefix,i=i)
    setStandard!(pd,i=j,standard=standard)
    return j
end

function predictStandard(pd::run;
                         sname::Union{Nothing,String}=nothing,
                         prefix::Union{Nothing,String}=nothing,
                         i::Union{Nothing,Integer}=nothing)
    i = findSamples(pd,i=i,prefix=prefix,snames=sname)
    standard = getStandard(pd,i=[i])[1]
    if standard<1 return nothing end
    s = signalData(pd,i=i)
    t = s[:,1]
    T = s[:,2]
    Xm = s[:,1]
    Ym = s[:,2]
    Zm = s[:,3]
    bpar = getBPar(pd)
    spar = getSPar(pd)
    c = parseSPar(spar,"c")
    ft = polyVal(parseSPar(spar,"f"),t)
    FT = polyVal(parseSPar(spar,"F"),T)
    bXt = polyVal(parseBPar(bpar,"bx"),t)
    bYt = polyVal(parseBPar(bpar,"by"),t)
    bZt = polyVal(parseBPar(bpar,"bz"),t)
    A = getA(pd)[standard]
    B = getB(pd)[standard]
    X = getX(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    Z = getZ(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    Xp = @. X*ft*FT + bXt
    Yp = @. (A*Z+B*X)*exp(c) + bYt
    Zp = @. Z + bZt
    hcat(t,T,Xp,Yp,Zp)
end

function parseSPar(spar,par="c")
    if isnothing(spar) PTerror("missingStandard") end
    np = size(spar,1)
    n = Int(np/2)
    if (par=="c") return spar[end]
    elseif (par=="f") return spar[1:n]
    elseif (par=="F") return [0;spar[n+1:2*n-1]]
    else return nothing
    end
end
