function plot(pd::SAMPLE;channels::Vector{String},transformation="sqrt",show=true)
    plotHelper(pd,channels=channels,transformation=transformation,show=show)
end

function plot(pd::sample;channels::Vector{String},transformation="sqrt",show=true)
    p = plot(pd.data,channels=channels,transformation=transformation)
    dy = Plots.ylims(p)
    plotWindows!(p,pd=pd,blank=true,dy=dy,linecolor="blue")
    plotWindows!(p,pd=pd,blank=false,dy=dy,linecolor="red")
    if show display(p) end
    return p
end

function plot(pd::RUN;channels::Vector{String},
              transformation="sqrt",steps=500,i=nothing,show=true)
    if isnothing(i)
        nr = nsweeps(pd)
        step = Int(ceil(nr/steps))
        plotobj = pd
    else
        step = 1
        plotobj = RUN2SAMPLE(pd,i=i)
    end
    plotHelper(plotobj,channels=channels,show=show,
               transformation=transformation,step=step)
end

function plot(pd::run;channels::Vector{String},transformation="sqrt",
              steps=500,i=nothing,show=true)
    if isnothing(i)
        println("plot run")
        p = plot(pd.data,channels=channels,show=show,
                 transformation=transformation,steps=steps)
    else
        samp = run2sample(pd,i=i)
        p = plot(samp,channels=channels,show=show,
                 transformation=transformation)
    end
    return p    
end

function plotHelper(pd::plasmaData;channels::Vector{String},
                    transformation="sqrt",step=1,show=false)
    tlab = getLabels(pd)[1]
    x = getCols(pd,labels=[tlab])[1:step:end,:]
    y = getCols(pd,labels=channels)[1:step:end,:]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    p = Plots.plot(x,ty,label=reshape(channels,1,:),legend=:topleft)
    xlabel!(tlab)
    ylabel!(transformation*"(signal)")
    if show display(p) end
    return p
end

function plotWindows!(p;pd::sample,blank=false,dy=Plots.ylims(p),linecolor="black")
    windows = blank ? getBlank(pd) : getSignal(pd)
    if isnothing(windows) return end
    for w in windows
        from = getVal(pd,r=w[1],c=1)
        to = getVal(pd,r=w[2],c=1)
        Plots.plot!(p,[from,from,to,to,from],collect(dy[[1,2,2,1,1]]),
                    linecolor=linecolor,linestyle=:dot,label="")
    end
end
