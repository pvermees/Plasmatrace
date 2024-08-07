# for age standards
function getD(Pm,Dm,dm,x0,y0,y1,ft,FT,mf,bPt,bDt,bdt)
    D = @. -((bDt-Dm)*mf^2*y1^2+((FT*Pm-FT*bPt)*ft*mf^2*x0+(2*Dm-2*bDt)*mf^2)*y0*y1+((FT*bPt-FT*Pm)*ft*mf^2*x0+(bDt-Dm)*mf^2)*y0^2+(FT^2*bdt-FT^2*dm)*ft^2*mf*x0^2*y0+(FT^2*bDt-Dm*FT^2)*ft^2*x0^2)/(mf^2*y1^2-2*mf^2*y0*y1+(FT^2*ft^2*mf^2*x0^2+mf^2)*y0^2+FT^2*ft^2*x0^2)
    return D
end
# for glass
function getD(Dm,dm,y0,mf,bDt,bdt)
    D = @. ((dm-bdt)*mf*y0-bDt+Dm)/(mf^2*y0^2+1)
    return D
end
export getD
function getp(Pm,Dm,dm,x0,y0,y1,ft,FT,mf,bPt,bDt,bdt)
    p = @. ((bDt-Dm)*mf^2*y1^2+(((FT*Pm-FT*bPt)*ft*mf^2*x0+(Dm-bDt)*mf^2)*y0+(dm-bdt)*mf)*y1+((FT^2*bdt-FT^2*dm)*ft^2*mf*x0^2+(bdt-dm)*mf)*y0+(FT^2*bDt-Dm*FT^2)*ft^2*x0^2+(FT*Pm-FT*bPt)*ft*x0)/((bDt-Dm)*mf^2*y1^2+((FT*Pm-FT*bPt)*ft*mf^2*x0+(2*Dm-2*bDt)*mf^2)*y0*y1+((FT*bPt-FT*Pm)*ft*mf^2*x0+(bDt-Dm)*mf^2)*y0^2+(FT^2*bdt-FT^2*dm)*ft^2*mf*x0^2*y0+(FT^2*bDt-Dm*FT^2)*ft^2*x0^2)
    return p
end
export getp
function getS(Xm,Sm,a,ft,FT,bXt,bSt)
    S = -((FT*a*bXt-FT*Xm*a)*ft+bSt-Sm)/(FT^2*a^2*ft^2+1)
    return S
end
export getS

# isotopic ratios in matrix matched mineral standards
function SS(t,T,Pm,Dm,dm,x0,y0,y1,drift,down,mfrac,bP,bD,bd)
    pred = predict(t,T,Pm,Dm,dm,x0,y0,y1,drift,down,mfrac,bP,bD,bd)
    S = @. (pred[:,"P"]-Pm)^2 + (pred[:,"D"]-Dm)^2 + (pred[:,"d"]-dm)^2
    return sum(S)
end
# isotopic ratios in glass
function SS(t,Dm,dm,y0,mfrac,bD,bd)
    pred = predict(t,Dm,dm,y0,mfrac,bD,bd)
    S = @. (pred[:,"D"]-Dm)^2 + (pred[:,"d"]-dm)^2
    return sum(S)
end
# concentrations
function SS(t,T,Xm,Sm,R,drift,down,bX,bS)
    pred = predict(t,T,Xm,Sm,R,drift,down,bX,bS)
    S = @. (pred[:,"X"]-Xm)^2 + (pred[:,"S"]-Sm)^2
    return sum(S)
end

# isotopic ratios
function predict(t,T,Pm,Dm,dm,x0,y0,y1,drift,down,mfrac,bP,bD,bd)
    ft = polyFac(drift,t)
    FT = polyFac(down,T)
    mf = exp(mfrac)
    bPt = polyVal(bP,t)
    bDt = polyVal(bD,t)
    bdt = polyVal(bd,t)
    D = getD(Pm,Dm,dm,x0,y0,y1,ft,FT,mf,bPt,bDt,bdt)
    p = getp(Pm,Dm,dm,x0,y0,y1,ft,FT,mf,bPt,bDt,bdt)
    Pf = @. D*x0*(1-p)*ft*FT + bPt
    Df = @. D + bDt
    df = @. D*(y1+(y0-y1)*p)*mf + bdt
    return DataFrame(P=Pf,D=Df,d=df)
end
# isotopic ratios for glass
function predict(t,Dm,dm,y0,mfrac,bD,bd)
    mf = exp(mfrac)
    bDt = polyVal(bD,t)
    bdt = polyVal(bd,t)
    D = getD(Dm,dm,y0,mf,bDt,bdt)
    Df = @. D + bDt
    df = @. D*y0*mf + bdt
    return DataFrame(D=Df,d=df)
end
# concentrations
function predict(t,T,Xm,Sm,R,drift,down,bX,bS)
    ft = polyFac(drift,t)
    FT = polyFac(down,T)
    bXt = polyVal(bX,t)
    bSt = polyVal(bS,t)
    S = getS(Xm,Sm,R,ft,FT,bXt,bSt)
    Xf = @. S*R*ft*FT + bXt
    Sf = @. S + bSt
    return DataFrame(X=Xf,S=Sf)
end
function predict(samp::Sample,
                 method::AbstractString,
                 pars::Pars,
                 blank::AbstractDataFrame,
                 channels::AbstractDict,
                 standards::AbstractDict,
                 glass::AbstractDict)
    anchors = getAnchors(method,standards,glass)
    return predict(samp,pars,blank,channels,anchors)
end
function predict(samp::Sample,
                 pars::Pars,
                 blank::AbstractDataFrame,
                 channels::AbstractDict,
                 anchors::AbstractDict)
    if samp.group == "sample"
        PTerror("notStandard")
    else
        dat = windowData(samp;signal=true)
        anchor = anchors[samp.group]
        return predict(dat,pars,blank,channels,anchor)
    end
end
# minerals
function predict(dat::AbstractDataFrame,
                 pars::Pars,
                 blank::AbstractDataFrame,
                 channels::AbstractDict,
                 anchor::NamedTuple)
    t = dat.t
    T = dat.T
    Pm = dat[:,channels["P"]]
    Dm = dat[:,channels["D"]]
    dm = dat[:,channels["d"]]
    bP = blank[:,channels["P"]]
    bD = blank[:,channels["D"]]
    bd = blank[:,channels["d"]]
    return predict(t,T,Pm,Dm,dm,
                   anchor.x0,anchor.y0,anchor.y1,
                   pars.drift,pars.down,pars.mfrac,
                   bP,bD,bd)    
end
# glass
function predict(dat::AbstractDataFrame,
                 pars::Pars,
                 blank::AbstractDataFrame,
                 channels::AbstractDict,
                 y0::AbstractFloat)
    t = dat.t
    Dm = dat[:,channels["D"]]
    dm = dat[:,channels["d"]]
    bD = blank[:,channels["D"]]
    bd = blank[:,channels["d"]]
    return predict(t,Dm,dm,y0,pars.mfrac,bD,bd)
end
export predict
