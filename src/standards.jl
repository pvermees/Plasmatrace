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
    changeGain = getGainOption(pd)==2
    
    function misfit(par)
        out = 0
        aft = par[1:n]
        aFT = [0.0;par[n+1:n+m]]
        if changeGain
            g = par[end]
        else
            g = getGainPar(pd)
        end
        for gr in groups
            t = gr.s[:,1]
            T = gr.s[:,2]
            Pm = gr.s[:,3]
            Dm = gr.s[:,4]
            dm = gr.s[:,5]
            ft = polyVal(p=aft,t=t)
            FT = polyVal(p=aFT,t=T)
            P = getP(Pm,Dm,dm,gr.A,gr.B,ft,FT,gr.bPt,gr.bDt,gr.bdt,g)
            D = getD(Pm,Dm,dm,gr.A,gr.B,ft,FT,gr.bPt,gr.bDt,gr.bdt,g)
            out += sum(getS(P,D,Pm,Dm,dm,gr.A,gr.B,ft,FT,gr.bPt,gr.bDt,gr.bdt,g))
        end
        out
    end

    init = changeGain ? fill(0.0,n+m+1) : fill(0.0,n+m)
    fit = Optim.optimize(misfit,init)
    if verbose println(fit) end
    sol = Optim.minimizer(fit)
    setDriftPars!(pd,sol[1:n])
    setDownPars!(pd,sol[n+1:n+m])
    if changeGain setGainPar!(pd,sol[end]) end
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
    Dm = s[:,4]
    dm = s[:,5]
    
    ft = polyVal(p=getDriftPars(pd),t=t)
    FT = polyVal(p=[0.0;getDownPars(pd)],t=T)
    g = getGainPar(pd)
    
    bpar = getBlankPars(pd)
    bPt = polyVal(p=parseBPar(bpar,par="bP"),t=t)
    bDt = polyVal(p=parseBPar(bpar,par="bD"),t=t)
    bdt = polyVal(p=parseBPar(bpar,par="bd"),t=t)
    
    A = getA(pd)[standard]
    B = getB(pd)[standard]
    P = getP(Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,g)
    D = getD(Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,g)

    Pp = @. P*ft*FT + bPt
    Dp = @. D*exp(g) + bDt
    dp = @. A*D + B*P + bdt
    
    channels = getChannels(pd)
    DataFrame(hcat(t,T,Pp,Dp,dp),[names(s)[1:2];channels])
end
