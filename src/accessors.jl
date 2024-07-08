function getExt(instrument)
    if instrument in ["Agilent","ThermoFisher"]
        return ".csv"
    else
        PTerror("unknownInstrument")
    end
end

function getChannels(run::Vector{Sample})
    return getChannels(run[1])
end
function getChannels(samp::Sample)
    return names(getDat(samp))
end
export getChannels

function getSnames(run::Vector{Sample})
    return getAttr(run,:sname)
end
export getSnames
function getGroups(run::Vector{Sample})
    return getAttr(run,:group)
end
export getGroups
function getAttr(run::Vector{Sample},attr::Symbol)
    ns = length(run)
    first = getproperty(run[1],attr)
    out = fill(first,ns)
    for i in eachindex(run)
        out[i] = getproperty(run[i],attr)
    end
    return out
end

function setStandards!(run::Vector{Sample},selection::Vector{Int},refmat::AbstractString)
    for i in selection
        run[i].group = refmat
    end
end
function setStandards!(run::Vector{Sample},prefix::AbstractString,refmat::AbstractString)
    snames = getSnames(run)
    selection = findall(contains(prefix),snames)
    setStandards!(run::Vector{Sample},selection,refmat)
end
function setStandards!(run::Vector{Sample},standards::AbstractDict)
    for (refmat,prefix) in standards
        setStandards!(run,prefix,refmat)
    end
end
function setStandards!(run::Vector{Sample},refmat::AbstractString)
    for sample in run
        sample.group = refmat
    end
end
export setStandards!

function isStandard(samp::Sample)
    samp.group != "sample"
end

function setBwin!(samp::Sample,bwin=nothing)
    if isnothing(bwin) bwin=autoWindow(samp,blank=true) end
    samp.bwin = bwin
end
function setBwin!(run::Vector{Sample},bwin=nothing)
    for i in eachindex(run)
        setBwin!(run[i],bwin)
    end
end
export setBwin!

function setSwin!(samp::Sample,swin=nothing)
    if isnothing(swin) swin=autoWindow(samp,blank=false) end
    samp.swin = swin
end
function setSwin!(run::Vector{Sample},swin=nothing)
    for i in eachindex(run)
        setSwin!(run[i],swin)
    end
end
export setSwin!

function getx0y0y1(method::AbstractString,
                   refmat::AbstractString)
    if method=="U-Pb"
        L8 = _PT["lambda"]["U238-Pb206"][1]
        L5 = _PT["lambda"]["U235-Pb207"][1]
        U58 = _PT["iratio"]["U-Pb"].U235/_PT["iratio"]["U-Pb"].U238
        t = _PT["refmat"][method][refmat].t[1]
        x0 = 1/(exp(L8*t)-1)
        y0 = _PT["refmat"][method][refmat].y0[1]
        y1 = U58*(exp(L5*t)-1)/(exp(L8*t)-1)
    else
        L = _PT["lambda"][method][1]
        t = _PT["refmat"][method][refmat].t[1]
        x0 = 1/(exp(L*t)-1)
        y0 = _PT["refmat"][method][refmat].y0[1]
        y1 = 0.0
    end
    return (x0=x0,y0=y0,y1=y1)
end

function getAnchor(method::AbstractString,refmat::AbstractString)
    return getx0y0y1(method,refmat)
end
function getAnchor(method::AbstractString,standards::Vector{String})
    nr = length(standards)
    out = Dict{String, NamedTuple}()
    for standard in standards
        out[standard] = getAnchor(method,standard)
    end
    return out
end
function getAnchor(method::AbstractString,standards::AbstractDict)
    return getAnchor(method,collect(keys(standards)))
end
export getAnchor

function setAnchor!(method::AbstractString,standards::AbstractDict)
    setMethod!(method)
    setStandards!(standards)
    setAnchor!()
end
function setAnchor!(method::AbstractString)
    setMethod!(method)
    setAnchor!()
end
export setAnchor!

function getDat(samp::Sample)
    return samp.dat[:,2:end-2]
end
function getDat(samp::Sample,channels::AbstractDict)
    return samp.dat[:,collect(values(channels))]
end
export getDat

function getPDd(method)
    i = findfirst(==(method),_PT["methods"][:,"method"])
    PDd = _PT["methods"][i,2:end]
    return PDd.P, PDd.D, PDd.d
end
export getPDd
function getMethods(csv::AbstractString=joinpath(@__DIR__,"../settings/methods.csv"))
    return CSV.read(csv, DataFrame)
end
export getMethods
function getLambdas(csv::AbstractString=joinpath(@__DIR__,"../settings/lambda.csv"))
    tab = CSV.read(csv, DataFrame)
    out = Dict()
    for row in eachrow(tab)
        out[row.method] = (row["lambda"],row["err"])
    end
    return out
end
export getLambdas
function getiratios(csv::AbstractString=joinpath(@__DIR__,"../settings/iratio.csv"))
    tab = CSV.read(csv, DataFrame)
    out = Dict()
    for row in eachrow(tab)
        isotope = row.isotope
        abundance = row.abundance
        method = row.method
        entry = NamedTuple{(Symbol(isotope),)}((abundance))
        if !(method in keys(out))
            out[method] = entry
        end
        out[method] = merge(out[method],entry)
    end
    return out
end
export getiratios
function getReferenceMaterials(csv::AbstractString=joinpath(@__DIR__,"../settings/standards.csv"))
    tab = CSV.read(csv, DataFrame)
    out = Dict()
    for row in eachrow(tab)
        method = row["method"]
        if !(method in keys(out))
            out[method] = Dict()
        end
        name = row["name"]
        out[method][name] = (t=(row["t"],row["st"]),y0=(row["y0"],row["sy0"]))
    end
    return out
end
export getReferenceMaterials
function setReferenceMaterials!(csv::AbstractString=joinpath(@__DIR__,"../settings/standards.csv"))
    _PT["refmat"] = getReferenceMaterials(csv)
end
export setReferenceMaterials!
