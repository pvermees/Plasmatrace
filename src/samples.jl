function findSamples(pd::run;snames=nothing,
                     prefix=nothing,i=nothing)::Vector{Integer}
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
            out = Vector{Integer}()
            for j in eachindex(allsnames)
                for p in prefix
                    if occursin(p,allsnames[j])
                        push!(out,j)
                    end
                end
            end
        end
    else # i-based
        out = size(i,1)>1 ? i : [i]
    end
    out
end

function fitSample(pd::run;i=nothing)
    atomic(pd=pd,i=i)
end

function atomic(;pd::Union{Nothing,run}=nothing,s=nothing,i=nothing)
    bpar = getBPar(pd)
    spar = getSPar(pd)
    if isnothing(bpar) PTerror("missingBlank") end
    if isnothing(spar) PTerror("missingStandard") end

    if isnothing(s) s = signalData(pd,i=i) end

    t = s[:,1]
    T = s[:,2]
    Xm = s[:,3]
    Ym = s[:,4]
    Zm = s[:,5]
    
    c = parseSPar(spar,par="c")
    ft = polyVal(p=parseSPar(spar,par="f"),t=t)
    FT = polyVal(p=parseSPar(spar,par="F"),t=T)

    bXt = polyVal(p=parseBPar(bpar,par="bx"),t=t)
    bYt = polyVal(p=parseBPar(bpar,par="by"),t=t)
    bZt = polyVal(p=parseBPar(bpar,par="bz"),t=t)

    X = @. (Xm-bXt)/(ft*FT)
    Z = @. (Zm-bZt)*exp(-c)
    Y = Ym-bYt
    
    DataFrame(t=t,T=T,X=X,Y=Y,Z=Z)
end
