"""
channels = optional array of names specifying the data columns to plot
numerator = optional vector of name of the data column to use as the numerator
denominator = optional name of the data column to use as the denominator
transformation = "sqrt", "log" or ""
seriestype = :scatter or :path
titlefontsize, ms, xlim, ylim = see the generic Plot.plot function
cumt = logical value indicating if the x-axis shows cumulative time in hours
"""
function plot(sample::Sample,channels::Vector{String};
              numerator=nothing,denominator=nothing,transformation="sqrt",seriestype=:scatter,
              titlefontsize=10,ms=2,ma=0.5,xlim=:auto,ylim=:auto,cumt=false)
    xlab = cumt ? names(sample.data)[1] : names(sample.data)[2]
    x = sample.data[:,xlab]
    meas = sample.data[:,channels]
    y = (isnothing(numerator) && isnothing(denominator)) ? meas : form_ratios(meas,numerator,denominator)
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    ratsig = denominator=="" ? "signal" : "ratio"
    ylab = transformation=="" ? ratsig : transformation*"("*ratsig*")"
    p = Plots.plot(x,Matrix(ty),seriestype=seriestype,
                   ms=ms,ma=ma,label=permutedims(names(y)),
                   legend=:topleft,xlimits=xlim,ylimits=ylim)
    Plots.xlabel!(xlab)
    Plots.ylabel!(ylab)
    title = sample.sample_name*" ["*sample.group*"]"
    Plots.title!(title,titlefontsize=titlefontsize)
    # plot selection windows:
    dy = Plots.ylims(p)
    for win in [sample.blank_window,sample.signal_window]
        for w in win
            from = x[w[1]]
            to = x[w[2]]
            Plots.plot!(p,[from,from,to,to,from],collect(dy[[1,2,2,1,1]]),
                        linecolor="black",linestyle=:dot,label="")
        end
    end
    return p
end
function plot(sample::Sample;numerator=nothing,denominator=nothing,transformation="sqrt",seriestype=:scatter,
              titlefontsize=10,ms=2,ma=0.5,xlim=:auto,ylim=:auto,cumt=false)
    plot(sample,getChannels(sample),numerator=numerator,denominator=denominator,
         transformation=transformation,seriestype=seriestype,
         titlefontsize=titlefontsize,ms=ms,ma=ma,
         xlim=lim,ylim=ylim,cumt=cumt)
end
function plot(sample::Sample,channels::AbstractDict;numerator=nothing,denominator=nothing,
              transformation="sqrt",seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,cumt=false,display=true)
    D = isnothing(denominator) ? nothing : channels[denominator]
    plot(sample,collect(values(channels)),numerator=numerator,denominator=D,
         transformation=transformation,seriestype=seriestype,
         titlefontsize=titlefontsize,ms=ms,ma=ma,
         xlim=xlim,ylim=ylim,cumt=cumt)
end
export plot

function plotFitted!(p,sample::Sample,parameters::Parameters,blank::AbstractDataFrame,
                     channels::AbstractDict,anchors::AbstractDict;
                     numerator=nothing,denominator=nothing,transformation="sqrt",cumt=false,
                     linecolor="black",linestyle=:solid)
    pred = predict(sample,parameters,blank,channels,anchors)
    plotdat = form_ratios(pred[:,3:end],numerator,denominator)
    x = pred[:,"T"]
    for y in eachcol(plotdat)
        if transformation==""
            ty = y
        else
            ty = fill(NaN,length(y))
            pos = (y.>0.0)
            ty[pos] = eval(Symbol(transformation)).(y[pos])
        end
        Plots.plot!(p,x,ty,linecolor=linecolor,linestyle=linestyle,label="")
    end
end
export plotFitted!
