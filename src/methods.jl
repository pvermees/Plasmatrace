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
function getBPar(pd::run) getproperty(pd,:bpar) end
function getSPar(pd::run) getproperty(pd,:spar) end
function getBCov(pd::run) getproperty(pd,:bcov) end
function getSCov(pd::run) getproperty(pd,:scov) end

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
function getA(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:A) end
function getB(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:B) end
function getIsotopes(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:isotopes) end
function getChannels(ctrl::Union{Nothing,control}) return isnothing(ctrl) ? nothing : getproperty(ctrl,:channels) end

# get control attributes from a run
function getMethod(pd::run) getMethod(getControl(pd)) end
function getA(pd::run) getA(getControl(pd)) end
function getB(pd::run) getB(getControl(pd)) end
function getIsotopes(pd::run) getIsotopes(getControl(pd)) end
function getChannels(pd::run) getChannels(getControl(pd)) end

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
function setBPar!(pd::run,bpar::Vector{Float64}) setproperty!(pd,:bpar,bpar) end
function setSPar!(pd::run,spar::Vector{Float64}) setproperty!(pd,:spar,spar) end
function setBCov!(pd::run,bcov::Matrix) setproperty!(pd,:bcov,bcov) end
function setSCov!(pd::run,scov::Matrix) setproperty!(pd,:scov,scov) end

# set key sample attributes in a run
function setBWin!(pd::run;i::Union{Integer,AbstractVector{<:Integer}},bwin::Vector{window}) accesSample!(pd,i,setBwin!,bwin) end
function setSWin!(pd::run;i::Union{Integer,AbstractVector{<:Integer}},swin::Vector{window}) accesSample!(pd,i,setSwin!,swin) end
function setStandard!(pd::run;i::Union{Int,AbstractVector{<:Integer}},standard::Integer) accesSample!(pd,i,setStandard!,standard) end

# set control attributes
function setInstrument!(ctrl::control,instrument::String) setproperty!(ctrl,:instrument,instrument) end
function setMethod!(ctrl::control,method::String) setproperty!(ctrl,:method,method) end
function setA!(ctrl::control,A::Vector{Float64}) setproperty!(ctrl,:A,A) end
function setB!(ctrl::control,B::Vector{Float64}) setproperty!(ctrl,:B,B) end
function setIsotopes!(ctrl::control,isotopes::Vector{String}) setproperty!(ctrl,:isotopes,isotopes) end
function setChannels!(ctrl::control,channels::Vector{String}) setproperty!(ctrl,:channels,channels) end

# set control attributes in a run
function setInstrument!(pd::run,instrument::String) accessControl!(pd,setInstrument!,instrument) end
function setMethod!(pd::run,method::String) accessControl!(pd,setMethod!,method) end
function setA!(pd::run,A::Vector{Float64}) accessControl!(pd,setA!,A) end
function setB!(pd::run,B::Vector{Float64}) accessControl!(pd,setB!,B) end
function setIsotopes!(pd::run,isotopes::Vector{String}) accessControl!(pd,setIsotopes!,isotopes) end
function setChannels!(pd::run,channels::Vector{String}) accessControl!(pd,setChannels!,channels) end

length(pd::run) = size(getSamples(pd),1)

function poolRunDat(pd::run,i=nothing)
    dats = getDat(pd,i=i)
    typeof(dats)
    reduce(vcat,dats)
end
