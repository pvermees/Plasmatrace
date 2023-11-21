# get sample attributes from a run:
function accesSample(pd::run,
                     i::Union{Nothing,Integer,AbstractVector{<:Integer}},
                     T::Type,
                     fun::Function)
    if isnothing(i) i = 1:length(pd) end
    samples = getSamples(pd)[i]
    if isa(i,Integer)
        out = fun(samples)
    else
        out = Vector{T}(undef,size(i,1))
        for j in eachindex(samples)
            out[j] = fun(samples[j])
        end
    end
    out
end
function accesSample!(pd::run,
                      i::Union{Integer,AbstractVector{<:Integer}},
                      fun::Function,val::Any)
    samples = getSamples(pd)
    for j in i fun(samples[j],val) end
    setSamples!(pd,samples)
end
# set the control parameters inside a run:
function accessControl!(pd::run,fun::Function,val::Any)
    ctrl = getControl(pd)
    fun(ctrl,val)
    setControl!(pd,ctrl)
end
# set the pars parameters inside a run:
function accessPar!(pd::run,fun::Function,val::Any)
    par = getPar(pd)
    fun(par,val)
    setPar!(pd,par)
end

# get sample attributes
function getSname(pd::sample) getproperty(pd,:sname) end
function getDateTime(pd::sample) getproperty(pd,:datetime) end
function getDat(pd::sample) getproperty(pd,:dat) end
function getBWin(pd::sample) getproperty(pd,:bwin) end
function getSWin(pd::sample) getproperty(pd,:swin) end
function getStandard(pd::sample) getproperty(pd,:standard) end

# get run attributes
function getSamples(pd::run) getproperty(pd,:samples) end
function getControl(pd::run) getproperty(pd,:control) end
function getPar(pd::run) getproperty(pd,:par) end
function getCov(pd::run) getproperty(pd,:cov) end

# get sample attributes from a run
function getSnames(pd::run;i=nothing) accesSample(pd,i,AbstractString,getSname) end
function getDateTimes(pd::run;i=nothing) accesSample(pd,i,DateTime,getDateTime) end
function getDat(pd::run;i=nothing) accesSample(pd,i,DataFrame,getDat) end
function getBWin(pd::run;i=nothing) accesSample(pd,i,AbstractVector{window},getBWin) end
function getSWin(pd::run;i=nothing) accesSample(pd,i,AbstractVector{window},getSWin) end
function getStandard(pd::run;i=nothing) accesSample(pd,i,Integer,getStandard) end

# get control attributes
function getInstrument(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:instrument) end
function getMethod(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:method) end
function getx0(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:x0) end
function gety0(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:y0) end
function getIsotopes(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:isotopes) end
function getChannels(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:channels) end
function getGainOption(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:gainOption) end

# get control attributes from a run
function getMethod(pd::run) getMethod(getControl(pd)) end
function getx0(pd::run) getx0(getControl(pd)) end
function gety0(pd::run) gety0(getControl(pd)) end
function getIsotopes(pd::run) getIsotopes(getControl(pd)) end
function getChannels(pd::run) getChannels(getControl(pd)) end
function getGainOption(pd::run) getGainOption(getControl(pd)) end

# set sample attributes
function setSname!(pd::sample,sname::String) setproperty!(pd,:sname,sname) end
function setDateTime!(pd::sample,datetime::DateTime) setproperty!(pd,:datetime,datetime) end
function setDat!(pd::sample,dat::DataFrame) setproperty!(pd,:dat,dat) end
function setBWin!(pd::sample,bwin::Vector{window}) setproperty!(pd,:bwin,bwin) end
function setSWin!(pd::sample,swin::Vector{window}) setproperty!(pd,:swin,swin) end
function setStandard!(pd::sample,standard::Integer) setproperty!(pd,:standard,standard) end
export setStandard!

# set run attributes
function setSamples!(pd::run,samples::AbstractVector{sample}) setproperty!(pd,:samples,samples) end
function setControl!(pd::run,ctrl::control) setproperty!(pd,:control,ctrl) end
function setPar!(pd::run,par::fitPars) setproperty!(pd,:par,par) end
function setCov!(pd::run,cov::Matrix) setproperty!(pd,:cov,cov) end

