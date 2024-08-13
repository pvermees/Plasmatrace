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
    setGroup!(run,glass)
    setGroup!(run,standards)
    fit = fractionation(run,method,blank,channels,standards,glass;
                        ndrift=ndrift,ndown=ndown,
                        PAcutoff=PAcutoff,verbose=verbose)
    return blank, fit
end
# concentrations:
function process!(run::Vector{Sample},
                  elements::AbstractDataFrame,
                  internal::Tuple,
                  glass::AbstractDict;
                  nblank::Integer=2)
    blank = fitBlanks(run;nblank=nblank)
    setGroup!(run,glass)
    fit = fractionation(run,blank,elements,internal,glass)
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
    mf = fractionation(run,method,blank,channels,glass;verbose=verbose)
    out = fractionation(run,method,blank,channels,standards,mf;
                        ndrift=ndrift,ndown=ndown,PAcutoff=PAcutoff,verbose=verbose)
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
                    @warn "Reached the maximum number of iterations before achieving " *
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

        out = (drift=drift,down=down,mfrac=mfrac)
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
# for concentration measurements:
function fractionation(run::Vector{Sample},
                       blank::AbstractDataFrame,
                       elements::AbstractDataFrame,
                       internal::Tuple,
                       glass::AbstractDict)
    return fractionation(run,blank,elements,internal,
                         collect(keys(glass)))
end
function fractionation(run::Vector{Sample},
                       blank::AbstractDataFrame,
                       elements::AbstractDataFrame,
                       internal::Tuple,
                       glass::AbstractVector)
    ne = size(elements,2)
    num = den = fill(0.0,ne-1)
    for SRM in glass
        dat = pool(run;signal=true,group=SRM)
        concs = elements2concs(elements,SRM)
        bt = polyVal(blank,dat.t)
        sig = getSignals(dat)
        (nr,nc) = size(sig)
        Xm = sig[:,Not(internal[1])]
        Sm = sig[:,internal[1]]
        bXt = bt[:,Not(internal[1])]
        bSt = bt[:,internal[1]]
        S = Sm.-bSt
        R = collect((concs[:,Not(internal[1])]./concs[:,internal[1]])[1,:])
        num += sum.(eachcol(R'.*(Xm.-bXt).*S))
        den += sum.(eachcol((R'.*S).^2))
    end
    return num./den
end
export fractionation

function atomic(samp::Sample,
                channels::AbstractDict,
                pars::NamedTuple,
                blank::AbstractDataFrame)
    dat = windowData(samp,signal=true)
    Pm = dat[:,channels["P"]]
    Dm = dat[:,channels["D"]]
    dm = dat[:,channels["d"]]
    ft = polyFac(pars.drift,dat.t)
    FT = polyFac(pars.down,dat.T)
    mf = exp(pars.mfrac)
    bPt = polyVal(blank[:,channels["P"]],dat.t)
    bDt = polyVal(blank[:,channels["D"]],dat.t)
    bdt = polyVal(blank[:,channels["d"]],dat.t)
    D = @. (Dm-bDt)
    P = @. (Pm-bPt)/(ft*FT)
    d = @. (dm-bdt)/mf
    return P, D, d
end
export atomic

function averat(samp::Sample,
                channels::AbstractDict,
                pars::NamedTuple,
                blank::AbstractDataFrame)
    P, D, d = atomic(samp,channels,pars,blank)
    nr = length(P)
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
                pars::NamedTuple,
                blank::AbstractDataFrame;
                PAcutoff=nothing)
    ns = length(run)
    nul = fill(0.0,ns)
    out = DataFrame(name=fill("",ns),x=nul,sx=nul,y=nul,sy=nul,rxy=nul)
    analog = isAnalog(run,channels,PAcutoff)
    for i in 1:ns
        samp = run[i]
        out[i,1] = samp.sname
        if length(pars)==3
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

function concentrations(samp::Sample,
                        elements::AbstractDataFrame,
                        blank::AbstractDataFrame,
                        pars::AbstractVector,
                        internal::Tuple)
    dat = windowData(samp,signal=true)
    sig = getSignals(dat)
    out = copy(sig)
    bt = polyVal(blank,dat.t)
    bXt = bt[:,Not(internal[1])]
    bSt = bt[:,internal[1]]
    Xm = sig[:,Not(internal[1])]
    Sm = sig[:,internal[1]]
    out[!,internal[1]] .= internal[2]
    num = @. (Xm-bXt)*internal[2]
    den = @. pars'*(Sm-bSt)
    out[!,Not(internal[1])] .= num./den
    elementnames = collect(elements[1,:])
    channelnames = names(sig)
    nms = "ppm[" .* elementnames .* "] from " .* channelnames
    rename!(out,Symbol.(nms))
    return out
end
function concentrations(run::Vector{Sample},
                        elements::AbstractDataFrame,
                        blank::AbstractDataFrame,
                        pars::AbstractVector,
                        internal::Tuple)
    nr = length(run)
    nc = 2*size(elements,2)
    mat = fill(0.0,nr,nc)
    conc = nothing
    for i in eachindex(run)
        samp = run[i]
        conc = concentrations(samp,elements,blank,pars,internal)
        mu = Statistics.mean.(eachcol(conc))
        sigma = Statistics.std.(eachcol(conc))
        mat[i,1:2:nc-1] .= mu
        mat[i,2:2:nc] .= sigma
    end
    nms = fill("",nc)
    nms[1:2:nc-1] .= names(conc)
    nms[2:2:nc] .= "s[" .* names(conc) .* "]"
    out = hcat(DataFrame(sample=getSnames(run)),DataFrame(mat,Symbol.(nms)))
    return out
end
export concentrations
