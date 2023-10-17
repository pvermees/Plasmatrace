function setWindow!(pd::run;
                    windows::Union{Nothing,Vector{window}}=nothing,
                    i::Union{Nothing,Integer}=nothing,
                    blank=false)
    w = blank ? getBlankWindows(pd) : getSignalWindows(pd)
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

function blankData(pd::processed;channels=nothing)
    windowData(pd,blank=true,channels=channels)
end
function signalData(pd::processed;channels=nothing)
    windowData(pd,blank=false,channels=channels)
end
function windowData(pd::processed;blank=false,channels=nothing)
    if isnothing(channels)
        if isnothing(getChannels(pd))
            channels = getLabels(pd)
        else
            channels = getChannels(pd)
        end
    end
    windows = blank ? getBlankWindows(pd) : getSignalWindows(pd)
    if isa(pd,run)
        start = getIndex(pd) .- 1
        selection = Vector{Int}()
        for i in eachindex(windows)
            for w in windows[i]
                first = Int(start[i] + w[1])
                last = Int(start[i] + w[2])
                append!(selection, first:last)
            end
        end
    else
        start = 1
        selection = 1:nsweeps(pd)
    end
    labels = [getLabels(pd)[1:2];channels] # add time columns
    dat = getCols(pd,labels=labels)
    dat[selection,:]
end
