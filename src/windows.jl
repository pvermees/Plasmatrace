function setBlank!(pd::run;
                   windows::Union{Nothing,Vector{window}}=nothing,
                   i::Union{Nothing,Integer}=nothing)
    setWindow!(pd,windows=windows,i=i,blank=true)
end

function setSignal!(pd::run;
                    windows::Union{Nothing,Vector{window}}=nothing,
                    i::Union{Nothing,Integer}=nothing)
    setWindow!(pd,windows=windows,i=i,blank=false)
end

function setWindow!(pd::run;
                    windows::Union{Nothing,Vector{window}}=nothing,
                    i::Union{Nothing,Integer}=nothing,
                    blank=false)
    w = blank ? getBlankWindows(pd) : getSignalWindows(pd)
    if isnothing(windows)
        dat = getDat(pd,withtime=false)
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

function blankData(pd::run;channels=nothing)
    windowData(pd::run,blank=true,channels=channels)
end
function signalData(pd::run;channels=nothing)
    windowData(pd::run,blank=false,channels=channels)
end
function windowData(pd::run;blank=false,channels=nothing)
    windows = blank ? getBlankWindows(pd) : getSignalWindows(pd)
    flattenonce = collect(Iterators.flatten(windows))
    flattentwice = collect(Iterators.flatten(flattenonce))
    numwin = size(flattentwice,1)//2
    from = flattentwice[1:2:end-1]
    to = flattentwice[2:2:end]
    step = to.-from
    nselected = Int(sum(step).+numwin)
    selection = fill(0,nselected)
    last = 0
    for i in eachindex(step)
        first = last + 1
        last = first + step[i]
        selection[first:last] = from[i]:to[i]
    end
    dat = getCols(pd,labels=channels)
    dat[selection,:]

end
