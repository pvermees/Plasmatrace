function getP(Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,g)
    @. -((FT*bPt*(exp(2*g)+A^2)+FT*Pm*((-exp(2*g))-A^2))*ft+B*bdt*exp(2*g)-B*dm*exp(2*g)+A*B*(Dm-bDt)*exp(g))/(FT^2*(exp(2*g)+A^2)*ft^2+B^2*exp(2*g))
end

function getD(Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,g)
    @. -((FT^2*(bDt-Dm)*exp(g)+A*FT^2*bdt-A*FT^2*dm)*ft^2+(A*B*FT*Pm-A*B*FT*bPt)*ft+B^2*(bDt-Dm)*exp(g))/(FT^2*(exp(2*g)+A^2)*ft^2+B^2*exp(2*g))
end

function getS(P,D,Pm,Dm,dm,A,B,ft,FT,bPt,bDt,bdt,g)
    @. (Pm-P*ft*FT-bPt)^2 + (dm-A*D-B*P-bdt)^2 + (Dm-D*exp(g)-bDt)^2
end
