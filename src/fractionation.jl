function fit(run::Vector{Sample};blank::AbstractDataFrame,
             channels::AbstractDict,anchors::AbstractDict,nft=2,nFT=1,g=nothing)
    dats = Dict()
    for (refmat,anchor) in anchors
        dats[refmat] = pool(run,signal=true,group=refmat)
    end
    init = vcat(fill(0.0,nft),fill(0.0,nFT))
    if isnothing(g) init = vcat(init,0.0) end
    misfit(init,dats,blank,channels,anchors,nft,g)
end
export fit

function misfit(par::AbstractVector,dats::AbstractDict,
                blank::AbstractDataFrame,channels::AbstractDict,
                anchors::AbstractDict,nft::Integer,g=nothing)
    out = 0
    aft = par[1:nft]
    if isnothing(g)
        aFT = par[nft+1:end-1]
        g = par[end]
    end
    for (refmat,dat) in dats
        t = dat[:,1]
        T = dat[:,2]
        d = dat[:,channels["d"]]
        D = dat[:,channels["D"]]
        P = dat[:,channels["P"]]
        bd = blank[:,channels["d"]]
        bD = blank[:,channels["D"]]
        bP = blank[:,channels["P"]]
        bdt = polyVal(p=bd,t=t)
        bDt = polyVal(p=bD,t=t)
        bPt = polyVal(p=bP,t=t)
        ft = polyVal(p=aft,t=t)
        FT = polyVal(p=aFT,t=T)
        (x0,y0) = anchors[refmat]
        out = out + SS(x0,y0,ft,FT,g,bdt,bDt,bPt)
    end
end
