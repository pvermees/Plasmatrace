"""
channels = optional array of names specifying the data columns to plot
num = optional array of names specifying the data columns to use as numerators
den = optional array of names specifying the data columns to use as denominators
transformation = "sqrt", "log" or ""
seriestype = :scatter or :path
titlefontsize, ms, xlim, ylim = see the generic Plot.plot function
cumt = logical value indicating if the x-axis shows cumulative time in hours
"""
function plot(samp::Sample;channels=nothing,num=nothing,den=nothing,
              transformation="sqrt",seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,cumt=false)
    xlab = cumt ? names(samp.dat)[1] : names(samp.dat)[2]
    x = samp.dat[:,xlab]
    meas = isnothing(channels) ? samp.dat[:,3:end] : samp.dat[:,channels]
    y = isnothing(den) ? meas : formRatios(meas,num=num,den=den,
                                           brackets=!isnothing(den))
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    ratsig = !isnothing(den) ? "ratio" : "signal"
    ylab = transformation=="" ? ratsig : transformation*"("*ratsig*")"
    p = Plots.plot(x,Matrix(ty),seriestype=seriestype,
                   ms=ms,ma=ma,label=permutedims(names(y)),
                   legend=:topleft,xlimits=xlim,ylimits=ylim)
    Plots.xlabel!(xlab)
    Plots.ylabel!(ylab)
    # plot selection windows:
    dy = Plots.ylims(p)
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
