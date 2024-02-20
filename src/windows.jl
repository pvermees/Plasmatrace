function setBwin!(samp::Sample,bwin=nothing)
    if isnothing(bwin) bwin=autoWindow(samp,blank=true) end
    samp.bwin = bwin
end
export setBwin!

function setSwin!(samp::Sample,swin=nothing)
    if isnothing(swin) swin=autoWindow(samp,blank=false) end
    samp.swin = swin
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
