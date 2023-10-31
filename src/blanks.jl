function fitBlanks!(pd::run;n=2)
    ctrl = getControl(pd)
    if isnothing(ctrl) PTerror("missingControl") end
    channels = getChannels(ctrl)
    b = blankData(pd,channels=channels)
    nc = size(channels,1)
    bpar = fill(0.0,n*nc)
    for i in eachindex(channels)
        bpar[(i-1)*n+1:i*n] = polyFit(t=b[:,1],y=b[:,i+2],n=n)
    end
    setBPar!(pd,bpar=bpar)
end
export fitBlanks!

function parseBPar(bpar;par="bx")
    if isnothing(bpar) PTerror("missingBlank") end
    nbp = Int(size(bpar,1)/3)
    if (par=="bx") return bpar[1:nbp]
    elseif (par=="by") return bpar[nbp+1:2*nbp]
    elseif (par=="bz") return bpar[2*nbp+1:3*nbp]
    else return nothing
    end
end