# set key sample attributes in a run
function setBWin!(pd::run;i::Union{Integer,AbstractVector{<:Integer}},bwin::Vector{window}) accesSample!(pd,i,setBwin!,bwin) end
function setSWin!(pd::run;i::Union{Integer,AbstractVector{<:Integer}},swin::Vector{window}) accesSample!(pd,i,setSwin!,swin) end
function setStandard!(pd::run;i::Union{Int,AbstractVector{<:Integer}},standard::Integer) accesSample!(pd,i,setStandard!,standard) end

# set control attributes
function setInstrument!(ctrl::control,instrument::String) setproperty!(ctrl,:instrument,instrument) end
function setMethod!(ctrl::control,method::String) setproperty!(ctrl,:method,method) end
function setx0!(ctrl::control,x0::Vector{Float64}) setproperty!(ctrl,:x0,x0) end
function sety0!(ctrl::control,y0::Vector{Float64}) setproperty!(ctrl,:y0,y0) end
function setIsotopes!(ctrl::control,isotopes::Vector{String}) setproperty!(ctrl,:isotopes,isotopes) end
function setChannels!(ctrl::control,channels::Vector{String}) setproperty!(ctrl,:channels,channels) end
function setGainOption!(ctrl::control,gainOption::Integer) setproperty!(ctrl,:gainOption,gainOption) end

# set control attributes in a run
function setInstrument!(pd::run,instrument::String) accessControl!(pd,setInstrument!,instrument) end
function setMethod!(pd::run,method::String) accessControl!(pd,setMethod!,method) end
function setx0!(pd::run,x0::Vector{Float64}) accessControl!(pd,setx0!,x0) end
function sety0!(pd::run,y0::Vector{Float64}) accessControl!(pd,sety0!,y0) end
function setIsotopes!(pd::run,isotopes::Vector{String}) accessControl!(pd,setIsotopes!,isotopes) end
function setChannels!(pd::run,channels::Vector{String}) accessControl!(pd,setChannels!,channels) end
function setGainOption!(pd::run,gainOption::Integer) accessControl!(pd,setGainOption!,gainOption) end

# get fitPars attributes
function getBlankPars(fp::fitPars) getproperty(fp,:blank) end
function getDriftPars(fp::fitPars) getproperty(fp,:drift) end
function getDownPars(fp::fitPars) getproperty(fp,:down) end
function getGainPar(fp::fitPars) getproperty(fp,:gain) end

# set fitPars attributes
function setBlankPars!(fp::fitPars,blank::AbstractVector{<:AbstractFloat}) setproperty!(fp,:blank,blank) end
function setDriftPars!(fp::fitPars,drift::AbstractVector{<:AbstractFloat}) setproperty!(fp,:drift,drift) end
function setDownPars!(fp::fitPars,down::AbstractVector{<:AbstractFloat}) setproperty!(fp,:down,down) end
function setGainPar!(fp::fitPars,gain::AbstractFloat) setproperty!(fp,:gain,gain) end

# get fitPars attributes from a run
function getBlankPars(pd::run) getBlankPars(getPar(pd)) end
function getDriftPars(pd::run) getDriftPars(getPar(pd)) end
function getDownPars(pd::run) getDownPars(getPar(pd)) end
function getGainPar(pd::run) getGainPar(getPar(pd)) end

# set fitPars attributes in a run
function setBlankPars!(pd::run,blank::AbstractVector{<:AbstractFloat}) accessPar!(pd,setBlankPars!,blank) end
function setDriftPars!(pd::run,drift::AbstractVector{<:AbstractFloat}) accessPar!(pd,setDriftPars!,drift) end
function setDownPars!(pd::run,down::AbstractVector{<:AbstractFloat}) accessPar!(pd,setDownPars!,down) end
function setGainPar!(pd::run,gain::AbstractFloat) accessPar!(pd,setGainPar!,gain) end

length(pd::run) = size(getSamples(pd),1)

function poolRunDat(pd::run,i=nothing)
    dats = getDat(pd,i=i)
    typeof(dats)
    reduce(vcat,dats)
end
