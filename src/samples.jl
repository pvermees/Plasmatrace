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

function fitSample(pd::run;i::Integer)
    bpar = getBPar(pd)
    spar = getSPar(pd)
    channels = getChannels(pd)
    if isnothing(bpar) PTerror("missingBlank") end
    if isnothing(spar) PTerror("missingStandard") end
    if isnothing(channels) PTerror("missingControl") end
    samp = getSamples(pd)[i]
    s = signalData(samp,channels=channels)
    mat = atomic(s=s,bpar=bpar,spar=spar)
    colnames = [names(s)[1:2];getIsotopes(pd)]
    DataFrame(mat,colnames)
end

function fitSamples(pd::run;i::Vector{Integer},num=nothing,den=nothing)
    nr = size(i,1)
    v = Vector{Vector}(undef,nr)
    dat = nothing
    for j in eachindex(i)
        df = fitSample(pd,i=i[j])
        dat = getPlotDat(df,num=num,den=den)[:,3:end]
        v[j] = average(dat)
    end
    nc = ncol(dat)
    ncov = Int(nc*(nc-1)/2)
    nms = names(dat)
    labels = Vector{String}(undef,2*nc+ncov)
    labels[1:2:2*nc-1] = nms
    labels[2:2:2*nc] = "s[".*nms.*"]"
    ncov = Int(nc*(nc-1)/2)
    for j in 1:ncov
        r,c = iuppert(j,nc)
        labels[2*nc+j] = "r["*nms[r]*","*nms[c]*"]"
    end
    mat = mapreduce(permutedims,vcat,v)
    DataFrame(mat,labels)
end
export fitSamples

# s is a data frame with the output of signalData(...)
function atomic(;s,bpar,spar)
    t = s[:,1]; T = s[:,2]; Xm = s[:,3]; Ym = s[:,4]; Zm = s[:,5]
    c = parseSPar(spar,par="c")
    ft = polyVal(p=parseSPar(spar,par="f"),t=t)
    FT = polyVal(p=parseSPar(spar,par="F"),t=T)
    bXt = polyVal(p=parseBPar(bpar,par="bx"),t=t)
    bYt = polyVal(p=parseBPar(bpar,par="by"),t=t)
    bZt = polyVal(p=parseBPar(bpar,par="bz"),t=t)
    X = @. (Xm-bXt)/(ft*FT)
    Z = @. (Zm-bZt)*exp(-c)
    Y = Ym-bYt
    hcat(t,T,X,Y,Z)
end
