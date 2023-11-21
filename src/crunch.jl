function getp(x0,y0,ft,FT,g,bPt,bDt,bdt,Pm,Dm,dm)
    @. (((2*FT^2*dm-FT^2*bdt+FT^2*bPt+Dm*FT^2)*ft^2*exp(g)*x0^2+(2*FT*dm-2*FT*bdt+FT*bPt+FT*bDt-FT*Pm-Dm*FT)*ft*exp(g)*x0+(2*dm-bdt+bDt+Pm)*exp(g))*y0+(FT^2*dm+FT^2*bPt-FT^2*bDt+2*Dm*FT^2)*ft^2*x0^2+((-FT*dm)+FT*bPt-FT*bDt-2*FT*Pm)*ft*x0)/(((FT*bdt-FT*bPt+2*FT*Pm+Dm*FT)*ft*exp(2*g)*x0+(bdt-bDt+Pm+2*Dm)*exp(2*g))*y0^2+((2*FT^2*dm-FT^2*bdt+FT^2*bPt+Dm*FT^2)*ft^2*exp(g)*x0^2+(FT*dm-FT*bdt-FT*bPt+2*FT*bDt+FT*Pm-2*Dm*FT)*ft*exp(g)*x0)*y0+(FT^2*dm+FT^2*bPt-FT^2*bDt+2*Dm*FT^2)*ft^2*x0^2)
end

function getS(p,x0,y0,ft,FT,g,bPt,bDt,bdt,Pm,Dm,dm)
    @. ((-((dm+Pm+Dm)*exp(g)*p*y0)/(exp(g)*p*y0+FT*ft*(1-p)*x0+1))+dm-bdt)^2+((-(FT*(dm+Pm+Dm)*ft*(1-p)*x0)/(exp(g)*p*y0+FT*ft*(1-p)*x0+1))-bPt+Pm)^2+((-(dm+Pm+Dm)/(exp(g)*p*y0+FT*ft*(1-p)*x0+1))-bDt+Dm)^2
end

function getP(p,x0,y0,ft,FT,g,bPt,bDt,bdt,Pm,Dm,dm)
    (FT*(dm+Pm+Dm)*ft*(1-p)*x0)/(exp(g)*p*y0+FT*ft*(1-p)*x0+1)+bPt
end

function getD(p,x0,y0,ft,FT,g,bPt,bDt,bdt,Pm,Dm,dm)
    (dm+Pm+Dm)/(exp(g)*p*y0+FT*ft*(1-p)*x0+1)+bDt
end

function getd(p,x0,y0,ft,FT,g,bPt,bDt,bdt,Pm,Dm,dm)
    ((dm+Pm+Dm)*exp(g)*p*y0)/(exp(g)*p*y0+FT*ft*(1-p)*x0+1)+bdt
end
