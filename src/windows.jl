function setBwin!(samp::Sample,bwin=nothing)
    if isnothing(bwin) bwin=autoWindow(samp,blank=true) end
    samp.bwin = bwin
end
function setBwin!(run::plasmaData,bwin=nothing;i=nothing)
    if isnothing(i) i = 1:length(run.samples) end
    if isnothing(bwin) bwin=autoWindow(samp,blank=true) end
    for j in i
        setBwin!(run.samples[j],bwin)
    end
end
export setBwin!

function setSwin!(samp::Sample,swin=nothing)
    if isnothing(swin) swin=autoWindow(samp,blank=false) end
    samp.swin = swin
end
function setSwin!(run::plasmaData,swin=nothing;i=nothing)
    if isnothing(i) i = 1:length(run.samples) end
    if isnothing(swin) swin=autoWindow(samp,blank=false) end
    for j in i
        setSwin!(run.samples[j],swin)
    end
end
export setSwin!

function autoWindow(signals::AbstractDataFrame;blank=false)
    total = sum.(eachrow(signals))
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
function autoWindow(samp::Sample;blank=false)
    autoWindow(samp.dat[:,3:end],blank=blank)
end
