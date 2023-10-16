function setBlank!(pd::run;
                   blank::Union{Nothing,Vector{window}}=nothing,
                   i::Union{Nothing,Integer}=nothing)
    if isnothing(blank)
        dat = getDat(pd,withtime=false)
        total = vec(sum(dat,dims=2))
        if isnothing(i)
            for j in eachindex(getIndex(pd))
                pd.blanks[j] = autoWindow(pd,total=total,i=j,blank=true)
            end
        else
            pd.blanks[i] = autoWindow(pd,total=total,i=i,blank=true)
        end
    else
        if isnothing(i)
            for j in eachindex(getIndex(pd))
                setBlank!(pd,i=j,blank=blank)
            end
        else
            pd.blanks[i] = blank
        end
    end

    return pd

end

function autoWindow(pd::run;total=nothing,i::Integer,blank=false)::Vector{window}
    ns = length(pd)
    nr = nsweeps(pd)
    index = getIndex(pd)
    from = index[i]
    to = i < ns ? index[i+1]-1 : nr
    q = quantile(total[from:to,:],[0.05,0.95])
    mid = (q[2]+q[1])/10
    low = total[from:to].<mid
    blk = findall(low)
    sig = findall(.!low)
    if blank
        min = minimum(blk)
        max = maximum(blk)
        from = floor(min)
        to = floor((19*max+min)/20)
    else
        min = minimum(sig)
        max = maximum(sig)
        from = ceil((19*min+max)/20)
        to = ceil(max)
    end
    return [window(from,to)]
end
