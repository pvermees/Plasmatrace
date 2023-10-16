function init(pd::run)
    b = fill(0.,9)
    a = fill(0.,3)
    c = -10.
    [b;a;c]
end

function crunch(pd::run;method="LuHf",refmat="Hogsbo")

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
    
    function misfit(par)
        K0 = getK0(b0x=par[1],b1x=par[2],b2x=par[3],
                   b0y=par[4],b1y=par[5],b2y=par[6],
                   b0z=par[7],b1z=par[8],b2z=par[9],
                   a0=par[10],a1=par[11],a2=par[12],c=par[13],
                   tb=tb,x=x,y=y,z=z,t=t,T=T,X=X,Y=Y,Z=Z,A=A,B=B)
        M0 = getM0(b0x=par[1],b1x=par[2],b2x=par[3],
                   b0y=par[4],b1y=par[5],b2y=par[6],
                   b0z=par[7],b1z=par[8],b2z=par[9],
                   a0=par[10],a1=par[11],a2=par[12],c=par[13],
                   tb=tb,x=x,y=y,z=z,t=t,T=T,X=X,Y=Y,Z=Z,A=A,B=B)
        out = SS(K0=K0,M0=M0,b0x=par[1],b1x=par[2],b2x=par[3],
                 b0y=par[4],b1y=par[5],b2y=par[6],
                 b0z=par[7],b1z=par[8],b2z=par[9],
                 a0=par[10],a1=par[11],a2=par[12],c=par[13],
                 tb=tb,x=x,y=y,z=z,t=t,T=T,X=X,Y=Y,Z=Z,A=A,B=B)
        println(out)
    end

    optimize(misfit,init(pd))
    
end

function SS(;K0,M0,b0x,b1x,b2x,b0y,b1y,b2y,b0z,b1z,b2z,a0,a1,a2,c,tb,x,y,z,t,T,X,Y,Z,A,B)
    s = @. (z-b2z*tb^2-b1z*tb-b0z)^2+(y-b2y*tb^2-b1y*tb-b0y)^2+(x-b2x*tb^2-b1x*tb-b0x)^2+((-b2z*t^2)-b1z*t-exp(a1)*t-b0z-T*exp(a2)-exp(a0)+M0)^2+((-b2y*t^2)-b1y*t-exp(c)-b0y-B*Z+Y-A*X+B*M0+A*K0)^2+((-b2x*t^2)-b1x*t-b0x+K0)^2
    sum(s)
end

function getK0(;b0x,b1x,b2x,b0y,b1y,b2y,b0z,b1z,b2z,a0,a1,a2,c,tb,x,y,z,t,T,X,Y,Z,A,B)
    @. -((A*B*b2z-A*b2y+((-B^2)-1)*b2x)*t^2+(A*B*b1z-A*b1y+((-B^2)-1)*b1x+A*B*exp(a1))*t-A*exp(c)+A*B*b0z-A*b0y+((-B^2)-1)*b0x+A*B*T*exp(a2)+A*B*exp(a0)-A*B*Z+A*Y-A^2*X)/(B^2+A^2+1)
end

function getM0(;b0x,b1x,b2x,b0y,b1y,b2y,b0z,b1z,b2z,a0,a1,a2,c,tb,x,y,z,t,T,X,Y,Z,A,B)
    @. (((A^2+1)*b2z+B*b2y-A*B*b2x)*t^2+((A^2+1)*b1z+B*b1y-A*B*b1x+(A^2+1)*exp(a1))*t+B*exp(c)+(A^2+1)*b0z+B*b0y-A*B*b0x+(A^2+1)*T*exp(a2)+(A^2+1)*exp(a0)+B^2*Z-B*Y+A*B*X)/(B^2+A^2+1)
end
