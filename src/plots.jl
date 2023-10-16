function plot(pd::SAMPLE;channels::Vector{String},transformation="sqrt",show=true)
    plotHelper(pd,channels=channels,transformation=transformation,show=show)
end

function plot(pd::sample;channels::Vector{String},transformation="sqrt",show=true)
    p = plot(pd.data,channels=channels,transformation=transformation)
    if !isnothing(pd.blank)
        dy = ylims(p)
        for w in pd.blank
            from = getVal(pd,r=w.from,c=1)
            to = getVal(pd,r=w.to,c=1)
            Plots.plot!(p,[from,from],[dy[1],dy[2]],linecolor="black",linestyle=:dash,label="")
            Plots.plot!(p,[to,to],[dy[1],dy[2]],linecolor="black",linestyle=:dash,label="")
        end
    end
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
    p = Plots.plot(x,ty,label=reshape(channels,1,:))
    xlabel!(tlab)
    ylabel!(transformation*" Y")
    if show display(p) end
    return p
end