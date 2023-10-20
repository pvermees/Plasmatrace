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
        out = size(i,1)>1 ? [i] : i
    end
    out
end

function predictSamples(pd::run,snames=nothing,
                        prefix=nothing,i=nothing)
    i = findSamples(pd,i=i,prefix=prefix,snames=snames)
    s = signalData(pd,i=i)
    
    bpar = getBPar(pd)
    spar = getSPar(pd)
    if isnothing(bpar) PTerror("missingBlank") end
    if isnothing(spar) PTerror("missingStandard") end
    np = size(par,1)
    n = Int((np-1)/5)
    c = par[end]
    f = par[1:n]
    F = par[n+1:2*n]
    bx = par[2*n+1:3*n]
    by = par[3*n+1:4*n]
    bz = par[4*n+1:5*n]
    dat = signalData(pd)
    t = dat[:,1]
    T = dat[:,2]
    Xm = dat[:,1]
    Ym = dat[:,2]
    Zm = dat[:,3]
    ft = polyVal(f,t)
    FT = polyVal(F,T)
    bXt = polyVal(bx,t)
    bYt = polyVal(by,t)
    bZt = polyVal(bz,t)
    # X = getX(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    # Z = getZ(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    # TODO: Y = (A*X + B*Z)*exp(c)
end
