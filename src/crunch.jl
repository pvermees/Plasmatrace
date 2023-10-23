function getX(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    @. ((A*B*FT*(bZt-Zm)*exp(c)-B*FT*bYt+B*FT*Ym)*ft+(A^2*Xm-A^2*bXt)*exp(2*c)-bXt+Xm)/(B^2*FT^2*ft^2+A^2*exp(2*c)+1)
end

function getZ(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    @. -(B^2*FT^2*(bZt-Zm)*ft^2+(A*B*FT*Xm-A*B*FT*bXt)*exp(c)*ft+(A*bYt-A*Ym)*exp(c)+bZt-Zm)/(B^2*FT^2*ft^2+A^2*exp(2*c)+1)
end

function getS(X,Z,Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    @. ((-B*FT*X*ft)-A*Z*exp(c)-bYt+Ym)^2+((-bZt)+Zm-Z)^2+((-bXt)+Xm-X)^2
end
