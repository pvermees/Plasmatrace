function setBlanks!(pd::sample;windows=nothing)
    setWindows!(pd,blank=true,windows=windows)
end
function setBlanks!(pd::run;windows=nothing,i=nothing)
    setWindows!(pd,blank=true,windows=windows,i=i)
end
export setBlanks!

function setSignals!(pd::sample;windows=nothing)
    setWindows!(pd,blank=false,windows=windows)
end
function setSignals!(pd::run;windows=nothing,i=nothing)
    setWindows!(pd,blank=false,windows=windows,i=i)
end
export setSignals!

function setWindows!(pd::sample;blank=false,windows=nothing)
    if isnothing(windows) windows = autoWindow(pd,blank=blank) end
    fun = blank ? setBWin! : setSWin!
    fun(pd,windows)
end
function setWindows!(pd::run;blank=false,windows=nothing,i=nothing)
    if isnothing(i) i = 1:length(pd) end
    samples = getSamples(pd)
    for j in i
        setWindows!(samples[j],blank=blank,windows=windows)
    end
    setSamples!(pd,samples)
end

function autoWindow(pd::sample;blank=false)::Vector{window}
    dat = getDat(pd)[:,3:end]
    total = sum.(eachrow(dat))
    q = Statistics.quantile(total,[0.05,0.95])
    mid = (q[2]+q[1])/10
    low = total.<mid
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

function blankData(pd::sample;channels::Vector{String})
    windowData(pd,blank=true,channels=channels)
end
function blankData(pd::run;channels=nothing,i=nothing)
    windowData(pd,blank=true,channels=channels,i=i)
end

function signalData(pd::sample;channels::Vector{String})
    windowData(pd,blank=false,channels=channels)
end
function signalData(pd::run;channels=nothing,i=nothing)
    windowData(pd,blank=false,channels=channels,i=i)
end

function windowData(pd::sample;blank=false,channels)
    windows = blank ? getBWin(pd) : getSWin(pd)
    selection = Vector{Integer}()
    if isnothing(windows) PTerror("missingWindows") end
    for w in windows
        append!(selection, w[1]:w[2])
    end
    dat = getDat(pd)
    labels = [names(dat)[1:2];channels] # add time columns
    dat[selection,labels]
end

function windowData(pd::run;blank::Bool=false,
                    channels::Union{Nothing,Vector{String}}=nothing,
                    i::Union{Nothing,Int,Vector{Int}}=nothing)
    if isnothing(channels)
        channels = getChannels(pd)
        if isnothing(channels) channels = names(pd) end
    end
    if isnothing(i) i = Vector{Integer}(1:length(pd)) 
    elseif isa(i,Integer) i = [i]
    end
    ni = size(i,1)
    dats = Vector{DataFrame}(undef,ni)
    samples = getSamples(pd)
    for j in eachindex(i)
        dats[j] = windowData(samples[i[j]];blank=blank,channels=channels)
    end
    reduce(vcat,dats)
end
