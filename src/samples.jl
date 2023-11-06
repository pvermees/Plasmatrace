function findSamples(pd::run;
                     snames::Union{Nothing,AbstractVector{<:AbstractString}}=nothing,
                     prefix::Union{Nothing,AbstractString}=nothing,
                     i::Union{Nothing,Integer,Vector{<:Integer}}=nothing)
    if isnothing(i)
        allsnames = getSnames(pd)
        if isnothing(prefix)
            if isnothing(snames) # return all samples
                out = 1:length(pd)
            else # snames-based
                if isa(snames,AbstractString) snames = [snames] end
                out = findall(in(snames),allsnames)
            end
        else # prefix-based
            if isa(prefix,AbstractString) prefix = [prefix] end
            out = Integer[]
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

function fitable(pd::run;throw=false)
    if isnothing(getBlankPars(pd))
        if throw PTerror("missingBlank ")
        else return false end
    elseif isnothing(getDriftPars(pd))
        if throw PTerror("missingStandard")
        else return false end
    elseif isnothing(getDownPars(pd))
        if throw PTerror("missingStandard")
        else return false end
    elseif isnothing(getMassPars(pd))
        if throw PTerror("missingStandard")
        else return false end
    elseif isnothing(getChannels(pd))
        if throw PTerror("undefinedMethod")
        else return false end
    elseif isnothing(getIsotopes(pd))
        if throw PTerror("undefinedMethod")
        else return false end
    else
        if !throw return true end
    end
end

function fitRawSampleData(pd::run;i::Integer)
    fitable(pd,throw=true)
    channels = getChannels(pd)
    par = getPar(pd)
    samp = getSamples(pd)[i]
    s = signalData(samp,channels=channels)
    mat = atomic(s=s,par=par)
    colnames = [names(s)[1:2];getIsotopes(pd)]
    DataFrame(mat,colnames)
end

function fitSamples(pd::run;i::AbstractVector{<:Integer},
                    num=nothing,den=[getIsotopes(pd)[end]],
                    logratios=false)
    nr = size(i,1)
    v = Vector{DataFrame}(undef,nr)
    for j in eachindex(i)
        dat = fitRawSampleData(pd,i=i[j])
        v[j] = averat(dat[:,3:end],num=num,den=den,logratios=logratios)
    end
    reduce(vcat, v)
end
export fitSamples

# s is a data frame with the output of signalData(...)
function atomic(;s,par)
    t = s[:,1]; T = s[:,2]; Xm = s[:,3]; Ym = s[:,4]; Zm = s[:,5]
    c = getMassPars(par)
    ft = polyVal(p=getDriftPars(par),t=t)
    FT = polyVal(p=getDownPars(par),t=T)
    bpar = getBlankPars(par)
    bXt = polyVal(p=parseBPar(bpar,par="bx"),t=t)
    bYt = polyVal(p=parseBPar(bpar,par="by"),t=t)
    bZt = polyVal(p=parseBPar(bpar,par="bz"),t=t)
    X = @. (Xm-bXt)/(ft*FT)
    Z = @. (Zm-bZt)*exp(-c)
    Y = Ym-bYt
    hcat(t,T,X,Y,Z)
end
