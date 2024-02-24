function fractionation(run::Vector{Sample};blank::AbstractDataFrame,
                       channels::AbstractDict,anchors::AbstractDict,
                       nf=1,nF=1,mf=false,verbose=false)

    dats = Dict()
    for (refmat,anchor) in anchors
        dats[refmat] = pool(run,signal=true,group=refmat)
    end
    
    function misfit(par)
        af = nf>0 ? vcat(0.0,par[1:nf]) : 0.0
        aF = nF>0 ? vcat(0.0,par[nf+1:nf+nF]) : 0.0
        eg = mf ? exp(par[end]) : 1.0
        out = 0
        for (refmat,dat) in dats
            t = dat[:,1]
            T = dat[:,2]
            dm = dat[:,channels["d"]]
            Dm = dat[:,channels["D"]]
            Pm = dat[:,channels["P"]]
            bd = blank[:,channels["d"]]
            bD = blank[:,channels["D"]]
            bP = blank[:,channels["P"]]
            bdt = polyVal(p=bd,t=t)
            bDt = polyVal(p=bD,t=t)
            bPt = polyVal(p=bP,t=t)
            ft = polyVal(p=af,t=t)
            FT = polyVal(p=aF,t=T)
            (x0,y0) = anchors[refmat]
            out = out + SS(dm,Dm,Pm,x0,y0,ft,FT,eg,bdt,bDt,bPt)
        end
        return out
    end

    init = fill(-10.0,nf+nF)
    if mf init = vcat(init,0.0) end # gain
    
    fit = Optim.optimize(misfit,init)
    if verbose println(fit) end
    
    pars = Optim.minimizer(fit)
    drift = vcat(0.0,pars[1:nf])
    down = vcat(0.0,pars[nf+1:nf+nF])
    mfrac = mf ? pars[end] : 0.0

    return Pars(drift,down,mfrac)
    
end
export fractionation
