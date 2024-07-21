"""
modifies run (adds standards to it)
returns blk, anchors, fit
"""
function process!(run::Vector{Sample},
                  method::AbstractString,
                  channels::AbstractDict,
                  standards::AbstractDict,
                  glass::AbstractDict;
                  nblank::Integer=2,ndrift::Integer=1,ndown::Integer=1,
                  PAcutoff=nothing,verbose::Bool=false)
    blank = fitBlanks(run;nblank=nblank)
    setGroup!(run,standards)
    setGroup!(run,glass)
    fit = fractionation(run,method,blank,channels,standards,glass;
                        ndrift=ndrift,ndown=ndown,
                        PAcutoff=PAcutoff,verbose=verbose)
    return blank, fit
end
export process!

function fitBlanks(run::Vector{Sample};nblank=2)
    blk = pool(run;blank=true)
    channels = getChannels(run)
    nc = length(channels)
    bpar = DataFrame(zeros(nblank,nc),channels)
    for channel in channels
        bpar[:,channel] = polyFit(blk.t,blk[:,channel],nblank)
    end
    return bpar
end
export fitBlanks

# two-step isotope fractionation
function fractionation(run::Vector{Sample},
                       method::AbstractString,
                       blank::AbstractDataFrame,
                       channels::AbstractDict,
                       standards::AbstractVector,
                       glass::AbstractVector;
                       ndrift::Integer=1,
                       ndown::Integer=0,
                       PAcutoff=nothing,
                       verbose::Bool=false)
    if method in ["concentrations","concentration","conc"]
        # TODO
    else
        mf = fractionation(run,method,blank,channels,glass;verbose=verbose)
        out = fractionation(run,method,blank,channels,standards,mf;
                            ndrift=ndrift,ndown=ndown,PAcutoff=PAcutoff,verbose=verbose)
    end
    return out
end
function fractionation(run::Vector{Sample},
                       method::AbstractString,
                       blank::AbstractDataFrame,
                       channels::AbstractDict,
                       standards::AbstractDict,
                       glass::AbstractDict;
                       ndrift::Integer=1,
                       ndown::Integer=0,
                       PAcutoff=nothing,
                       verbose::Bool=false)
    return fractionation(run,method,blank,channels,
                         collect(keys(standards)),
                         collect(keys(glass));
                         ndrift=ndrift,ndown=ndown,
                         PAcutoff=PAcutoff,verbose=verbose)
end
# one-step isotope fractionation using mineral standards
function fractionation(run::Vector{Sample},
                       method::AbstractString,
                       blank::AbstractDataFrame,
                       channels::AbstractDict,
                       standards::AbstractVector,
                       mf::Union{AbstractFloat,Nothing};
                       ndrift::Integer=1,
                       ndown::Integer=0,
                       PAcutoff=nothing,
                       verbose::Bool=false)
    
    anchors = getAnchors(method,standards,false)

    if isnothing(PAcutoff)
        
        if ndrift<1 PTerror("ndriftzero") end

        dats = Dict()
        for (refmat,anchor) in anchors
            dats[refmat] = pool(run;signal=true,group=refmat)
        end

        bD = blank[:,channels["D"]]
        bd = blank[:,channels["d"]]
        bP = blank[:,channels["P"]]

        function misfit(par)
            drift = par[1:ndrift]
            down = vcat(0.0,par[ndrift+1:ndrift+ndown])
            mfrac = isnothing(mf) ? par[end] : log(mf)
            out = 0.0
            for (refmat,dat) in dats
                t = dat.t
                T = dat.T 
                Pm = dat[:,channels["P"]]
                Dm = dat[:,channels["D"]]
                dm = dat[:,channels["d"]]
                (x0,y0,y1) = anchors[refmat]
                out += SS(t,T,Pm,Dm,dm,x0,y0,y1,drift,down,mfrac,bP,bD,bd)
            end
            return out
        end

        init = fill(0.0,ndrift)
        if (ndown>0) init = vcat(init,fill(0.0,ndown)) end
        if isnothing(mf) init = vcat(init,0.0) end
        if length(init)>0
            fit = Optim.optimize(misfit,init)
            if verbose
                println("Drift and downhole fractionation correction:\n")
                println(fit)
            else
                if fit.iteration_converged
                    @warn "Reached the maximum number of iterations before reaching " *
                        "convergence. Reduce the order of the polynomials or fix the " *
                        "mass fractionation and try again."
                end
            end
            pars = Optim.minimizer(fit)
        else
            pars = 0.0
        end
        drift = pars[1:ndrift]
        down = vcat(0.0,pars[ndrift+1:ndrift+ndown])

        mfrac = isnothing(mf) ? pars[end] : log(mf)

        out = Pars(drift,down,mfrac)
    else
        analog = isAnalog(run,channels,PAcutoff)
        out = (analog = fractionation(run[analog],method,blank,channels,standards,mf;
                                      ndrift=ndrift,ndown=ndown,verbose=verbose),
               pulse = fractionation(run[.!analog],method,blank,channels,standards,mf;
                                     ndrift=ndrift,ndown=ndown,verbose=verbose))
    end
    return out
