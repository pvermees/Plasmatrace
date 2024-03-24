function form_ratios(df::AbstractDataFrame,
                    numerator::AbstractString,
                    denominator::Union{Nothing,AbstractVector};
                    brackets=false)
    form_ratios(df,[numerator],denominator,brackets=brackets)
end
function form_ratios(df::AbstractDataFrame,
                    numerator::Union{Nothing,AbstractVector},
                    denominator::AbstractString;
                    brackets=false)
    form_ratios(df,numerator,[denominator],brackets=brackets)
end
function form_ratios(df::AbstractDataFrame,
                    numerator::Union{Nothing,AbstractVector},
                    denominator::Union{Nothing,AbstractVector};
                    brackets=false)
    labels = names(df)
    channels_count = size(labels,1)
    if isnothing(numerator) && isnothing(denominator)
        return df
    elseif isnothing(numerator)
        n = findall(!=(denominator[1]),labels)
        d = fill(findfirst(==(denominator[1]),labels),length(n))
    elseif isnothing(denominator)
        d = findall(!=(numerator[1]),labels)
        n = fill(findfirst(==(numerator[1]),labels),length(d))
    elseif length(numerator)==length(denominator)
        n = findall(in(numerator),labels)
        d = findall(in(denominator),labels)
    elseif length(numerator)>length(denominator)
        n = findall(in(numerator),labels)
        d = fill(findfirst(==(denominator[1]),labels),length(n))
    else
        d = findall(in(denominator),labels)
        n = fill(findfirst(==(numerator[1]),labels),length(d))
    end
    mat = Matrix(df)
    ratios = mat[:,n]./mat[:,d]
    numerator = labels[n]
    denominator = labels[d]
    ratio_labels = brackets ? "(".*numerator.*")/(".*denominator.*")" : numerator.*"/".*denominator
    DataFrame(ratios,ratio_labels)
end

# polynomial fit with logarithmic coefficients
function polynomial_fit(;t,y,n=1)

    function misfit(par)
        pred = polynomial_values(p=par,t=t)
        sum((y.-pred).^2)
    end

    b0 = log(abs(Statistics.mean(y)))
    init = [b0;fill(-10,n-1)]
    fit = Optim.optimize(misfit,init)
    Optim.minimizer(fit)

end

function polynomial_values(;p,t)
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
export polynomial_values

function polynomial_factor(;p,t)
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
export polynomial_factor
