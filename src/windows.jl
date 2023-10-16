function setBlank!(pd::run;
                   blank::Union{Nothing,Vector{window}}=nothing,
                   i::Union{Nothing,Integer}=nothing)
    if isnothing(blank)
        if isnothing(i)
            for j in eachindex(pd.data.index)
                setBlank!(pd,i=j)
            end
        else
            ns = length(pd)
            nr = nsweeps(pd)
            index = getIndex(pd)
            from = index[i]
            to = i < ns ? index[i+1]-1 : nr
            total = vec(sum(getData(pd)[from:to,3:end],dims=2))
            q = quantile(total,[0.05,0.95])
            mid = (q[2]+q[1])/10
            low = findall(total.<mid)
            to = floor(maximum(low)*0.95)
            pd.blanks[i] = [window(1,to)]
        end
    else
        if isnothing(i)
            
        else
            pd.blanks[i] = blank
        end
    end

    return pd

end
