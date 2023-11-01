function plot(pd::sample;channels=nothing,
              num=nothing,den=nothing,
              transformation="sqrt")
    dat = getDat(pd)
    plotdat = getPlotDat(dat,channels=channels,num=num,den=den)
    ylab = isnothing(channels) & !isnothing(den) ? "ratio" : "signal"
    p = plotHelper(plotdat,transformation=transformation,ix=2,ylab=ylab)
    tit = replace(getSname(pd),"\\" => "∖")
    Plots.title!(tit,titlefontsize=10)
    dy = Plots.ylims(p)
    plotWindows!(p,pd=pd,blank=true,dy=dy,linecolor="blue")
    plotWindows!(p,pd=pd,blank=false,dy=dy,linecolor="red")
    return p
end
function plot(pd::run;i::Union{Nothing,Integer}=nothing,
              channels=nothing,num=nothing,den=nothing,
              transformation="sqrt",steps=1000)
    if isnothing(i)
        dat = poolRunDat(pd)
        step = Int(ceil(size(dat,1)/steps))
        plotdat = getPlotDat(dat[1:step:end,:],channels=channels,num=num,den=den)
        ylab = isnothing(channels) & !isnothing(den) ? "ratio" : "signal"
        p = plotHelper(plotdat,transformation=transformation,
                       seriestype=:path,ix=1,ylab=ylab)
    else
        if isnothing(channels) & isnothing(den) channels = getChannels(pd) end
        p = plot(getSamples(pd)[i],channels=channels,
                 num=num,den=den,transformation=transformation)
        if fitable(pd)
            plotFitted!(p,pd=pd,i=i,channels=channels,num=num,den=den,
                        transformation=transformation)
        end
    end
    return p
end
export plot

function plotHelper(plotdat::DataFrame;seriestype=:scatter,
                    ms=2,ma=0.5,transformation="sqrt",ix=1,
                    ylab="signal")
    xy = Matrix(plotdat)
    x = xy[:,ix]
    y = xy[:,3:end]
    plotlabels = names(plotdat)
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    p = Plots.plot(x,ty,seriestype=seriestype,ms=ms,ma=ma,
                   label=permutedims(plotlabels[3:end]),legend=:topleft)
    xlab = plotlabels[ix]
    ylab = transformation=="" ? ylab : transformation*"("*ylab*")"
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
                     num=nothing,den=nothing,transformation="sqrt",
                     linecolor="black",linestyle=:solid)
    pred = predictStandard(pd,i=i)
    plotdat = getPlotDat(pred,channels=channels,num=num,den=den)
    x = pred[:,2]
    y = Matrix(plotdat[:,3:end])
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    Plots.plot!(p,x,ty,linecolor=linecolor,linestyle=linestyle,label="")
end

function plotAtomic(pd::run;i::Integer,num=nothing,den=nothing,
                    scatter=true,transformation="sqrt",ms=4)
    fit = fitSample(pd,i=i)
    plotdat = getPlotDat(fit,num=num,den=den,brackets=false)
    p = plotHelper(plotdat,transformation=transformation,ms=ms,ix=2)
    return p
end
export plotAtomic

function plotCalibration(pd::run,ms=2,ma=0.5,xlim=nothing,ylim=nothing)
    groups = groupStandards(pd)
    ng = size(groups,1)
    plotdat = Vector{DataFrame}(undef,ng)
    xm = Inf; xM = -Inf; ym = Inf; yM = -Inf
    bpar = getBPar(pd)
    spar = getSPar(pd)
    colnames = [names(groups[1].s)[1:2];getIsotopes(pd)]
    for i in 1:ng
        mat = atomic(s=groups[i].s,bpar=bpar,spar=spar)
        df = DataFrame(mat,colnames)
        plotdat[i] = getPlotDat(df,den=[colnames[5]],brackets=false)
        if !isnothing(xlim)
            xm = minimum([xm,minimum(plotdat[i][:,3])])
            xM = maximum([xM,maximum(plotdat[i][:,3])])
        end
        if !isnothing(ylim)
            ym = minimum([ym,minimum(plotdat[i][:,4])])
            yM = maximum([yM,maximum(plotdat[i][:,4])])
        end
    end
    xlim = isnothing(xlim) ? :auto : (xm,xM)
    ylim = isnothing(ylim) ? :auto : (ym,yM)
    axislabels = names(plotdat[1])[3:4]
    p = Plots.plot(0,0,xlimits=xlim,ylimits=ylim,
                   xlab=axislabels[1],ylab=axislabels[2])
    for i in 1:ng
        Plots.scatter!(p,plotdat[i][:,3],plotdat[i][:,4],ms=ms,ma=ma)
    end
    for i in 1:ng
        A = groups[i].A
        B = groups[i].B
        x0 = -A/B
        x = [0.,x0]
        y = A .+ B .* x
        Plots.plot!(p,x,y)
    end
    return p
end
export plotCalibration

function getPlotDat(dat::DataFrame;
                    channels::Union{Nothing,Vector{String}}=nothing,
                    num::Union{Nothing,Vector{String}}=nothing,
                    den::Union{Nothing,Vector{String}}=nothing,
                    brackets=true)
    tT = dat[:,1:2]
    meas = dat[:,3:end]
    if isnothing(channels)
        if !isnothing(den)
            o = brackets ? "(" : ""
            c = brackets ? ")" : ""
            nd = size(den,1)
            if isnothing(num)
                meas = meas[:,Not(den[1])] ./ meas[:,den[1]]
                labels = o.*names(meas).*c.*"/".*o.*den[1].*c
            else
                nn = size(num,1)
                if nn==nd
                    meas = meas[:,num] ./ meas[:,den]
                    labels = o.*num.*c.*"/".*o.*den.*c
                else
                    meas = meas[:,num] ./ meas[:,den[1]]
                    labels = o.*num.*c.*"/".*o.*den[1].*c
                end
            end
            rename!(meas,labels)
        end
    else
        meas = meas[:,channels]
    end
    hcat(tT,meas)
end
