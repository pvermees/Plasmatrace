function formRatios(df,num="",den="";sigma=0.0)
    N = num=="" ? nothing : [num]
    D = den=="" ? nothing : [den]
    return formRatios(df,N,D,sigma=sigma,brackets=!isnothing(D))
end
function formRatios(df,num::Union{Nothing,AbstractVector}=nothing,
                    den::Union{Nothing,AbstractVector}=nothing;
                    sigma=0.0,brackets=false)
    labels = names(df)
    nc = size(labels,1)
    if isnothing(num)
        if isnothing(den)
            PTerror("missingNumDen")
        else
            n = findall(!=(den[1]),labels)
            d = fill(findfirst(==(den[1]),labels),size(n,1))
        end
    elseif isnothing(den)
        if isnothing(num)
            PTerror("missingNumDen")
        else
            d = findall(!=(num[1]),labels)
            n = fill(findfirst(==(num[1]),labels),size(d,1))
        end
    else
        nnum = size(num,1)
        nden = size(den,1)
        if nnum==nden
            n = findall(in(num),labels)
            d = findall(in(den),labels)
        elseif nnum>nden
            n = findall(in(num),labels)
            d = fill(findfirst(==(den[1]),labels),size(n,1))
        else
            d = findall(in(den),labels)
            n = fill(findfirst(==(num[1]),labels),size(d,1))
        end
    end
    mat = Matrix(df)
    ratios = mat[:,n]./mat[:,d]
    num = labels[n]
    den = labels[d]
    ratlabs = brackets ? "(".*num.*")/(".*den.*")" : num.*"/".*den
    if sigma>0.0
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
            row[irow] = E[r,c]/sqrt(E[r,r]*E[c,c])
            olabs[irow] = "r[".*ratlabs[r].*",".*ratlabs[c].*"]"
        end
        out = DataFrame(reshape(row,1,nout),olabs)
    else # error propagation
        out = DataFrame(ratios,ratlabs)
    end
    out
end

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
    out = fill(0.0,nt)
    if np>0
        for i in 1:np
            out .+= exp(p[i]).*t.^(i-1)
        end
    end
    out
end
export polyVal

function polyFac(;p,t)
    np = size(p,1)
    nt = size(t,1)
    out = fill(1.0,nt)
    if np>0
        out = fill(0.0,nt)
        for i in 1:np
            out .+= p[i].*t.^(i-1)
        end
    end
    exp.(out)
end
export polyFac