end
function fractionation(run::Vector{Sample},
                       method::AbstractString,
                       blank::AbstractDataFrame,
                       channels::AbstractDict,
                       standards::AbstractDict,
                       mf::Union{AbstractFloat,Nothing};
                       ndrift::Integer=1,
                       ndown::Integer=0,
                       PAcutoff=nothing,
                       verbose::Bool=false)
    return fractionation(run,method,blank,channels,
                         collect(keys(standards)),mf;
                         ndrift=ndrift,ndown=ndown,
                         PAcutoff=PAcutoff,verbose=verbose)
end
# isotopic mass fractionation using glass
function fractionation(run::Vector{Sample},
                       method::AbstractString,
                       blank::AbstractDataFrame,
                       channels::AbstractDict,
                       glass::AbstractVector;
                       verbose::Bool=false)
    
    anchors = getAnchors(method,glass,true)

    dats = Dict()
    for (refmat,anchor) in anchors
        dats[refmat] = pool(run;signal=true,group=refmat)
    end

    bD = blank[:,channels["D"]]
    bd = blank[:,channels["d"]]

    function misfit(par)
        mfrac = par[1]
        out = 0.0
        for (refmat,dat) in dats
            t = dat.t
            Dm = dat[:,channels["D"]]
            dm = dat[:,channels["d"]]
            y0 = anchors[refmat]
            out += SS(t,Dm,dm,y0,mfrac,bD,bd)
        end
        return out
    end

    fit = Optim.optimize(misfit,[0.0])
    if verbose
        println("Mass fractionation correction:\n")
        println(fit)
    end

    mfrac = Optim.minimizer(fit)[1]
    
    return exp(mfrac)
end
function fractionation(run::Vector{Sample},
                       method::AbstractString,
                       blank::AbstractDataFrame,
                       channels::AbstractDict,
                       glass::AbstractDict;
                       verbose::Bool=false)
    return fractionation(run,method,blank,channels,
                         collect(keys(glass));
                         verbose=verbose)
end
export fractionation

function atomic(samp::Sample,
                channels::AbstractDict,
                pars::Pars,
                blank::AbstractDataFrame)
    dat = windowData(samp,signal=true)
    t = dat.t
    T = dat.T
    Pm = dat[:,channels["P"]]
    Dm = dat[:,channels["D"]]
    dm = dat[:,channels["d"]]
    ft = polyFac(pars.drift,t)
    FT = polyFac(pars.down,T)
    mf = exp(pars.mfrac)
    bPt = polyVal(blank[:,channels["P"]],t)
    bDt = polyVal(blank[:,channels["D"]],t)
    bdt = polyVal(blank[:,channels["d"]],t)
    D = @. (Dm-bDt)
    P = @. (Pm-bPt)/(ft*FT)
    d = @. (dm-bdt)/mf
    return t, T, P, D, d
end
export atomic

function averat(samp::Sample,
                channels::AbstractDict,
                pars::Pars,
                blank::AbstractDataFrame)
    t, T, P, D, d = atomic(samp,channels,pars,blank)
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
function averat(run::Vector{Sample},
                channels::AbstractDict,
                pars::Union{Pars,NamedTuple},
                blank::AbstractDataFrame;
                PAcutoff=nothing)
    ns = length(run)
    nul = fill(0.0,ns)
    out = DataFrame(name=fill("",ns),x=nul,sx=nul,y=nul,sy=nul,rxy=nul)
    analog = isAnalog(run,channels,PAcutoff)
    for i in 1:ns
        samp = run[i]
        out[i,1] = samp.sname
        if isa(pars,Pars)
            samp_pars = pars
        elseif analog[i]
            samp_pars = pars.analog
        else
            samp_pars = pars.pulse
        end
        out[i,2:end] = averat(samp,channels,samp_pars,blank)
    end
    return out
end
export averat
