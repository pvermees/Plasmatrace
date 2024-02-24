function atomic(samp::Sample; channels::AbstractDict,pars::Pars,blank::AbstractDataFrame)
    dat = windowData(samp,signal=true)
    t = dat[:,1]
    T = dat[:,2]
    Pm = dat[:,channels["P"]]
    Dm = dat[:,channels["D"]]
    dm = dat[:,channels["d"]]
    ft = polyVal(p=pars.drift,t=t)
    FT = polyVal(p=pars.down,t=T)
    mf = exp(pars.mfrac)
    bPt = polyVal(p=blank[:,channels["P"]],t=t)
    bDt = polyVal(p=blank[:,channels["D"]],t=t)
    bdt = polyVal(p=blank[:,channels["d"]],t=t)
    P = @. (Pm-bPt)/(ft*FT)
    D = @. (Dm-bDt)
    d = @. (dm-bdt)/mf
    return t, T, P, D, d
end

function averat(samp::Sample; channels::AbstractDict,pars::Pars,blank::AbstractDataFrame)
    t, T, P, D, d = atomic(samp,channels=channels,pars=pars,blank=blank)
    nr = length(t)
    sumP = sum(P)
    sumD = sum(D)
    sumd = sum(d)
    E = Statistics.cov(hcat(P,D,d))*nr
    x = sumP/sumD
    y = sumd/sumD
    J = [1/sumD 1/sumD^2 0;
         0 1/sumD^2 1/sumD]
    covmat = J * E * transpose(J)
    sx = sqrt(covmat[1,1])
    sy = sqrt(covmat[2,2])
    rxy = covmat[1,2]/(sx*sy)
    return [x sx y sy rxy]
end
function averat(run::Vector{Sample}; channels::AbstractDict,pars::Pars,blank::AbstractDataFrame)
    ns = length(run)
    out = DataFrame(name=fill("",ns),x=fill(0.0,ns),sx=fill(0.0,ns),
                    y=fill(0.0,ns),sy=fill(0.0,ns),rxy=fill(0.0,ns))
    for i in 1:ns
        out[i,1] = run[i].sname
        out[i,2:end] = averat(run[i],channels=channels,pars=pars,blank=blank)
    end
    return out
end
