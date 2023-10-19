function plot(pd::sample;channels::Union{Nothing,Vector{String}},transformation="sqrt",show=true)
    if isnothing(channels) selected = [2;3:ncol(pd)]
    else selected = [2;label2index(pd,channels)] end
    plotdat = getDat(pd)[:,selected]
    p = plotHelper(plotdat,labels=getLabels(pd)[selected],
                   transformation=transformation,show=show)
    dy = Plots.ylims(p)
    plotWindows!(p,pd=pd,blank=true,dy=dy,linecolor="blue")
    plotWindows!(p,pd=pd,blank=false,dy=dy,linecolor="red")
    #plotFitted!(p,pd=pd,channels=channels)
    if show display(p) end
    return p
end

function plot(pd::run;channels::Union{Nothing,Vector{String}}=nothing,
              transformation="sqrt",steps=500,
              i::Union{Nothing,Int}=nothing,show=true)
    if isnothing(i)
        dat = poolRunDat(pd)
        labels = getLabels(pd)[1]
        if isnothing(channels) selected = [1;3:ncol(pd)]
        else selected = [1;label2index(pd,channels)] end
        step = Int(ceil(size(dat,1)/steps))
        plotdat = dat[1:step:end,selected]
        plotHelper(plotdat,labels=labels[selected],
                   transformation=transformation,show=show)
    else
        plot(getSamples(pd)[i],channels=channels,
             transformation=transformation,show=show)
    end
end

function plotHelper(dat::Matrix;labels::Vector{String},
                    transformation="sqrt",show=false)
    x = dat[:,1]
    y = dat[:,2:end]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    p = Plots.plot(x,ty,label=reshape(labels[2:end],1,:),legend=:topleft)
    xlabel!(labels[1])
    ylabel!(transformation*"(signal)")
    if show display(p) end
    return p
end

function plotWindows!(p;pd::sample,blank=false,
                      dy=Plots.ylims(p),linecolor="black")
    windows = blank ? getBWin(pd) : getSWin(pd)
    if isnothing(windows) return end
    dat = getDat(pd)
    for w in windows
        from = dat[w[1],2]
        to = dat[w[2],2]
        Plots.plot!(p,[from,from,to,to,from],collect(dy[[1,2,2,1,1]]),
                    linecolor=linecolor,linestyle=:dot,label="")
    end
end

function plotFitted!(p;pd::sample,channels,dy=Plots.ylims(p))
    fittedchannels = getChannels(pd)
    if isnothing(fittedchannels) return end
    available = findall(in(channels),fittedchannels)
    if (size(available,1)<1) return end
    pred = predict(pd)
end
