function fit_blanks(run::Vector{Sample};n=2)
    blk = pool(run,blank=true)
    channels = getChannels(run)
    channels_count = length(channels)
    bpar = DataFrame(zeros(n,channels_count),channels)
    for channel in channels
        bpar[:,channel] = polynomial_fit(t=blk[:,1],y=blk[:,channel],n=n)
    end
    return bpar
end
export fit_blanks

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
        downhole_fractionation = vcat(0.0,par[nf+1:nf+nF])
        mass_fractionation = isnothing(mf) ? par[end] : log(mf)
        out = 0.0
        for (refmat,data) in dats
            t = data[:,1]
            T = data[:,2]
            Pm = data[:,channels["P"]]
            Dm = data[:,channels["D"]]
            dm = data[:,channels["d"]]
            (x0,y0) = anchors[refmat]
            out += SS(t,T,Pm,Dm,dm,x0,y0,drift,downhole_fractionation,mass_fractionation,bP,bD,bd)
        end
        return out
    end

    init = fill(0.0,nf)
    if (nF>0) init = vcat(init,fill(0.0,nF)) end
    if isnothing(mf) init = vcat(init,0.0) end

    if length(init)>0
        fit = Optim.optimize(misfit,init)
        if verbose println(fit) end
        parameters = Optim.minimizer(fit)
    else
        parameters = 0.0
    end
    drift = parameters[1:nf]
    downhole_fractionation = vcat(0.0,parameters[nf+1:nf+nF])

    mass_fractionation = isnothing(mf) ? parameters[end] : log(mf)

    return Parameters(drift,downhole_fractionation,mass_fractionation)

end
export fractionation

function atomic(sample::Sample;channels::AbstractDict,parameters::Parameters,blank::AbstractDataFrame)
    data = windowData(sample,signal=true)
    t = data[:,1]
    T = data[:,2]
    Pm = data[:,channels["P"]]
    Dm = data[:,channels["D"]]
    dm = data[:,channels["d"]]
    ft = polynomial_factor(p=parameters.drift,t=t)
    FT = polynomial_factor(p=parameters.downhole_fractionation,t=T)
    mf = exp(parameters.mass_fractionation)
    bPt = polynomial_values(p=blank[:,channels["P"]],t=t)
    bDt = polynomial_values(p=blank[:,channels["D"]],t=t)
    bdt = polynomial_values(p=blank[:,channels["d"]],t=t)
    P = @. (Pm-bPt)/(ft*FT)
    D = @. (Dm-bDt)
    d = @. (dm-bdt)/mf
    return t, T, P, D, d
end
export atomic

function averat(sample::Sample;channels::AbstractDict,parameters::Parameters,blank::AbstractDataFrame)
    t, T, P, D, d = atomic(sample,channels=channels,parameters=parameters,blank=blank)
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
function averat(run::Vector{Sample};channels::AbstractDict,parameters::Parameters,blank::AbstractDataFrame)
    ns = length(run)
    out = DataFrame(name=fill("",ns),x=fill(0.0,ns),sx=fill(0.0,ns),
                    y=fill(0.0,ns),sy=fill(0.0,ns),rxy=fill(0.0,ns))
    for i in 1:ns
        out[i,1] = run[i].sample_name
        out[i,2:end] = averat(run[i],channels=channels,parameters=parameters,blank=blank)
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
