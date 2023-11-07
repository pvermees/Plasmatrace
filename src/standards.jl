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
        aFT = [0.0;par[n+1:n+m]]
        c = par[end]
        for g in groups
            t = g.s[:,1]
            T = g.s[:,2]
            Pm = g.s[:,3]
            dm = g.s[:,4]
            Dm = g.s[:,5]
            ft = polyVal(p=aft,t=t)
            FT = polyVal(p=aFT,t=T)
            P = getP(Pm,Dm,dm,g.A,g.B,ft,FT,g.bPt,g.bDt,g.bdt,c)
            D = getD(Pm,Dm,dm,g.A,g.B,ft,FT,g.bPt,g.bDt,g.bdt,c)
            out += sum(getS(P,D,Pm,Dm,dm,g.A,g.B,ft,FT,g.bPt,g.bDt,g.bdt,c))
        end
        out
    end

    init = fill(0.0,n+m+1)
    fit = Optim.optimize(misfit,init)
    if verbose println(fit) end
    sol = Optim.minimizer(fit)
    setDriftPars!(pd,sol[1:n])
    setDownPars!(pd,sol[n+1:n+m])
    setMassPars!(pd,sol[end])
end
export fitStandards!

function groupStandards(pd::run)
    par = getPar(pd)
    if isnothing(par) PTerror("missingBlank") end
    A = getA(pd)
    B = getB(pd)
    bpar = getBlankPars(pd)
    bP = parseBPar(bpar,par="bP")
    bD = parseBPar(bpar,par="bD")
    bd = parseBPar(bpar,par="bd")
    std = getStandard(pd)
    groups = Vector{NamedTuple}(undef,0)
    for i in eachindex(A)
        j = findall(in(i),std)
        s = signalData(pd,channels=getChannels(pd),i=j)
        t = s[:,1]
        bPt = polyVal(p=bP,t=t)
        bDt = polyVal(p=bD,t=t)
        bdt = polyVal(p=bd,t=t)
        dat = (A=A[i],B=B[i],s=s,bPt=bPt,bdt=bdt,bDt=bDt)
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
    Pm = s[:,3]
    dm = s[:,4]
    Dm = s[:,5]
    
    ft = polyVal(p=getDriftPars(pd),t=t)
    FT = polyVal(p=[0.0;getDownPars(pd)],t=T)
    c = getMassPars(pd)
    
    bpar = getBlankPars(pd)
    bPt = polyVal(p=parseBPar(bpar,par="bP"),t=t)
    bDt = polyVal(p=parseBPar(bpar,par="bD"),t=t)
    bdt = polyVal(p=parseBPar(bpar,par="bd"),t=t)
    
    A = getA(pd)[standard]
    B = getB(pd)[standard]
    P = getP(Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,c)
    D = getD(Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,c)

    Pp = @. P*ft*FT + bPt
    Dp = @. D*exp(c) + bDt
    dp = @. A*D + B*P + bdt
    
    channels = getChannels(pd)
    DataFrame(hcat(t,T,Pp,dp,Dp),[names(s)[1:2];channels])
end
