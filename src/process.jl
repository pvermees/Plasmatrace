function fitBlanks(run::Vector{Sample};n=2)
    blk = pool(run,blank=true)
    channels = getChannels(run)
    nc = length(channels)
    bpar = DataFrame(zeros(n,nc),channels)
    for channel in channels
        bpar[:,channel] = polyFit(t=blk[:,1],y=blk[:,channel],n=n)
    end
    return bpar
end
export fitBlanks

function fractionation(run::Vector{Sample};blank::AbstractDataFrame,
                       channels::AbstractDict,anchors::AbstractDict,
                       nf=1,nF=0,mf=nothing,verbose=false)

    if nf<1 PTerror("nfzero") end

    dats = Dict()
    for (refmat,anchor) in anchors
        dats[refmat] = pool(run,signal=true,group=refmat)
    end
    
    bD = blank[:,channels["D"]]
    bd = blank[:,channels["d"]]
    bP = blank[:,channels["P"]]
    
    function misfit(par)
        drift = par[1:nf]
        down = vcat(0.0,par[nf+1:nf+nF])
        mfrac = isnothing(mf) ? par[end] : log(mf)
        out = 0.0
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

    init = fill(0.0,nf)
    if (nF>0) init = vcat(init,fill(0.0,nF)) end
    if isnothing(mf) init = vcat(init,0.0) end

    if length(init)>0
        fit = Optim.optimize(misfit,init)
        if verbose println(fit) end
        pars = Optim.minimizer(fit)
    else
        pars = 0.0
    end
    drift = pars[1:nf]
    down = vcat(0.0,pars[nf+1:nf+nF])
    
    mfrac = isnothing(mf) ? pars[end] : log(mf)

    return Pars(drift,down,mfrac)
    
end
export fractionation

function atomic(samp::Sample;channels::AbstractDict,pars::Pars,blank::AbstractDataFrame)
    dat = windowData(samp,signal=true)
    t = dat[:,1]
    T = dat[:,2]
    Pm = dat[:,channels["P"]]
    Dm = dat[:,channels["D"]]
    dm = dat[:,channels["d"]]
    ft = polyFac(p=pars.drift,t=t)
    FT = polyFac(p=pars.down,t=T)
    mf = exp(pars.mfrac)
    bPt = polyVal(p=blank[:,channels["P"]],t=t)
    bDt = polyVal(p=blank[:,channels["D"]],t=t)
    bdt = polyVal(p=blank[:,channels["d"]],t=t)
    P = @. (Pm-bPt)/(ft*FT)
    D = @. (Dm-bDt)
    d = @. (dm-bdt)/mf
    return t, T, P, D, d
end
export atomic

function averat(samp::Sample;channels::AbstractDict,pars::Pars,blank::AbstractDataFrame)
    t, T, P, D, d = atomic(samp,channels=channels,pars=pars,blank=blank)
    nr = length(t)
    sumP = sum(P)
    sumD = sum(D)
    sumd = sum(d)
    E = Statistics.cov(hcat(P,D,d))*nr
    x = sumP/sumD
    y = sumd/sumD
    J = [1/sumD -sumP/sumD^2 0;
         0 -sumd/sumD^2 1/sumD]
    covmat = J * E * transpose(J)
    sx = sqrt(covmat[1,1])
    sy = sqrt(covmat[2,2])
    rxy = covmat[1,2]/(sx*sy)
    return [x sx y sy rxy]
end
function averat(run::Vector{Sample};channels::AbstractDict,pars::Pars,blank::AbstractDataFrame)
    ns = length(run)
    out = DataFrame(name=fill("",ns),x=fill(0.0,ns),sx=fill(0.0,ns),
                    y=fill(0.0,ns),sy=fill(0.0,ns),rxy=fill(0.0,ns))
    for i in 1:ns
        out[i,1] = run[i].sname
        out[i,2:end] = averat(run[i],channels=channels,pars=pars,blank=blank)
    end
    return out
end
export averat

function export2IsoplotR(fname::AbstractString,ratios::AbstractDataFrame,method::AbstractString)
    json = jsonTemplate()
    if method=="LuHf"
        datastring = "\"ierr\":1,\"data\":{"*
        "\"Lu176/Hf176\":["     *join(ratios[:,2],",")*"],"*
        "\"err[Lu176/Hf176]\":["*join(ratios[:,3],",")*"],"*
        "\"Hf177/Hf176\":["     *join(ratios[:,4],",")*"],"*
        "\"err[Hf177/Hf176]\":["*join(ratios[:,5],",")*"],"*
        "\"(rho)\":["*join(ratios[:,6],",")*"],"*
        "\"(C)\":[],\"(omit)\":[],"*
        "\"(comment)\":[\""*join(ratios[:,1],"\",\"")*"\"]"
        json = replace(json,
                       "\"geochronometer\":\"U-Pb\",\"plotdevice\":\"concordia\"" =>
                       "\"geochronometer\":\"Lu-Hf\",\"plotdevice\":\"isochron\"")
        json = replace(json,"\"Lu-Hf\":{}" => "\"Lu-Hf\":{"*datastring*"}}")
        json = replace(json,
                       "\"Lu-Hf\":{\"format\":1,\"i2i\":true,\"projerr\":false,\"inverse\":false}" =>
                       "\"Lu-Hf\":{\"format\":2,\"i2i\":true,\"projerr\":false,\"inverse\":true}")
    end
    file = open(fname,"w")
    write(file,json)
    close(file)
end
export export2IsoplotR
