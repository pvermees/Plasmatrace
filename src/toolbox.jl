function formRatios(df::AbstractDataFrame,
                    num::AbstractString,
                    den::Union{Nothing,AbstractVector};
                    brackets=false)
    formRatios(df,[num],den,brackets=brackets)
end
function formRatios(df::AbstractDataFrame,
                    num::Union{Nothing,AbstractVector},
                    den::AbstractString;
                    brackets=false)
    formRatios(df,num,[den],brackets=brackets)
end
function formRatios(df::AbstractDataFrame,
                    num::Union{Nothing,AbstractVector},
                    den::Union{Nothing,AbstractVector};
                    brackets=false)
    labels = names(df)
    nc = size(labels,1)
    if isnothing(num) && isnothing(den)
        return df
    elseif isnothing(num)
        n = findall(!=(den[1]),labels)
        d = fill(findfirst(==(den[1]),labels),length(n))
    elseif isnothing(den)
        d = findall(!=(num[1]),labels)
        n = fill(findfirst(==(num[1]),labels),length(d))
    elseif length(num)==length(den)
        n = findall(in(num),labels)
        d = findall(in(den),labels)        
    elseif length(num)>length(den)
        n = findall(in(num),labels)
        d = fill(findfirst(==(den[1]),labels),length(n))
    else
        d = findall(in(den),labels)
        n = fill(findfirst(==(num[1]),labels),length(d))
    end
    mat = Matrix(df)
    ratios = mat[:,n]./mat[:,d]
    num = labels[n]
    den = labels[d]
    ratlabs = brackets ? "(".*num.*")/(".*den.*")" : num.*"/".*den
    DataFrame(ratios,ratlabs)
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
