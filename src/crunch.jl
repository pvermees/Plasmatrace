function getX(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    @. -(exp(c)*(A*bYt*exp(2*ft+2*FT)-A*Ym*exp(2*ft+2*FT))+bXt*exp(2*ft+2*FT)-Xm*exp(2*ft+2*FT)+exp(2*c)*(A*B*(exp(FT)*Zm-exp(FT)*bZt)*exp(ft)+B^2*bXt-B^2*Xm))/(exp(2*c)*(A^2*exp(2*ft+2*FT)+B^2)+exp(2*ft+2*FT))
end

function getZ(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    @. (exp(2*c)*(A^2*(exp(FT)*Zm-exp(FT)*bZt)*exp(ft)+A*B*bXt-A*B*Xm)+(exp(FT)*Zm-exp(FT)*bZt)*exp(ft)+(B*Ym-B*bYt)*exp(c))/(exp(2*c)*(A^2*exp(2*ft+2*FT)+B^2)+exp(2*ft+2*FT))
end

function getS(X,Z,Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    @. ((-Z*exp(ft+FT))-bZt+Zm)^2+((-(B*Z+A*X)*exp(c))-bYt+Ym)^2+((-bXt)+Xm-X)^2
end
