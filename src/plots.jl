function plot(pd::SAMPLE;channels::Vector{String},transformation="sqrt",show=true)
    plotHelper(pd,channels=channels,
               transformation=transformation,show=show)
end

function plot(pd::RUN;channels::Vector{String},
              transformation="sqrt",steps=500,i=nothing,show=true)
    if isnothing(i)
        nr = nsweeps(pd)
        step = Int(ceil(nr/steps))
        plotobj = pd
    else
        step = 1
        plotobj = getSAMPLE(pd,i=i)
    end
    plotHelper(plotobj,xi=1,channels=channels,show=show,
               transformation=transformation,step=step)
end

function plot(pd::sample;channels::Vector{String},transformation="sqrt",show=true)
    p = plot(getRaw(pd),channels=channels,transformation=transformation)
    dy = Plots.ylims(p)
    plotWindows!(p,pd=pd,blank=true,dy=dy,linecolor="blue")
    plotWindows!(p,pd=pd,blank=false,dy=dy,linecolor="red")
    plotFitted!(p,pd=pd,channels=channels,dy=dy)
    if show display(p) end
    return p
end

function plot(pd::run;channels::Vector{String},transformation="sqrt",
              steps=500,i=nothing,show=true)
    if isnothing(i)
        p = plot(getRaw(pd),channels=channels,show=show,
                 transformation=transformation,steps=steps)
    else
        samp = getsample(pd,i=i)
        p = plot(samp,channels=channels,show=show,
                 transformation=transformation)
    end
    return p    
end

function plotHelper(pd::plasmaData;xi=2,channels::Vector{String},
                    transformation="sqrt",step=1,show=false)
    tlab = getLabels(pd)[xi]
    x = getCols(pd,labels=[tlab])[1:step:end,:]
    y = getCols(pd,labels=channels)[1:step:end,:]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    p = Plots.plot(x,ty,label=reshape(channels,1,:),legend=:topleft)
    xlabel!(tlab)
    ylabel!(transformation*"(signal)")
    if show display(p) end
    return p
end

function plotWindows!(p;xi=2,pd::sample,blank=false,
                      dy=Plots.ylims(p),linecolor="black")
    windows = blank ? getBWin(pd) : getSWin(pd)
    if isnothing(windows) return end
    for w in windows
        from = getVal(pd,r=w[1],c=xi)
        to = getVal(pd,r=w[2],c=xi)
        Plots.plot!(p,[from,from,to,to,from],collect(dy[[1,2,2,1,1]]),
                    linecolor=linecolor,linestyle=:dot,label="")
    end
end

function plotFitted!(p;pd::processed,channels,dy=Plots.ylims(p),xi=2)
    fittedchannels = getChannels(pd)
    if isnothing(fittedchannels) return end
    available = findall(in(channels),fittedchannels)
    if (size(available,1)<1) return end
    pred = predict(pd)
end
