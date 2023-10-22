function fitBlanks!(pd::run;n=2)
    b = blankData(pd)
    bx = polyFit(b[:,1],b[:,3],n=n)
    by = polyFit(b[:,1],b[:,4],n=n)
    bz = polyFit(b[:,1],b[:,5],n=n)
    setBPar!(pd,[bx;by;bz])
end

function parseBPar(bpar,par="bx")
    if isnothing(bpar) PTerror("missingBlank") end
    nbp = Int(size(bpar,1)/3)
    if (par=="bx") return bpar[1:nbp]
    elseif (par=="by") return bpar[nbp+1:2*nbp]
    elseif (par=="bz") return bpar[2*nbp+1:3*nbp]
    else return nothing
    end
end
