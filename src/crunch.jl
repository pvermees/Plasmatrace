# polynomial fit with logarithmic coefficients
function polyFit(t,y;n=1)
    
    b0 = log(abs(Statistics.mean(y)))
    init = n>1 ? [b0;fill(-10,n-1)] : [b0]
    nt = size(t,1)
    
    function misfit(par)
        pred = fill(exp(par[1]),nt)
        if n>1
            for i in 2:n
                @. pred += exp(par[i])*t^(i-1)
            end
        end
        sum((y.-pred).^2)
    end

    fit = optimize(misfit,init)
    Optim.minimizer(fit)
    
end

function polyVal(p,t)
    np = size(p,1)
    nt = size(t,1)
    out = fill(0.0,nt)
    if np>1
        for i in 2:np
            out .+= exp(p[i]).*t.^(i-1)
        end
    end
    out
end

function crunch!(pd::run;method="LuHf",refmat="Hogsbo",n::Int=2)

    data = DRSprep!(pd,method=method,refmat=refmat)

    tb = data.b[:,1]
    xm = data.b[:,3]
    ym = data.b[:,4]
    zm = data.b[:,5]
    t = data.s[:,1]
    T = data.s[:,2]
    Xm = data.s[:,3]
    Ym = data.s[:,4]
    Zm = data.s[:,5]
    A = data.A
    B = data.B

    bx = polyFit(tb,xm,n=n)
    by = polyFit(tb,ym,n=n)
    bz = polyFit(tb,zm,n=n)

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
