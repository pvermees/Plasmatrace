function fitBlanks!(pd::processed;n=2)
    b = blankData(pd)
    bx = polyFit(b[:,1],b[:,3],n=n)
    by = polyFit(b[:,1],b[:,4],n=n)
    bz = polyFit(b[:,1],b[:,5],n=n)
    setBPar!(pd,[bx;by;bz])
end

function blankData(pd::processed;channels=nothing)
    windowData(pd,blank=true,channels=channels)
end
