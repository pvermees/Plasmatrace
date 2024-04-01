function getD(Pm,Dm,dm,x0,y0,ft,FT,mf,bPt,bDt,bdt)
    D = @. -(((FT*bPt-FT*Pm)*ft*mf^2*x0+(bDt-Dm)*mf^2)*y0^2+(FT^2*bdt-FT^2*dm)*ft^2*mf*x0^2*y0+(FT^2*bDt-Dm*FT^2)*ft^2*x0^2)/((FT^2*ft^2*mf^2*x0^2+mf^2)*y0^2+FT^2*ft^2*x0^2)
    return D
end
export getD
function getp(Pm,Dm,dm,x0,y0,ft,FT,mf,bPt,bDt,bdt)
    p = @. -(((FT^2*dm-FT^2*bdt)*ft^2*mf*x0^2+(dm-bdt)*mf)*y0+(Dm*FT^2-FT^2*bDt)*ft^2*x0^2+(FT*bPt-FT*Pm)*ft*x0)/(((FT*bPt-FT*Pm)*ft*mf^2*x0+(bDt-Dm)*mf^2)*y0^2+(FT^2*bdt-FT^2*dm)*ft^2*mf*x0^2*y0+(FT^2*bDt-Dm*FT^2)*ft^2*x0^2)
    return p
end
export getp
function SS(t,T,Pm,Dm,dm,x0,y0,drift,down,mfrac,bP,bD,bd)
    pred = predict(t,T,Pm,Dm,dm,x0,y0,drift,down,mfrac,bP,bD,bd)
    S = @. (pred[:,"P"]-Pm)^2 + (pred[:,"D"]-Dm)^2 + (pred[:,"d"]-dm)^2
    return sum(S)
end

function predict(t,T,Pm,Dm,dm,x0,y0,drift,down,mfrac,bP,bD,bd)
    ft = polyFac(p=drift,t=t)
    FT = polyFac(p=down,t=T)
    mf = exp(mfrac)
    bPt = polyVal(p=bP,t=t)
    bDt = polyVal(p=bD,t=t)
    bdt = polyVal(p=bd,t=t)
    D = getD(Pm,Dm,dm,x0,y0,ft,FT,mf,bPt,bDt,bdt)
    p = getp(Pm,Dm,dm,x0,y0,ft,FT,mf,bPt,bDt,bdt)
    Pf = @. D*x0*(1-p)*ft*FT + bPt
    Df = @. D + bDt
    df = @. D*y0*p*mf + bdt
    return DataFrame(P=Pf,D=Df,d=df)
end
function predict(samp::Sample,
                 pars::Pars,
                 blank::AbstractDataFrame,
                 channels::AbstractDict,
                 anchors::AbstractDict)
    if haskey(anchors,samp.group)
        dat = windowData(samp,signal=true)
        (x0,y0) = anchors[samp.group]
        return predict(dat,pars,blank,channels,x0,y0)
    else
        PTerror("notStandard")
    end
end
function predict(dat::AbstractDataFrame,
                 pars::Pars,
                 blank::AbstractDataFrame,
                 channels::AbstractDict,
                 x0::AbstractFloat,
                 y0::AbstractFloat)
    t = dat.t
    T = dat.T
    Pm = dat[:,channels["P"]]
    Dm = dat[:,channels["D"]]
    dm = dat[:,channels["d"]]
    bP = blank[:,channels["P"]]
    bD = blank[:,channels["D"]]
    bd = blank[:,channels["d"]]
    return predict(t,T,Pm,Dm,dm,x0,y0,
                   pars.drift,pars.down,pars.mfrac,
                   bP,bD,bd)
end
export predict
