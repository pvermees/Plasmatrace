function getX(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    @. -(((A^2*FT*bXt-A^2*FT*Xm)*exp(2*c)+FT*bXt-FT*Xm)*ft+A*B*(Zm-bZt)*exp(2*c)+(B*bYt-B*Ym)*exp(c))/((A^2*FT^2*exp(2*c)+FT^2)*ft^2+B^2*exp(2*c))
end

function getZ(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    @. -(((A*FT^2*bYt-A*FT^2*Ym)*exp(c)+FT^2*(bZt-Zm))*ft^2+(A*B*FT*Xm-A*B*FT*bXt)*exp(2*c)*ft+B^2*(bZt-Zm)*exp(2*c))/((A^2*FT^2*exp(2*c)+FT^2)*ft^2+B^2*exp(2*c))
end

function getS(Z,X,Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    @. ((-FT*X*ft)-bXt+Xm)^2+((-(A*Z+B*X)*exp(c))-bYt+Ym)^2+((-bZt)+Zm-Z)^2
end
