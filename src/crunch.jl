function SS(dm,Dm,Pm,x0,y0,ft,FT,gain,bdt,bDt,bPt)

    D = @. -(((FT*bPt-FT*Pm)*ft*gain^2*x0+(bDt-Dm)*gain^2)*y0^2+(FT^2*bdt-FT^2*dm)*ft^2*gain*x0^2*y0+(FT^2*bDt-Dm*FT^2)*ft^2*x0^2)/((FT^2*ft^2*gain^2*x0^2+gain^2)*y0^2+FT^2*ft^2*x0^2)
    p = @. -(((FT^2*dm-FT^2*bdt)*ft^2*gain*x0^2+(dm-bdt)*gain)*y0+(Dm*FT^2-FT^2*bDt)*ft^2*x0^2+(FT*bPt-FT*Pm)*ft*x0)/(((FT*bPt-FT*Pm)*ft*gain^2*x0+(bDt-Dm)*gain^2)*y0^2+(FT^2*bdt-FT^2*dm)*ft^2*gain*x0^2*y0+(FT^2*bDt-Dm*FT^2)*ft^2*x0^2)
    p[findall(p.<0.0)] .= 0.0
    p[findall(p.>1.0)] .= 1.0
    s = @. ((-D*gain*p*y0)+dm-bdt)^2+((-D*FT*ft*(1-p)*x0)-bPt+Pm)^2+((-bDt)+Dm-D)^2
    
    return sum(s)
end

function predict(pars::Pars,t,T)
    ft = polyVal(p=pars.drift,t=t)
    FT = polyVal(p=pars.down,t=T)
    D*x0*(1-p)*ft*FT + bPt 
    D*y0*p*gain + bdt
    D + bDt
end
