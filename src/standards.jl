function fitStandards!(pd::run;method="LuHf",refmat="Hogsbo",
                       snames=nothing,prefix=nothing,
                       i=nothing,n=2)
    if isnothing(getBPar(pd)) PTerror("missingBlank") end
    setDRS!(pd,method=method,refmat=refmat)
    i = findSamples(pd,i=i,prefix=prefix,snames=snames)
    s = signalData(pd,channels=getChannels(pd),i=i)
    
    t = s[:,1]
    T = s[:,2]
    Xm = s[:,3]
    Ym = s[:,4]
    Zm = s[:,5]

    A = getA(pd)
    B = getB(pd)

    bpar = getBPar(pd)
    nbp = Int(size(bpar,1)/3)
    bx = bpar[1:nbp]
    by = bpar[nbp+1:2*nbp]
    bz = bpar[2*nbp+1:3*nbp]

    bXt = polyVal(bx,t)
    bYt = polyVal(by,t)
    bZt = polyVal(bz,t)
    
    function misfit(par)
        ft = polyVal(par[1:n],t)
        FT = polyVal(par[n+1:2*n],T)
        c = par[end]
        X = getX(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
        Z = getZ(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
        sum(getS(X,Z,Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c))
    end

    init = [log(abs(mean(Zm)));fill(0.0,2*n-1);-10.0]
    fit = optimize(misfit,init)
    sol = Optim.minimizer(fit)
    setSPar!(pd,sol)
end

function findSamples(pd::run;snames=nothing,prefix=nothing,i=nothing)
    if isnothing(i)
        allsnames = getSnames(pd)
        if isnothing(prefix)
            if isnothing(snames) # return all samples
                out = 1:length(pd)
            else # snames-based
                if isa(snames,String) snames = [snames] end
                out = findall(in(snames),allsnames)
            end
        else # prefix-based
            if isa(prefix,String) prefix = [prefix] end
            out = Vector{Int}()
            for j in eachindex(allsnames)
                for p in prefix
                    if occursin(p,allsnames[j])
                        push!(out,j)
                    end
                end
            end
        end
    else # i=based
        out = i
    end
    out
end
