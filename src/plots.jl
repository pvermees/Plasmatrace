"""
Plot selected channels for a sample or a standard

method = either "U-Pb", "Lu-Hf" or "Rb-Sr"
channels = dictionary of the type Dict("P" => "parent", "D" => "daughter", "d" => "sister")
blank = the output of fitBlanks()
pars = the output of fractionation() or process!()
standards = dictionary of the type Dict("prefix" => "mineral standard")
glass = dictionary of the type Dict("prefix" => "reference glass")
num = optional vector of name of the data column to use as the numerator
den = optional name of the data column to use as the denominator
transformation = "sqrt", "log" or nothing
seriestype = :scatter or :path
titlefontsize, ms, xlim, ylim = see the generic Plot.plot function
"""
function plot(samp::Sample,
              method::AbstractString,
              channels::AbstractDict,
              blank::AbstractDataFrame,
              pars::Pars,
              standards::AbstractDict,
              glass::AbstractDict;
              num=nothing,den=nothing,
              transformation=nothing,
              seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,
              linecol="black",linestyle=:solid)
    Sanchors = getAnchors(method,standards,false)
    Ganchors = getAnchors(method,glass,true)
    anchors = merge(Sanchors,Ganchors)
    return plot(samp,channels,blank,pars,anchors;
                num=num,den=den,transformation=transformation,
                seriestype=seriestype,titlefontsize=titlefontsize,
                ms=ms,ma=ma,xlim=xlim,ylim=ylim)
end
"""
Plot selected channels for a sample or a standard
anchors = the output of getAnchors()
"""
function plot(samp::Sample,
              channels::AbstractDict,
              blank::AbstractDataFrame,
              pars::Pars,
              anchors::AbstractDict;
              num=nothing,den=nothing,
              transformation=nothing,
              seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,
              linecol="black",linestyle=:solid)

    if samp.group == "sample"

        p = plot(samp,channels;
                 num=num,den=den,transformation=transformation,
                 seriestype=seriestype,titlefontsize=titlefontsize,
                 ms=ms,ma=ma,xlim=xlim,ylim=ylim,display=display)
        
    else

        offset = getOffset(samp,channels,blank,pars,anchors,transformation;
                           num=num,den=den)

        p = plot(samp,channels;
                 num=num,den=den,transformation=transformation,offset=offset,
                 seriestype=seriestype,titlefontsize=titlefontsize,
                 ms=ms,ma=ma,xlim=xlim,ylim=ylim,display=display)

        plotFitted!(p,samp,pars,blank,channels,anchors;
                     num=num,den=den,transformation=transformation,
                     offset=offset,linecolor=linecol,linestyle=linestyle)
        
    end
    return p
end
"""
Plot selected channels (provided as a dictionary) from a sample
"""
function plot(samp::Sample,
              channels::AbstractDict;
              num=nothing,den=nothing,
              transformation=nothing,offset=nothing,
              seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,display=true)
    return plot(samp,collect(values(channels));
                num=num,den=den,transformation=transformation,
                offset=offset,seriestype=seriestype,titlefontsize=titlefontsize,
                ms=ms,ma=ma,xlim=xlim,ylim=ylim)
end
"""
plot selected channels (provided as a vector) from a sample
channels = a vector of channel names (e.g., the keys of a channels Dict)
"""
function plot(samp::Sample,
              channels::AbstractVector;
              num=nothing,den=nothing,
              transformation=nothing,offset=nothing,
              seriestype=:scatter,titlefontsize=10,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto)
    xlab = names(samp.dat)[1]
    x = samp.dat[:,xlab]
    meas = samp.dat[:,channels]
    y = (isnothing(num) && isnothing(den)) ? meas : formRatios(meas,num,den)
    if isnothing(offset)
        offset = Dict(zip(names(y),fill(0.0,size(y,2))))
    end
    ty = transformeer(y;transformation=transformation,offset=offset)
    ratsig = isnothing(den) ? "signal" : "ratio"
    ylab = isnothing(transformation) ? ratsig : transformation*"("*ratsig*")"
    p = Plots.plot(x,Matrix(ty);
                   ms=ms,ma=ma,seriestype=seriestype,label=permutedims(names(y)),
                   legend=:topleft,xlimits=xlim,ylimits=ylim)
    Plots.xlabel!(xlab)
    Plots.ylabel!(ylab)
    title = samp.sname*" ["*samp.group*"]"
    Plots.title!(title;titlefontsize=titlefontsize)
    dy = Plots.ylims(p)
    # plot t0:
    Plots.plot!(p,[samp.t0,samp.t0],collect(dy[[1,2]]);
                linecolor="grey",linestyle=:dot,label="")
    # plot selection windows:
    for win in [samp.bwin,samp.swin]
        for w in win
            from = x[w[1]]
            to = x[w[2]]
            Plots.plot!(p,[from,from,to,to,from],collect(dy[[1,2,2,1,1]]);
                        linecolor="black",linestyle=:dot,label="")
        end
    end
    return p
end
export plot

"""
Add a model fit to an existing sample plot

p = the output of plot()
samp = a sample
pars = the output of fractionation() or process!()
blank = the output of fitBlanks()
channels = dictionary of the type Dict("P" => "parent", "D" => "daughter", "d" => "sister")
anchors = output of getAnchors()
num, den, transformation, offset, linecolor, linestyle = see ?plot
"""
function plotFitted!(p,samp::Sample,pars::Pars,blank::AbstractDataFrame,
                     channels::AbstractDict,anchors::AbstractDict;
                     num=nothing,den=nothing,transformation=nothing,
                     offset::AbstractDict,linecolor="black",linestyle=:solid)
    x = windowData(samp,signal=true)[:,1]
    pred = predict(samp,pars,blank,channels,anchors)
    rename!(pred,[channels[i] for i in names(pred)])
    y = formRatios(pred,num,den)
    ty = transformeer(y;transformation=transformation,offset=offset)
    for tyi in eachcol(ty)
        Plots.plot!(p,x,tyi;linecolor=linecolor,linestyle=linestyle,label="")
    end
end
