"""
modifies run (adds standards to it)
returns blk, anchors, fit
"""
function process!(run::Vector{Sample},
                  method::AbstractString,
                  channels::AbstractDict,
                  standards::AbstractDict;
                  nb::Integer=2,nf::Integer=1,nF::Integer=1,
                  mf=nothing,PAcutoff=nothing,
                  verbose::Bool=false)
    blk = fitBlanks(run,nb=nb)
    setStandards!(run,standards)
    anchors = getAnchor(method,standards)
    fit = fractionation(run,blank=blk,channels=channels,
                        anchors=anchors,nf=nf,nF=nF,mf=mf,
                        PAcutoff=PAcutoff,verbose=verbose)
    return blk, anchors, fit
end
export process!

function fitBlanks(run::Vector{Sample};nb=2)
    blk = pool(run,blank=true)
    channels = getChannels(run)
    nc = length(channels)
    bpar = DataFrame(zeros(nb,nc),channels)
    for channel in channels
        bpar[:,channel] = polyFit(t=blk.t,y=blk[:,channel],n=nb)
    end
    return bpar
end
export fitBlanks

function fractionation(run::Vector{Sample};
                       blank::AbstractDataFrame,channels::AbstractDict,
                       anchors::AbstractDict,nf::Integer=1,nF::Integer=0,
                       mf=nothing,PAcutoff=nothing,verbose::Bool=false)

    if isnothing(PAcutoff)
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
                t = dat.t
                T = dat.T 
                Pm = dat[:,channels["P"]]
                Dm = dat[:,channels["D"]]
                dm = dat[:,channels["d"]]
                (x0,y0,y1) = anchors[refmat]
                if ismissing(x0)
                    out += SS(t,Dm,dm,y0,mfrac,bD,bd)
                else
                    out += SS(t,T,Pm,Dm,dm,x0,y0,y1,drift,down,mfrac,bP,bD,bd)
                end
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

        out = Pars(drift,down,mfrac)
    else
        out = Array{Pars}(undef,2)
        analog = isAnalog(run,channels=channels,cutoff=PAcutoff)
        out[1] = fractionation(run[analog],
                               blank=blank,channels=channels,
                               anchors=anchors,nf=nf,nF=nF,mf=mf,
                               verbose=verbose)
        
        out[2] = fractionation(run[.!analog],
                               blank=blank,channels=channels,
                               anchors=anchors,nf=nf,nF=nF,mf=mf,
                               verbose=verbose)
    end
    return out
end
export fractionation

function atomic(samp::Sample;
                channels::AbstractDict,pars::Pars,blank::AbstractDataFrame)
    dat = windowData(samp,signal=true)
    t = dat.t
    T = dat.T
    Pm = dat[:,channels["P"]]
    Dm = dat[:,channels["D"]]
    dm = dat[:,channels["d"]]
    ft = polyFac(p=pars.drift,t=t)
    FT = polyFac(p=pars.down,t=T)
    mf = exp(pars.mfrac)
    bPt = polyVal(p=blank[:,channels["P"]],t=t)
    bDt = polyVal(p=blank[:,channels["D"]],t=t)
    bdt = polyVal(p=blank[:,channels["d"]],t=t)
    D = @. (Dm-bDt)
    P = @. (Pm-bPt)/(ft*FT)
    d = @. (dm-bdt)/mf
    return t, T, P, D, d
end
export atomic

function averat(samp::Sample;
                channels::AbstractDict,pars::Pars,blank::AbstractDataFrame)
    t, T, P, D, d = atomic(samp,channels=channels,pars=pars,blank=blank)
    nr = length(t)
    muP = Statistics.mean(P)
    muD = Statistics.mean(D)
    mud = Statistics.mean(d)
    E = Statistics.cov(hcat(P,D,d))
    if mud < 0.0
        mud = 0.0
        E[1,3] = E[3,1] = sum((P.-muP).*d)/(nr-1)
        E[2,3] = E[3,2] = sum((D.-muD).*d)/(nr-1)
        E[3,3] = Statistics.mean(d.^2)
    end
    x = muP/muD
    y = mud/muD
    J = [1/muD -muP/muD^2 0;
         0 -mud/muD^2 1/muD]
    covmat = J * (E/nr) * transpose(J)
    sx = sqrt(covmat[1,1])
    sy = sqrt(covmat[2,2])
    rxy = covmat[1,2]/(sx*sy)
    return [x sx y sy rxy]
end
function averat(run::Vector{Sample};
                channels::AbstractDict,
                pars::Union{Pars,AbstractVector},
                blank::AbstractDataFrame,
                PAcutoff=nothing)
    ns = length(run)
    out = DataFrame(name=fill("",ns),x=fill(0.0,ns),sx=fill(0.0,ns),
                    y=fill(0.0,ns),sy=fill(0.0,ns),rxy=fill(0.0,ns))
    analog = isAnalog(run,channels=channels,cutoff=PAcutoff)
    for i in 1:ns
        out[i,1] = run[i].sname
        if isa(pars,Pars)
            out[i,2:end] = averat(run[i],channels=channels,
                                  pars=pars,blank=blank)
        else
            j = analog ? 1 : 2
            out[i,2:end] = averat(run[i],channels=channels,
                                  pars=pars[j],blank=blank)
        end
    end
    return out
end
export averat

function export2IsoplotR(fname::AbstractString,
                         ratios::AbstractDataFrame,
                         method::AbstractString)
    json = jsonTemplate()

    P, D, d = getPDd(method)

    datastring = "\"ierr\":1,\"data\":{"*
    "\""* P *"/"* D *"\":["*     join(ratios[:,2],",")*"],"*
    "\"err["* P *"/"* D *"]\":["*join(ratios[:,3],",")*"],"*
    "\""* d *"/"* D *"\":["*     join(ratios[:,4],",")*"],"*
    "\"err["* d *"/"* D *"]\":["*join(ratios[:,5],",")*"],"*
    "\"(rho)\":["*join(ratios[:,6],",")*"],"*
    "\"(C)\":[],\"(omit)\":[],"*
    "\"(comment)\":[\""*join(ratios[:,1],"\",\"")*"\"]"

    json = replace(json,"\""*method*"\":{}" =>
                   "\""*method*"\":{"*datastring*"}}")

    
    if method in ["Lu-Hf","Rb-Sr"]
                        
        old = "\"geochronometer\":\"U-Pb\",\"plotdevice\":\"concordia\""
        new = "\"geochronometer\":\""*method*"\",\"plotdevice\":\"isochron\""
        json = replace(json, old => new)
        
        old = "\""*method*"\":{\"format\":1,\"i2i\":true,\"projerr\":false,\"inverse\":false}"
        new = "\""*method*"\":{\"format\":2,\"i2i\":true,\"projerr\":false,\"inverse\":true}"
        json = replace(json, old => new)
        
    end
    
    file = open(fname,"w")
    write(file,json)
    close(file)
    
end
export export2IsoplotR
