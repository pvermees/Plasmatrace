function setWindow!(pd::run;
                    windows::Union{Nothing,Vector{window}}=nothing,
                    i::Union{Nothing,Integer}=nothing,
                    blank=false)
    w = blank ? getBWin(pd) : getSWin(pd)
    if isnothing(windows)
        dat = getDat(pd)[:,3:end]
        total = vec(sum(dat,dims=2))
        if isnothing(i)
            for j in eachindex(getIndex(pd))
                w[j] = autoWindow(pd,total=total,i=j,blank=blank)
            end
        else
            w[i] = autoWindow(pd,total=total,i=i,blank=blank)
        end
    else
        if isnothing(i)
            for j in eachindex(getIndex(pd))
                setWindow!(pd,windows=windows,i=j,blank=blank)
            end
        else
            w[i] = windows
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
        from = floor(Int,min)
        to = floor(Int,(19*max+min)/20)
    else
        min = minimum(sig)
        max = maximum(sig)
        from = ceil(Int,(9*min+max)/10)
        to = ceil(Int,max)
    end
    return [(from,to)]
end

function windowData(pd::processed;blank=false,channels=nothing,i=nothing)
    if isnothing(channels)
        if isnothing(getChannels(pd))
            channels = getLabels(pd)
        else
            channels = getChannels(pd)
        end
    end
    windows = blank ? getBWin(pd) : getSWin(pd)
    if isa(pd,run)
        start = getIndex(pd) .- 1
    else
        start = 0
        windows = [windows]
    end
    selection = Vector{Int}()
    if isnothing(i)
        iterator = windows
    else
        if isa(i,Int) i = [i] end
        iterator = i
    end
    for j in eachindex(iterator)
        if isnothing(windows[j])
            throw(error("Missing selection windows. " *
                        "Run setBlank!(...) or setSignal!(...) first."))
        end
        for w in windows[j]
            first = Int(start[j] + w[1])
            last = Int(start[j] + w[2])
            append!(selection, first:last)
        end
    end
    labels = [getLabels(pd)[1:2];channels] # add time columns
    dat = getCols(pd,labels=labels)
    dat[selection,:]
end
