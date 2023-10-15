function plot(pd::SAMPLE;channels::Vector{String},transformation::String="sqrt")
    plotHelper(pd,channels=channels,transformation=transformation)
end

function plot(pd::sample;channels::Vector{String},transformation::String="sqrt")
    plot(pd.data,channels=channels,transformation=transformation)
end

function plot(pd::RUN;channels::Vector{String},
              transformation::String="sqrt",
              steps::Int64=500,i::Int=0)

    if (i>0)
        step = 1
        plotobj = RUN2SAMPLE(pd=pd,i=i)
    else
        nr = size(pd.dat,1)
        step = Int64(ceil(nr/steps))
        plotobj = pd
    end
    plotHelper(plotobj,channels=channels,
               transformation=transformation,step=step)

end

function plot(pd::run;channels::Vector{String},
              transformation::String="sqrt",
              steps::Int64=500,i::Int=0)
    plot(pd.data,channels=channels,
         transformation=transformation,
         steps=steps,i=i)
end

function plotHelper(pd::plasmaData;channels::Vector{String},
                    transformation::String="sqrt",step::Int64=1)

    tlab = pd.labels[1]
    x = getCols(pd=pd,labels=[tlab])[1:step:end,:]
    y = getCols(pd=pd,labels=channels)[1:step:end,:]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    Plots.plot(x,ty,label=reshape(channels,1,:))
    xlabel!(tlab)
    ylabel!(transformation*" Y")

end
