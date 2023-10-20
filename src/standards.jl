function fitStandards!(pd::run;method="LuHf",
                       refmat::Union{String,Vector{String}}="Hogsbo",
                       snames::Union{Nothing,String,Vector{String}}=nothing,
                       prefix::Union{Nothing,String,Vector{String}}=nothing,
                       i::Union{Nothing,Vector{Int},Vector{Vector{Int}}}=nothing,
                       n=2)
    if isnothing(getBPar(pd)) PTerror("missingBlank") end
    
    if !isa(refmat,Vector{String}) refmat = [refmat] end
    if !isa(snames,Vector{String}) snames = [snames] end
    if !isa(prefix,Vector{String}) prefix = [prefix] end
    if !isa(i,Vector{Vector{Int}}) i = [i] end

    setDRS!(pd,method=method,refmat=refmat)
    A = getA(pd)
    B = getB(pd)
    bpar = getBPar(pd)
    nbp = Int(size(bpar,1)/3)
    bx = bpar[1:nbp]
    by = bpar[nbp+1:2*nbp]
    bz = bpar[2*nbp+1:3*nbp]
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
    
    function misfit(par)
        out = 0
        c = par[end]
        for g in groups
            ft = polyVal(par[1:n],g.t)
            FT = polyVal(par[n+1:2*n],g.T)
            X = getX(g.Xm,g.Ym,g.Zm,g.A,g.B,g.t,g.T,ft,FT,g.bXt,g.bYt,g.bZt,c)
            Z = getZ(g.Xm,g.Ym,g.Zm,g.A,g.B,g.t,g.T,ft,FT,g.bXt,g.bYt,g.bZt,c)
            out += sum(getS(X,Z,g.Xm,g.Ym,g.Zm,g.A,g.B,g.t,g.T,ft,FT,g.bXt,g.bYt,g.bZt,c))
        end
        out
    end

    init = [fill(0.0,2*n);-10.0]
    fit = optimize(misfit,init)
    sol = Optim.minimizer(fit)
    setSPar!(pd,sol)
end

function markStandards!(pd;i=nothing,prefix=nothing,snames=nothing,standard=0)
    j = findSamples(pd,snames=snames,prefix=prefix,i=i)
    setStandard!(pd,i=j,standard=standard)
    return j
end
