function plot(pd::sample;channels=nothing,num=nothing,den=nothing,
              transformation="sqrt",prefix="",nstand=1,
              titlefontsize=10,xlim=:auto,ylim=:auto)
    dat = getDat(pd)
    plotdat = getRawPlotDat(dat,channels=channels,num=num,den=den)
    ylab = !isnothing(den) ? "ratio" : "signal"
    p = plotHelper(plotdat,transformation=transformation,ix=2,
                   ylab=ylab,xlim=xlim,ylim=ylim)
    tit = prefix*getSname(pd)
    stand = getStandard(pd)
    if stand>0
        tit *= " [standard"
        if nstand>1 tit *= " "*string(stand) end
        tit *= "]"
    end
    Plots.title!(tit,titlefontsize=titlefontsize)
    dy = Plots.ylims(p)
    plotWindows!(p,pd=pd,blank=true,dy=dy,linecolor="blue")
    plotWindows!(p,pd=pd,blank=false,dy=dy,linecolor="red")
    return p
end
function plot(pd::run;i::Union{Nothing,Integer}=nothing,
              channels=nothing,num=nothing,den=nothing,
              transformation="sqrt",titlefontsize=10,steps=1000,
              xlim=:auto,ylim=:auto)
    if isnothing(i)
        dat = poolRunDat(pd)
        step = Int(ceil(size(dat,1)/steps))
        plotdat = getRawPlotDat(dat[1:step:end,:],channels=channels,num=num,den=den)
        ylab = isnothing(channels) & !isnothing(den) ? "ratio" : "signal"
        p = plotHelper(plotdat,transformation=transformation,
                       seriestype=:path,ix=1,ylab=ylab,xlim=xlim,ylim=ylim)
    else
        if isnothing(channels) & isnothing(den) channels = getChannels(pd) end
        samp = getSamples(pd)[i]
        nstand = size(unique(getStandard(pd)),1)-1
        p = plot(samp,channels=channels,num=num,den=den,
                 transformation=transformation,prefix=string(i)*". ",
                 nstand=nstand,titlefontsize=titlefontsize,xlim=xlim,ylim=ylim)
        if fitable(pd) && getStandard(samp)>0
            plotFitted!(p,pd=pd,i=i,channels=channels,num=num,den=den,
                        transformation=transformation)
        end
    end
    return p
end
export plot

function plotHelper(plotdat::DataFrame;seriestype=:scatter,
                    ms=2,ma=0.5,transformation="sqrt",ix=1,
                    ylab="signal",xlim=:auto,ylim=:auto)
    xy = Matrix(plotdat)
    x = xy[:,ix]
    y = xy[:,3:end]
    plotlabels = names(plotdat)
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    p = Plots.plot(x,ty,seriestype=seriestype,ms=ms,ma=ma,
                   label=permutedims(plotlabels[3:end]),
                   legend=:topleft,xlimits=xlim,ylimits=ylim)
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
    plotdat = getRawPlotDat(pred,channels=channels,num=num,den=den)
    x = pred[:,2]
    y = Matrix(plotdat[:,3:end])
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    Plots.plot!(p,x,ty,linecolor=linecolor,linestyle=linestyle,label="")
end

function plotAtomic(pd::run;i::Integer,num=nothing,den=nothing,
                    scatter=true,transformation="sqrt",ms=4)
    fit = fitRawSampleData(pd,i=i)
    plotdat = getRawPlotDat(fit,num=num,den=den,brackets=false)
    p = plotHelper(plotdat,transformation=transformation,ms=ms,ix=2)
    return p
end
export plotAtomic

function plotCalibration(pd::run;ms=2,ma=0.5,xlim=:auto,ylim=:auto)
    groups = groupStandards(pd)
    ng = size(groups,1)
    plotdat = Vector{DataFrame}(undef,ng)
    xm = Inf; xM = -Inf; ym = Inf; yM = -Inf
    par = getPar(pd)
    colnames = [names(groups[1].s)[1:2];getIsotopes(pd)]
    Dcol = 4
    PDcol = 3
    dDcol = 4
    for i in 1:ng
        mat = atomic(s=groups[i].s,par=par)
        df = DataFrame(mat,colnames)
        plotdat[i] = getRawPlotDat(df,den=[colnames[Dcol]],brackets=false)
        if xlim!=:auto
            xm = minimum([xm,minimum(plotdat[i][:,PDcol])])
            xM = maximum([xM,maximum(plotdat[i][:,PDcol])])
        end
        if ylim!=:auto
            ym = minimum([ym,minimum(plotdat[i][:,dDcol])])
            yM = maximum([yM,maximum(plotdat[i][:,dDcol])])
        end
    end
    xlim = xlim==:auto ? (xm,xM) : xlim
    ylim = ylim==:auto ? (ym,yM) : ylim
    axislabels = names(plotdat[1])[PDcol:dDcol]
    p = Plots.plot(0,0,xlimits=xlim,ylimits=ylim,
                   xlab=axislabels[1],ylab=axislabels[2])
    for i in 1:ng
        Plots.scatter!(p,plotdat[i][:,PDcol],plotdat[i][:,dDcol],ms=ms,ma=ma)
    end
    for i in 1:ng
        A = groups[i].A
        B = groups[i].B
        x0 = -A/B
        x = [0.,x0]
        y = A .+ B .* x
        col = p.series_list[i].plotattributes.explicit[:markercolor]
        Plots.plot!(p,x,y,linecolor=col,label="")
    end
    return p
end
export plotCalibration

function getRawPlotDat(df::DataFrame;
                       channels::Union{Nothing,AbstractVector{T}}=nothing,
                       num::Union{Nothing,AbstractVector{T}}=nothing,
                       den::Union{Nothing,AbstractVector{T}}=nothing,
                       brackets=true) where T<:AbstractString
    tT = df[:,1:2]
    if isnothing(channels)
        meas = df[:,3:end]
    else
        meas = df[:,channels]
    end
    if !isnothing(den)
        meas = formRatios(meas,num=num,den=den,brackets=brackets)
    end
    hcat(tT,meas)
end
