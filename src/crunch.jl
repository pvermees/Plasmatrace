function getP(Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,c)
    @. -((FT*bPt*(exp(2*c)+A^2)+FT*Pm*((-exp(2*c))-A^2))*ft+B*bdt*exp(2*c)-B*dm*exp(2*c)+A*B*(Dm-bDt)*exp(c))/(FT^2*(exp(2*c)+A^2)*ft^2+B^2*exp(2*c))
end

function getD(Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,c)
    @. -((FT^2*(bDt-Dm)*exp(c)+A*FT^2*bdt-A*FT^2*dm)*ft^2+(A*B*FT*Pm-A*B*FT*bPt)*ft+B^2*(bDt-Dm)*exp(c))/(FT^2*(exp(2*c)+A^2)*ft^2+B^2*exp(2*c))
end

function getS(P,D,Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,c)
    @. ((-FT*P*ft)-bPt+Pm)^2 + ((-bdt)-A*D+dm-B*P)^2 + ((-D*exp(c))-bDt+Dm)^2
end
