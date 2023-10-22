# polynomial fit with logarithmic coefficients
function polyFit(;t,y,n=1)
    
    function misfit(par)
        pred = polyVal(p=par,t=t)
        sum((y.-pred).^2)
    end

    b0 = log(abs(Statistics.mean(y)))
    init = [b0;fill(-10,n-1)]
    fit = optimize(misfit,init)
    Optim.minimizer(fit)

end

function polyVal(;p,t)
    np = size(p,1)
    nt = size(t,1)
    out = fill(exp(p[1]),nt)
    if np>1
        for i in 2:np
            out .+= exp(p[i]).*t.^(i-1)
        end
    end
    out
end
