function plot(;pd::sample,channels::Array{String},transformation::String="sqrt")

    plotRaw(pd=pd,channels=channels,transformation=transformation)

end

function plot(;pd::run,channels::Array{String},transformation::String="sqrt",steps::Int64=500)

    nr = size(pd.dat,1)
    step = Int64(round(nr/steps))
    plotRaw(pd=pd,channels=channels,transformation=transformation,step=step)

end

function plotRaw(;pd::plasmaData,channels::Array{String},transformation::String="sqrt",step::Int64=1)

    tlab = pd.labels[1]
    x = getCols(pd=pd,labels=[tlab])[1:step:end,:]
    y = getCols(pd=pd,labels=channels)[1:step:end,:]
    ty = (transformation=="") ? y : eval(Symbol(transformation)).(y)
    Plots.plot(x,ty)
    xlabel!(tlab)
    ylabel!(transformation*" Y")

end