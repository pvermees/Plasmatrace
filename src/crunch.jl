function getD(Pm,Dm,dm,x0,y0,ft,FT,mf,bPt,bDt,bdt)
    D = @. -(((FT*bPt-FT*Pm)*ft*mf^2*x0+(bDt-Dm)*mf^2)*y0^2+(FT^2*bdt-FT^2*dm)*ft^2*mf*x0^2*y0+(FT^2*bDt-Dm*FT^2)*ft^2*x0^2)/((FT^2*ft^2*mf^2*x0^2+mf^2)*y0^2+FT^2*ft^2*x0^2)
    return D
end
function getp(Pm,Dm,dm,x0,y0,ft,FT,mf,bPt,bDt,bdt)
    p = @. -(((FT^2*dm-FT^2*bdt)*ft^2*mf*x0^2+(dm-bdt)*mf)*y0+(Dm*FT^2-FT^2*bDt)*ft^2*x0^2+(FT*bPt-FT*Pm)*ft*x0)/(((FT*bPt-FT*Pm)*ft*mf^2*x0+(bDt-Dm)*mf^2)*y0^2+(FT^2*bdt-FT^2*dm)*ft^2*mf*x0^2*y0+(FT^2*bDt-Dm*FT^2)*ft^2*x0^2)
    p[findall(p.<0.0)] .= 0.0
    p[findall(p.>1.0)] .= 1.0
    return p
end
function SS(t,T,Pm,Dm,dm,x0,y0,drift,down,mfrac,bP,bD,bd)
    pred = predict(t,T,Pm,Dm,dm,x0,y0,drift,down,mfrac,bP,bD,bd)
    S = @. (pred[:,"P"]-Pm)^2 + (pred[:,"D"]-Dm)^2 + (pred[:,"d"]-dm)^2
    return sum(S)
end

function predict(t,T,Pm,Dm,dm,x0,y0,drift,down,mfrac,bP,bD,bd)
    ft = polyVal(p=drift,t=t)
    FT = polyVal(p=down,t=T)
    mf = exp(mfrac)
    bPt = polyVal(p=bP,t=t)
    bDt = polyVal(p=bD,t=t)
    bdt = polyVal(p=bd,t=t)
    D = getD(Pm,Dm,dm,x0,y0,ft,FT,mf,bPt,bDt,bdt)
    p = getp(Pm,Dm,dm,x0,y0,ft,FT,mf,bPt,bDt,bdt)
    Pf = @. D*x0*(1-p)*ft*FT + bPt
    Df = @. D + bDt
    df = @. D*y0*p*mf + bdt
    return DataFrame(t=t,T=T,P=Pf,D=Df,d=df)
end
function predict(samp::Sample,pars::Pars,blank::AbstractDataFrame,
                 channels::AbstractDict,anchors::AbstractDict)
    if haskey(anchors,samp.group)
        dat = windowData(samp,signal=true)
        t = dat[:,1]
        T = dat[:,2]
        Pm = dat[:,channels["P"]]
        Dm = dat[:,channels["D"]]
        dm = dat[:,channels["d"]]
        bP = blank[:,channels["P"]]
        bD = blank[:,channels["D"]]
        bd = blank[:,channels["d"]]
        (x0,y0) = anchors[samp.group]
        return predict(t,T,Pm,Dm,dm,x0,y0,pars.drift,pars.down,pars.mfrac,bP,bD,bd)
    else
        PTerror("notStandard")
    end
end
export predict
