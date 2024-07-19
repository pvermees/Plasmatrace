"""
channels = optional array of names specifying the data columns to plot
num = optional vector of name of the data column to use as the numerator
den = optional name of the data column to use as the denominator
transformation = "sqrt", "log" or ""
seriestype = :scatter or :path
titlefontsize, ms, xlim, ylim = see the generic Plot.plot function
"""
function plot(samp::Sample,
              channels::AbstractDict,
              blank::AbstractDataFrame,
              pars::Pars,
              anchors::AbstractDict;
              num=nothing,den=nothing,
              transformation="sqrt",
              seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,
              linecol="black",linestyle=:solid)

    if samp.group == "sample"

        p = plot(samp,channels,num=num,den=den,transformation=transformation,
                 seriestype=seriestype,titlefontsize=titlefontsize,
                 ms=ms,ma=ma,xlim=xlim,ylim=ylim,display=display)
        
    else

        offset = getOffset(samp,channels,blank,pars,anchors,
                           num=num,den=den,transformation=transformation)

        p = plot(samp,channels,num=num,den=den,
                 transformation=transformation,offset=offset,
                 seriestype=seriestype,titlefontsize=titlefontsize,
                 ms=ms,ma=ma,xlim=xlim,ylim=ylim,display=display)

        plotFitted!(p,samp,pars,blank,channels,anchors,
                     num=num,den=den,transformation=transformation,
                     offset=offset,linecolor=linecol,linestyle=linestyle)
        
    end
    return p
end
function plot(samp::Sample,
              channels::AbstractDict;
              num=nothing,den=nothing,
              transformation="sqrt",offset=nothing,
              seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,display=true)
    p = plot(samp,collect(values(channels)),num=num,den=den,
             transformation=transformation,offset=offset,seriestype=seriestype,
             titlefontsize=titlefontsize,ms=ms,ma=ma,xlim=xlim,ylim=ylim)
    return p
end
function plot(samp::Sample;
              num=nothing,den=nothing,
              transformation="sqrt",offset=nothing,
              seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto)
    p = plot(samp,getChannels(samp),num=num,den=den,
             transformation=transformation,offset=offset,
             seriestype=seriestype,titlefontsize=titlefontsize,
             ms=ms,ma=ma,xlim=lim,ylim=ylim)
    return p
end
function plot(samp::Sample,
              channels::AbstractVector;
              num=nothing,den=nothing,
              transformation="sqrt",offset=nothing,
              seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto)
    xlab = names(samp.dat)[1]
    x = samp.dat[:,xlab]
    meas = samp.dat[:,channels]
    y = (isnothing(num) && isnothing(den)) ? meas : formRatios(meas,num,den)
    if isnothing(offset)
        offset = Dict(zip(names(y),fill(0.0,size(y,2))))
    end
    ty = transformeer(y,transformation=transformation,offset=offset)
    ratsig = isnothing(den) ? "signal" : "ratio"
    ylab = transformation=="" ? ratsig : transformation*"("*ratsig*")"
    p = Plots.plot(x,Matrix(ty),seriestype=seriestype,
                   ms=ms,ma=ma,label=permutedims(names(y)),
                   legend=:topleft,xlimits=xlim,ylimits=ylim)
    Plots.xlabel!(xlab)
    Plots.ylabel!(ylab)
    title = samp.sname*" ["*samp.group*"]"
    Plots.title!(title,titlefontsize=titlefontsize)
    dy = Plots.ylims(p)
    # plot t0:
    Plots.plot!(p,[samp.t0,samp.t0],collect(dy[[1,2]]),
                linecolor="grey",linestyle=:dot,label="")
    # plot selection windows:
    for win in [samp.bwin,samp.swin]
        for w in win
            from = x[w[1]]
            to = x[w[2]]
            Plots.plot!(p,[from,from,to,to,from],collect(dy[[1,2,2,1,1]]),
                        linecolor="black",linestyle=:dot,label="")
        end
    end
    return p
end
export plot

function plotFitted!(p,samp::Sample,pars::Pars,blank::AbstractDataFrame,
                     channels::AbstractDict,anchors::AbstractDict;
                     num=nothing,den=nothing,transformation="sqrt",
                     offset::AbstractDict,linecolor="black",linestyle=:solid)
    x = windowData(samp,signal=true)[:,1]
    pred = predict(samp,pars,blank,channels,anchors)
    rename!(pred,[channels[i] for i in names(pred)])
    y = formRatios(pred,num,den)
    ty = transformeer(y,transformation=transformation,offset=offset)
    for tyi in eachcol(ty)
        Plots.plot!(p,x,tyi,linecolor=linecolor,linestyle=linestyle,label="")
    end
end
