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
