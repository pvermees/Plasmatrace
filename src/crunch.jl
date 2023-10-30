function getX(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    @. -((FT*bXt*(exp(2*c)+A^2)+FT*Xm*((-exp(2*c))-A^2))*ft+B*bYt*exp(2*c)-B*Ym*exp(2*c)+A*B*(Zm-bZt)*exp(c))/(FT^2*(exp(2*c)+A^2)*ft^2+B^2*exp(2*c))
end

function getZ(Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    @. -((FT^2*(bZt-Zm)*exp(c)+A*FT^2*bYt-A*FT^2*Ym)*ft^2+(A*B*FT*Xm-A*B*FT*bXt)*ft+B^2*(bZt-Zm)*exp(c))/(FT^2*(exp(2*c)+A^2)*ft^2+B^2*exp(2*c))
end

function getS(X,Z,Xm,Ym,Zm,A,B,ft,FT,bXt,bYt,bZt,c)
    @. ((-FT*X*ft)-bXt+Xm)^2+((-Z*exp(c))-bZt+Zm)^2+((-bYt)-A*Z+Ym-B*X)^2
end
