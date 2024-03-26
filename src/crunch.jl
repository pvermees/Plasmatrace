function getD(Pm, Dm, dm, x0, y0, ft, FT, mf, bPt, bDt, bdt)
    D = @. -(
        ((FT * bPt - FT * Pm) * ft * mf^2 * x0 + (bDt - Dm) * mf^2) * y0^2 +
        (FT^2 * bdt - FT^2 * dm) * ft^2 * mf * x0^2 * y0 +
        (FT^2 * bDt - Dm * FT^2) * ft^2 * x0^2
    ) / ((FT^2 * ft^2 * mf^2 * x0^2 + mf^2) * y0^2 + FT^2 * ft^2 * x0^2)
    return D
end
export getD
function getp(Pm, Dm, dm, x0, y0, ft, FT, mf, bPt, bDt, bdt)
    p = @. -(
        ((FT^2 * dm - FT^2 * bdt) * ft^2 * mf * x0^2 + (dm - bdt) * mf) * y0 +
        (Dm * FT^2 - FT^2 * bDt) * ft^2 * x0^2 +
        (FT * bPt - FT * Pm) * ft * x0
    ) / (
        ((FT * bPt - FT * Pm) * ft * mf^2 * x0 + (bDt - Dm) * mf^2) * y0^2 +
        (FT^2 * bdt - FT^2 * dm) * ft^2 * mf * x0^2 * y0 +
        (FT^2 * bDt - Dm * FT^2) * ft^2 * x0^2
    )
    return p
end
export getp
function SS(
    t,
    T,
    Pm,
    Dm,
    dm,
    x0,
    y0,
    drift,
    downhole_fractionation,
    mass_fractionation,
    bP,
    bD,
    bd,
)
    pred = predict(
        t,
        T,
        Pm,
        Dm,
        dm,
        x0,
        y0,
        drift,
        downhole_fractionation,
        mass_fractionation,
        bP,
        bD,
        bd,
    )
    S = @. (pred[:, "P"] - Pm)^2 + (pred[:, "D"] - Dm)^2 + (pred[:, "d"] - dm)^2
    return sum(S)
end

function predict(
    t,
    T,
    Pm,
    Dm,
    dm,
    x0,
    y0,
    drift,
    downhole_fractionation,
    mass_fractionation,
    bP,
    bD,
    bd,
)
    ft = polynomial_factor(; p = drift, t = t)
    FT = polynomial_factor(; p = downhole_fractionation, t = T)
    mf = exp(mass_fractionation)
    bPt = polynomial_values(; p = bP, t = t)
    bDt = polynomial_values(; p = bD, t = t)
    bdt = polynomial_values(; p = bd, t = t)
    D = getD(Pm, Dm, dm, x0, y0, ft, FT, mf, bPt, bDt, bdt)
    p = getp(Pm, Dm, dm, x0, y0, ft, FT, mf, bPt, bDt, bdt)
    Pf = @. D * x0 * (1 - p) * ft * FT + bPt
    Df = @. D + bDt
    df = @. D * y0 * p * mf + bdt
    return DataFrame(; t = t, T = T, P = Pf, D = Df, d = df)
end
function predict(
    sample::Sample,
    parameters::Parameters,
    blank::AbstractDataFrame,
    channels::AbstractDict,
    anchors::AbstractDict,
)
    if haskey(anchors, sample.group)
        data = windowData(sample; signal = true)
        (x0, y0) = anchors[sample.group]
        return predict(data, parameters, blank, channels, x0, y0)
    else
        PTerror("notStandard")
    end
end
function predict(
    data::AbstractDataFrame,
    parameters::Parameters,
    blank::AbstractDataFrame,
    channels::AbstractDict,
    x0::AbstractFloat,
    y0::AbstractFloat,
)
    t = data[:, 1]
    T = data[:, 2]
    Pm = data[:, channels["P"]]
    Dm = data[:, channels["D"]]
    dm = data[:, channels["d"]]
    bP = blank[:, channels["P"]]
    bD = blank[:, channels["D"]]
    bd = blank[:, channels["d"]]
    return predict(
        t,
        T,
        Pm,
        Dm,
        dm,
        x0,
        y0,
        parameters.drift,
        parameters.downhole_fractionation,
        parameters.mass_fractionation,
        bP,
        bD,
        bd,
    )
end
export predict
