function plot(samp::abstractSample;channels=nothing,num=nothing,den=nothing,
              transformation="sqrt",seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,tasx=true)
    xlab = tasx ? names(samp.dat)[1] : names(samp.dat)[2]
    x = samp.dat[:,xlab]
    y = isnothing(channels) ? samp.dat[:,3:end] : samp.dat[:,channels]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    ratsig = !isnothing(den) ? "ratio" : "signal"
    ylab = transformation=="" ? ratsig : transformation*"("*ratsig*")"
    p = Plots.plot(x,Matrix(ty),seriestype=seriestype,ms=ms,ma=ma,
                   label=permutedims(names(y)),
                   legend=:topleft,xlimits=xlim,ylimits=ylim)
    Plots.xlabel!(xlab)
    Plots.ylabel!(ylab)
    return p
end
export plot
