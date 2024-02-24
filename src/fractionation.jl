function fractionation(run::Vector{Sample};blank::AbstractDataFrame,
                       channels::AbstractDict,anchors::AbstractDict,
                       nf=1,nF=1,mf=false,verbose=false)

    dats = Dict()
    for (refmat,anchor) in anchors
        dats[refmat] = pool(run,signal=true,group=refmat)
    end

    bD = blank[:,channels["D"]]
    bd = blank[:,channels["d"]]
    bP = blank[:,channels["P"]]
    
    function misfit(par)
        drift = vcat(0.0,par[1:nf])
        down = vcat(0.0,par[nf+1:nf+nF])
        mfrac = mf ? par[end] : 0.0
        out = 0
        for (refmat,dat) in dats
            t = dat[:,1]
            T = dat[:,2]
            Pm = dat[:,channels["P"]]
            Dm = dat[:,channels["D"]]
            dm = dat[:,channels["d"]]
            (x0,y0) = anchors[refmat]
            out += SS(t,T,Pm,Dm,dm,x0,y0,drift,down,mfrac,bP,bD,bd)
        end
        return out
    end

    init = fill(-10.0,nf+nF)
    if mf init = vcat(init,0.0) end
    
    fit = Optim.optimize(misfit,init)
    if verbose println(fit) end
    
    pars = Optim.minimizer(fit)
    drift = vcat(0.0,pars[1:nf])
    down = vcat(0.0,pars[nf+1:nf+nF])
    mfrac = mf ? pars[end] : 0.0

    return Pars(drift,down,mfrac)
    
end
export fractionation
