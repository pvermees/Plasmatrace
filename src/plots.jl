function plot(pd::sample;channels::Union{Nothing,Vector{String}},
              transformation="sqrt")
    if isnothing(channels) channels = getLabels(pd) end
    selected = [2;label2index(pd,channels)]
    plotdat = getDat(pd)[:,selected]
    p = plotHelper(plotdat,labels=getLabels(pd)[selected],
                   transformation=transformation)
    dy = Plots.ylims(p)
    plotWindows!(p,pd=pd,blank=true,dy=dy,linecolor="blue")
    plotWindows!(p,pd=pd,blank=false,dy=dy,linecolor="red")
    return p
end
function plot(pd::run;channels::Union{Nothing,Vector{String}}=nothing,
              transformation="sqrt",steps=1000,
              i::Union{Nothing,Integer}=nothing)
    if isnothing(i)
        dat = poolRunDat(pd)
        labels = getLabels(pd)
        if isnothing(channels) selected = [1;3:ncol(pd)]
        else selected = [1;label2index(pd,channels)] end
        step = Int(ceil(size(dat,1)/steps))
        plotdat = dat[1:step:end,selected]
        p = plotHelper(plotdat,labels=labels[selected],
                       transformation=transformation,seriestype=:path)
    else
        if isnothing(channels) channels = getChannels(pd) end
        p = plot(getSamples(pd)[i],channels=channels,
                 transformation=transformation)
        plotFitted!(p,pd=pd,i=i,channels=channels,transformation=transformation)
    end
    return p
end
export plot

function plotHelper(dat::Matrix;labels::Vector{String},
                    seriestype=:scatter,ms=2,ma=0.5,
                    transformation="sqrt")
    x = dat[:,1]
    y = dat[:,2:end]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    p = Plots.plot(x,ty,seriestype=seriestype,ms=ms,ma=ma,
                   label=reshape(labels[2:end],1,:),legend=:topleft)
    xlab = labels[1]
    ylab = transformation=="" ? "signal" : transformation*"(signal)"
    Plots.xlabel!(xlab)
    Plots.ylabel!(ylab)
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

function plotFitted!(p;pd::run,i::Integer,channels=nothing,
                     transformation="sqrt",linecolor="black",
                     linestyle=:solid,label="")
    fittedchannels = getChannels(pd)
    if isnothing(fittedchannels) return end
    available = findall(in(channels),fittedchannels)
    if (size(available,1)<1) return end
    pred = predictStandard(pd,i=i)
    x = pred[:,2]
    y = pred[:,available .+ 2]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    Plots.plot!(p,x,ty,linecolor=linecolor,linestyle=linestyle,label=label)
end

function plotAtomic(pd::run;i::Integer,
                    num::Union{Nothing,Vector{Integer}}=nothing,
                    den::Union{Nothing,Vector{Integer}}=nothing,
                    scatter=true,transformation="sqrt",ms=4)
    fit = fitSample(pd,i=i)
    channels = getChannels(pd)
    p = plotHelper(fit[:,2:end],labels=[getLabels(pd)[2];channels],
                   transformation=transformation,ms=ms)
    return p
end

function plotCalibration(pd::run)
    groups = groupStandards(pd)
    for g in groups
        s = hcat(g.t,g.T,g.Xm,g.Ym,g.Zm)
        S = atomic(pd=pd,s=s)
        p = Plots.plot(S[:,3]./S[:,5],S[:,4]./S[:,5],seriestype=:scatter)
        display(p)
    end
end
