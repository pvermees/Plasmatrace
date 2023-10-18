function crunch!(pd::run;method="LuHf",refmat="Hogsbo",n::Int=2)

    t = data.s[:,1]
    T = data.s[:,2]
    Xm = data.s[:,3]
    Ym = data.s[:,4]
    Zm = data.s[:,5]
    A = data.A
    B = data.B

    bXt = polyVal(bx,t)
    bYt = polyVal(by,t)
    bZt = polyVal(bz,t)
    
    function misfit(par)
        ft = polyVal(par[1:n],t)
        FT = polyVal(par[n+1:2*n],T)
        c = par[end]
        X = getX(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
        Z = getZ(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
        sum(getS(X,Z,Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c))
    end

    init = [log(abs(mean(Zm)));fill(0.0,2*n-1);-10.0]
    fit = optimize(misfit,init)
    sol = Optim.minimizer(fit)
    setPar!(pd,[bx;by;bz;sol])
    
end

function getX(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    @. -(exp(c)*(A*bYt*exp(2*ft+2*FT)-A*Ym*exp(2*ft+2*FT))+bXt*exp(2*ft+2*FT)-Xm*exp(2*ft+2*FT)+exp(2*c)*(A*B*(exp(FT)*Zm-exp(FT)*bZt)*exp(ft)+B^2*bXt-B^2*Xm))/(exp(2*c)*(A^2*exp(2*ft+2*FT)+B^2)+exp(2*ft+2*FT))
end

function getZ(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    @. (exp(2*c)*(A^2*(exp(FT)*Zm-exp(FT)*bZt)*exp(ft)+A*B*bXt-A*B*Xm)+(exp(FT)*Zm-exp(FT)*bZt)*exp(ft)+(B*Ym-B*bYt)*exp(c))/(exp(2*c)*(A^2*exp(2*ft+2*FT)+B^2)+exp(2*ft+2*FT))
end

function getS(X,Z,Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    @. ((-Z*exp(ft+FT))-bZt+Zm)^2+((-(B*Z+A*X)*exp(c))-bYt+Ym)^2+((-bXt)+Xm-X)^2
end

function predict(pd::processed)
    par = getPar(pd)
    if isnothing(par) return nothing end
    np = size(par,1)
    n = Int((np-1)/5)
    c = par[end]
    f = par[1:n]
    F = par[n+1:2*n]
    bx = par[2*n+1:3*n]
    by = par[3*n+1:4*n]
    bz = par[4*n+1:5*n]
    dat = signalData(pd)
    t = dat[:,1]
    T = dat[:,2]
    Xm = dat[:,1]
    Ym = dat[:,2]
    Zm = dat[:,3]
    ft = polyVal(f,t)
    FT = polyVal(F,T)
    bXt = polyVal(bx,t)
    bYt = polyVal(by,t)
    bZt = polyVal(bz,t)
    # X = getX(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    # Z = getZ(Xm,Ym,Zm,A,B,t,T,ft,FT,bXt,bYt,bZt,c)
    # TODO: Y = (A*X + B*Z)*exp(c)
end
