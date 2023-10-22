function findSamples(pd::run;snames=nothing,prefix=nothing,i=nothing)::Vector{Int}
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
        out = size(i,1)>1 ? i : [i]
    end
    out
end
