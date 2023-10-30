function plot(pd::sample;channels=nothing,transformation="sqrt")
    plotdat = getDat(pd)
    p = plotHelper(plotdat,channels=channels,
                   transformation=transformation,ix=2)
    dy = Plots.ylims(p)
    plotWindows!(p,pd=pd,blank=true,dy=dy,linecolor="blue")
    plotWindows!(p,pd=pd,blank=false,dy=dy,linecolor="red")
    return p
end
function plot(pd::run;channels=nothing,
              transformation="sqrt",steps=1000,
              i::Union{Nothing,Integer}=nothing)
    if isnothing(i)
        plotdat = poolRunDat(pd)
        step = Int(ceil(size(plotdat,1)/steps))
        p = plotHelper(plotdat[1:step:end,:],
                       channels=channels,
                       transformation=transformation,
                       seriestype=:path,ix=1)
    else
        if isnothing(channels) channels = getChannels(pd) end
        p = plot(getSamples(pd)[i],channels=channels,
                 transformation=transformation)
        plotFitted!(p,pd=pd,i=i,channels=channels,
                    transformation=transformation)
    end
    return p
end
export plot

function plotHelper(plotdat::DataFrame;
                    channels::Union{Nothing,Vector{String},Vector{Integer}}=nothing,
                    seriestype=:scatter,ms=2,ma=0.5,transformation="sqrt",ix=1)
    labels = names(plotdat)
    if isnothing(channels)
        i = 3:ncol(plotdat)
    elseif isa(channels,Vector{String})
        i = findall(in(channels),labels)
    end
    xy = Matrix(plotdat)
    x = xy[:,ix]
    y = xy[:,i]
    plotlabels = labels[i]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    p = Plots.plot(x,ty,seriestype=seriestype,ms=ms,ma=ma,
                   label=permutedims(plotlabels),legend=:topleft)
    xlab = names(plotdat)[1]
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
    p = plotHelper(fit,transformation=transformation,ms=ms,ix=2)
    return p
end
export plotAtomic

function plotCalibration(pd::run,ms=1,ma=0.5)
    groups = groupStandards(pd)
    for g in groups
        s = hcat(g.t,g.T,g.Xm,g.Ym,g.Zm)
        S = atomic(pd=pd,s=s)
        p = Plots.plot(S[:,3]./S[:,5],S[:,4]./S[:,5],
                       seriestype=:scatter,ms=ms,ma=ma)
        display(p)
    end
end
export plotCalibration
