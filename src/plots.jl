function plot(;pd::sample,channels::Vector{String},transformation::String="sqrt")

    plotRaw(pd=pd,channels=channels,transformation=transformation)

end

function plot(;pd::run,channels::Vector{String},
              transformation::String="sqrt",
              steps::Int64=500,i::Int=nothing)

    if (isnothing(i))
        nr = size(pd.dat,1)
        step = Int64(ceil(nr/steps))
        plotobj = pd
    else
        step = 1
        plotobj = run2sample(pd=pd,i=i)
    end
    plotRaw(pd=plotobj,channels=channels,
            transformation=transformation,step=step)

end

function plotRaw(;pd::plasmaData,channels::Vector{String},
                 transformation::String="sqrt",step::Int64=1)

    tlab = pd.labels[1]
    x = getCols(pd=pd,labels=[tlab])[1:step:end,:]
    y = getCols(pd=pd,labels=channels)[1:step:end,:]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    Plots.plot(x,ty,label=reshape(channels,1,:))
    xlabel!(tlab)
    ylabel!(transformation*" Y")

end
