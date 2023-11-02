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

# average ratios
function averat(df;num=nothing,den=nothing,logratios=false)
    nin = ncol(df)
    nr = nrow(df)
    function misfit(mu,df,logratios)
        expected = logratios ? exp.(mu) : mu
    end
    muvec = Statistics.mean.(eachcol(df))
    mumat = reshape(muvec,(1,nin))
    mu = DataFrame(mumat,names(df))
    if logratios # TODO
        init = log.(mu)
        out = nothing
        # optimise
    else
        sigma = Statistics.cov(Matrix(df))/nr
        out = formRatios(mu,sigma=sigma,num=num,den=den)
    end
    out
end

# gets k-th linear index (i,j) of n x n matrix
function iuppert(k::Integer,n::Integer)
  i = n - 1 - floor(Int,sqrt(-8*k + 4*n*(n-1) + 1)/2 - 0.5)
  j = k + i + div( (n-i+1)*(n-i) - n*(n-1) , 2)
  return i, j
end

function formRatios(df;sigma=nothing,num=nothing,den=nothing,brackets=false)
    labels = names(df)
    nc = size(labels,1)
    if isnothing(num)
        if isnothing(den)
            PTerror("missingNumDen")
        else
            n = findall(!=(den[1]),labels)
            d = fill(findfirst(==(den[1]),labels),nc-1)
        end
    elseif isnothing(den)
        if isnothing(num)
            PTerror("missingNumDen")
        else
            d = findall(!=(num[1]),labels)
            n = fill(findfirst(==(num[1]),labels),nc-1)
        end
    else
        nnum = size(num,1)
        nden = size(den,1)
        if nnum==nden
            n = findall(in(num),labels)
            d = findall(in(den),labels)
        elseif nnum>nden
            n = findall(in(num),labels)
            d = fill(findfirst(==(den[1]),labels),nc-1)
        else
            d = findall(in(den),labels)
            n = fill(findfirst(==(num[1]),labels),nc-1)
        end
    end
    mat = Matrix(df)
    ratios = mat[:,n]./mat[:,d]
    num = labels[n]
    den = labels[d]
    ratlabs = brackets ? "(".*num.*")/(".*den.*")" : num.*"/".*den
    if isnothing(sigma)
        DataFrame(ratios,ratlabs)
    else # error propagation
        nin = ncol(df)
        nrat = size(ratios,2)
        J = fill(0.0,nrat,nin)
        for i in 1:nrat
            J[i,n[i]] = 1/mat[1,d[i]]
            J[i,d[i]] = -mat[1,n[i]]/mat[1,d[i]]^2
        end
        E = J * sigma * transpose(J)
        ncov = Int(nrat*(nrat-1)/2)
        nout = 2*nrat+ncov
        row = fill(0.0,nout)
        olabs = fill("",nout)
        irat = 1:2:(2*nrat-1)
        row[irat] = ratios[1,:]
        olabs[irat] = ratlabs
        israt = 2:2:2*nrat
        row[israt] = sqrt.(LinearAlgebra.diag(E))
        olabs[israt] = "s[".*ratlabs.*"]"
        for i in 1:ncov
            r,c = iuppert(i,nrat)
            irow = 2*nrat+i
            row[irow] = sigma[r,c]/sqrt(sigma[r,r]*sigma[c,c])
            olabs[irow] = "r[".*ratlabs[r].*"/".*ratlabs[c].*"]"
        end
        out = DataFrame(reshape(row,1,nout),olabs)
    end
    out
end
