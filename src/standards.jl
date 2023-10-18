function fitStandards!(pd::run;method="LuHf",refmat="Hogsbo",
                       snames=nothing,prefix=nothing,
                       i=nothing,n=2)
    if isnothing(getBPar(pd))
        throw(error("No blank model fitted. Run fitBlanks!(...) first."))
    end
    setDRS!(pd,method=method,refmat=refmat)
    i = findSamples(pd,i=i,prefix=prefix,snames=snames)
    s = signalData(pd,i=i)
    s
end

function signalData(pd::processed;channels=nothing,i=nothing)
    windowData(pd,blank=false,channels=channels,i=i)
end

function findSamples(pd::run;snames=nothing,prefix=nothing,i=nothing)
    out = Vector{Int}(undef,0)
    allsnames = getSName(pd)
    if isnothing(snames)
        if isnothing(prefix)
            if isnothing(i)
                out = 1:length(pd)
            else # just return i
                if isa(i,Int) out = [i]
                else out = i
                end
            end
        else # prefix-based
            if isa(prefix,String) prefix = [prefix] end
            for j in eachindex(allsnames)
                for p in prefix
                    if occursin(p,allsnames[j])
                        push!(out,j)
                    end
                end
            end
        end
    else # snames-based
        if isa(snames,String) snames = [snames] end
        out = findall(in(snames),allsnames)
    end
    out
end
