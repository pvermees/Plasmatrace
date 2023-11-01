# polynomial fit with logarithmic coefficients
function polyFit(;t,y,n=1)
    
    function misfit(par)
        pred = polyVal(p=par,t=t)
        sum((y.-pred).^2)
    end

    b0 = log(abs(Statistics.mean(y)))
    init = [b0;fill(-10,n-1)]
    fit = Optim.optimize(misfit,init)
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

function average(df;logratios=false)
    nin = ncol(df)
    function misfit(mu,df,logratios)
        expected = logratios ? exp.(mu) : mu
    end
    mu = Statistics.mean.(eachcol(df))
    if logratios # TODO
        init = log.(mu)
        # optimise
    else
        sigma = Statistics.cov(Matrix(df))
    end
    ncov = Int(nin*(nin-1)/2)
    nout = 2*nin+ncov
    out = Vector{AbstractFloat}(undef,nout)
    out[1:2:(2*nin-1)] = mu
    out[2:2:2*nin] = sqrt.(LinearAlgebra.diag(sigma))
    for i in 1:ncov
        j, k = iuppert(i,nin)
        out[2*nin+i] = sigma[j,k]/sqrt(sigma[j,j]*sigma[k,k])
    end
    out
end

function iuppert(k::Integer,n::Integer)
  i = n - 1 - floor(Int,sqrt(-8*k + 4*n*(n-1) + 1)/2 - 0.5)
  j = k + i + ( (n-i+1)*(n-i) - n*(n-1) )÷2
  return i, j
end
