function plot(pd::SAMPLE;channels::Vector{String},transformation="sqrt")
    plotHelper(pd,channels=channels,transformation=transformation)
end

function plot(pd::sample;channels::Vector{String},transformation="sqrt")
    plot(pd.data,channels=channels,transformation=transformation)
end

function plot(pd::RUN;channels::Vector{String},
              transformation="sqrt",steps=500,i=0)

    if i>0
        step = 1
        plotobj = RUN2SAMPLE(pd,i=i)
    else
        nr = size(pd.dat,1)
        step = Int(ceil(nr/steps))
        plotobj = pd
    end
    plotHelper(plotobj,channels=channels,
               transformation=transformation,step=step)

end

function plot(pd::run;channels::Vector{String},
              transformation="sqrt",steps=500,i=0)
    plot(pd.data,channels=channels,
         transformation=transformation,
         steps=steps,i=i)
end

function plotHelper(pd::plasmaData;channels::Vector{String},
                    transformation="sqrt",step=1)

    tlab = pd.labels[1]
    x = getCols(pd,labels=[tlab])[1:step:end,:]
    y = getCols(pd,labels=channels)[1:step:end,:]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    Plots.plot(x,ty,label=reshape(channels,1,:))
    xlabel!(tlab)
    ylabel!(transformation*" Y")
    gui()

end
