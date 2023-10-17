# polynomial fit with logarithmic coefficients
function polyFit(t,y;n=2)
    
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

function crunch!(pd::run;method="LuHf",refmat="Hogsbo")

    data = DRSprep(pd,method=method,refmat=refmat)

    tb = data.b[:,1]
    x = data.b[:,3]
    y = data.b[:,4]
    z = data.b[:,5]
    t = data.s[:,1]
    T = data.s[:,2]
    X = data.s[:,3]
    Y = data.s[:,4]
    Z = data.s[:,5]
    A = data.A
    B = data.B
    
    bx = polyFit(tb,x,n=2)
    by = polyFit(tb,y,n=2)
    bz = polyFit(tb,z,n=2)

    bXt = polyVal(bx,t)
    bYt = polyVal(by,t)
    bZt = polyVal(bz,t)
    
    function misfit(par)
        a0 = par[1]
        a1 = par[2]
        a2 = par[3]
        c = par[4]
        K0 = @. -(A*B*exp(a1)*t-A*exp(c)+A*B*bZt-A*bYt+((-B^2)-1)*bXt+A*B*T*exp(a2)+A*B*exp(a0)-A*B*Z+A*Y-A^2*X)/(B^2+A^2+1)
        M0 = @. ((A^2+1)*exp(a1)*t+B*exp(c)+(A^2+1)*bZt+B*bYt-A*B*bXt+(A^2+1)*T*exp(a2)+(A^2+1)*exp(a0)+B^2*Z-B*Y+A*B*X)/(B^2+A^2+1)
        S = @. ((-exp(a1)*t)-bZt-T*exp(a2)-exp(a0)+M0)^2+((-exp(c))-bYt-B*Z+Y-A*X+B*M0+A*K0)^2+(K0-bXt)^2
        sum(S)
    end

    fit = optimize(misfit,[0.0,0.0,0.0,-10.0])
    setPar!(pd,Optim.minimizer(fit))
    
end
