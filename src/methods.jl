function getRaw(pd::raw)::raw pd end
function getRaw(pd::processed)::raw pd.data end

function getDat(pd::plasmaData)::Matrix getproperty(getRaw(pd),:dat) end

function getCols(pd::plasmaData;labels::Vector{String})::Matrix
    i = findall(in(labels).(getLabels(pd)))
    getDat(pd)[:,i]
end

function getVal(pd::plasmaData;r=1,c=1) getDat(pd)[r,c] end

function getDatetime(pd::plasmaData) getproperty(getRaw(pd),:datetime) end

function nsweeps(pd::plasmaData) size(getDat(pd),1) end

function getName(pd::plasmaData) getproperty(getRaw(pd),:sname) end

function getLabels(pd::plasmaData) getproperty(getRaw(pd),:labels) end

function getIndex(pd::Union{RUN,run}) getproperty(getRaw(pd),:index) end

function getBlankWindows(pd::processed) getproperty(pd,:blank) end

function getSignalWindows(pd::processed) getproperty(pd,:signal) end

function getPar(pd::processed) getproperty(pd,:par) end

function getChannels(pd::processed) getproperty(pd,:channels) end

function setBlank!(pd::processed;
                   windows::Union{Nothing,Vector{window}}=nothing,
                   i::Union{Nothing,Integer}=nothing)
    setWindow!(pd,windows=windows,i=i,blank=true)
end

function setSignal!(pd::processed;
                    windows::Union{Nothing,Vector{window}}=nothing,
                    i::Union{Nothing,Integer}=nothing)
    setWindow!(pd,windows=windows,i=i,blank=false)
end

function setPar!(pd::processed,par::Vector) pd.par = par end

function setChannels!(pd::processed,channels::Vector) pd.channels = channels end

length(pd::Union{RUN,run}) = Base.length(getName(pd))
