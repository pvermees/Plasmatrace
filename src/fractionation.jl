function fractionation(run::Vector{Sample};blank::AbstractDataFrame,
                       channels::AbstractDict,anchors::AbstractDict,
                       nft=2,nFT=1,g=nothing,verbose=false)

    dats = Dict()
    for (refmat,anchor) in anchors
        dats[refmat] = pool(run,signal=true,group=refmat)
    end
    
    function misfit(par)
        out = 0
        aft = par[1:nft]
        if isnothing(g)
            aFT = par[nft+1:end-1]
            gain = exp(par[end])
        else
            aFT = par[nft+1:end]
            gain = exp(g)
        end
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
            ft = polyVal(p=aft,t=t)
            FT = polyVal(p=aFT,t=T)
            (x0,y0) = anchors[refmat]
            out = out + SS(dm,Dm,Pm,x0,y0,ft,FT,gain,bdt,bDt,bPt)
        end
        return out
    end

    fti = vcat(0.0,fill(-10.0,nft-1))
    FTi = vcat(0.0,fill(-10.0,nFT-1))
    init = vcat(fti,FTi)
    if isnothing(g) init = vcat(init,0.0) end
    
    fit = Optim.optimize(misfit,init)
    if verbose println(fit) end
    return Optim.minimizer(fit)
    
end
export fractionation
